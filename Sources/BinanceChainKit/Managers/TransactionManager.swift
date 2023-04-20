import Foundation
import HsToolKit

class TransactionManager {
    enum TransactionManagerError: Error {
        case transactionNotIncludedInBlock
    }

    weak var delegate: ITransactionManagerDelegate?

    private let storage: IStorage
    private let wallet: Wallet
    private let apiProvider: IApiProvider
    private let accountSyncer: AccountSyncer
    private let logger: Logger?

    private let windowTime: TimeInterval = 88 * 24 * 3600 // 3 months duration
    private let binanceLaunchTime: Date = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: 2019, month: 3, day: 7).date!

    init(storage: IStorage, wallet: Wallet, apiProvider: IApiProvider, accountSyncer: AccountSyncer, logger: Logger?) {
        self.storage = storage
        self.wallet = wallet
        self.apiProvider = apiProvider
        self.accountSyncer = accountSyncer
        self.logger = logger
    }

    func transactions(symbol: String, filterType: TransactionFilterType?, fromTransactionHash: String?, limit: Int?) -> [Transaction] {
        var fromAddress: String? = nil
        var toAddress: String? = nil

        switch filterType {
        case .incoming: toAddress = wallet.address
        case .outgoing: fromAddress = wallet.address
        case nil: ()
        }

        return storage.transactions(symbol: symbol, fromAddress: fromAddress, toAddress: toAddress, fromTransactionHash: fromTransactionHash, limit: limit)
    }

    func transaction(symbol: String, hash: String) -> Transaction? {
        storage.transaction(symbol: symbol, hash: hash)
    }

    func sync() async {
        let syncedUntilTime = storage.syncState?.transactionSyncedUntilTime ?? binanceLaunchTime
        logger?.debug("Syncing transactions starting from \(syncedUntilTime)")

        do {
            try await syncTransactionsPartially(startTime: syncedUntilTime.timeIntervalSince1970)
        } catch {
            logger?.error("TransactionManager sync failure: \(error)")
        }
    }

    private func syncTransactionsPartially(startTime: TimeInterval) async throws {
        let txs = try await apiProvider.transactions(account: wallet.address, limit: 1000, startTime: startTime)

        logger?.debug("\(txs.count) transactions received: [\(txs.map { $0.txHash }.joined(separator: ", "))]")

        let transactions = txs.compactMap { Transaction(tx: $0) }
        let currentTime = Date().timeIntervalSince1970 - 60

        let syncedUntil: TimeInterval
        if transactions.count >= 1000, let lastTransaction = transactions.last {
            syncedUntil = lastTransaction.date.timeIntervalSince1970
        } else {
            syncedUntil = min(startTime + windowTime, currentTime)
        }

        storage.save(syncState: SyncState(transactionSyncedUntilTime: syncedUntil))

        if transactions.count > 0 {
            storage.save(transactions: transactions)
            delegate?.didSync(transactions: transactions)
        }

        if (syncedUntil < currentTime) {
            try await syncTransactionsPartially(startTime: syncedUntil)
        }
    }

    func send(symbol: String, to: String, amount: Decimal, memo: String) async throws -> String {
        try await accountSyncer.sync(wallet: wallet)

        let amountDouble = Double(truncating: amount as NSNumber)
        return try await apiProvider.send(symbol: symbol, to: to, amount: amountDouble, memo: memo, wallet: wallet)
    }

    func moveToBsc(symbol: String, bscPublicKeyHash: Data, amount: Decimal) async throws -> String {
        try await accountSyncer.sync(wallet: wallet)

        let amountDouble = Double(truncating: amount as NSNumber)
        return try await apiProvider.transferOut(symbol: symbol, bscPublicKeyHash: bscPublicKeyHash, amount: amountDouble, expireTime: Int64(Date().timeIntervalSince1970 + 600), wallet: wallet)
    }

    func blockHeight(forTransaction hash: String, retriesCount: Int = 0) async throws -> Int {
        guard retriesCount < 5 else {
            throw TransactionManagerError.transactionNotIncludedInBlock
        }

        logger?.verbose("Checking blockHeight of transaction \(hash) for \(retriesCount) time")

        let blockHeight = try await apiProvider.blockHeight(forTransaction: hash)

        guard blockHeight > 0 else {
            logger?.verbose("Transaction not in block yet")
            try await Task.sleep(nanoseconds: 1_000_000_000)

            return try await self.blockHeight(forTransaction: hash, retriesCount: retriesCount + 1)
        }

        logger?.verbose("Transaction in blockHeight: \(blockHeight)")

        return blockHeight
    }

}
