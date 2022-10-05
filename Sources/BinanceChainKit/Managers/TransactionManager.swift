import Foundation
import RxSwift
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

    private let disposeBag = DisposeBag()
    private let windowTime: TimeInterval = 88 * 24 * 3600 // 3 months duration
    private let binanceLaunchTime: Date = DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, year: 2019, month: 3, day: 7).date!

    init(storage: IStorage, wallet: Wallet, apiProvider: IApiProvider, accountSyncer: AccountSyncer, logger: Logger?) {
        self.storage = storage
        self.wallet = wallet
        self.apiProvider = apiProvider
        self.accountSyncer = accountSyncer
        self.logger = logger
    }

    func transactionsSingle(symbol: String, filterType: TransactionFilterType?, fromTransactionHash: String?, limit: Int?) -> Single<[Transaction]> {
        var fromAddress: String? = nil
        var toAddress: String? = nil

        switch filterType {
        case .incoming: toAddress = wallet.address
        case .outgoing: fromAddress = wallet.address
        case nil: ()
        }
        
        return storage.transactionsSingle(symbol: symbol, fromAddress: fromAddress, toAddress: toAddress, fromTransactionHash: fromTransactionHash, limit: limit)
    }

    func transaction(symbol: String, hash: String) -> Transaction? {
        storage.transaction(symbol: symbol, hash: hash)
    }

    func sync() {
        let syncedUntilTime = storage.syncState?.transactionSyncedUntilTime ?? binanceLaunchTime
        logger?.debug("Syncing transactions starting from \(syncedUntilTime)")

        syncTransactionsPartially(startTime: syncedUntilTime.timeIntervalSince1970)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: {}, onError: { [weak self] error in
                    self?.logger?.error("TransactionManager sync failure: \(error.localizedDescription)")
                })
                .disposed(by: disposeBag)
    }

    private func syncTransactionsPartially(startTime: TimeInterval) -> Single<Void> {
        apiProvider.transactionsSingle(account: wallet.address, limit: 1000, startTime: startTime)
                .flatMap { txs in
                    self.logger?.debug("\(txs.count) transactions received: [\(txs.map { $0.txHash }.joined(separator: ", "))]")

                    let transactions = txs.compactMap { Transaction(tx: $0) }
                    let currentTime = Date().timeIntervalSince1970 - 60

                    let syncedUntil: TimeInterval
                    if transactions.count >= 1000, let lastTransaction = transactions.last {
                        syncedUntil = lastTransaction.date.timeIntervalSince1970
                    } else {
                        syncedUntil = min(startTime + self.windowTime, currentTime)
                    }

                    self.storage.save(syncState: SyncState(transactionSyncedUntilTime: syncedUntil))

                    if transactions.count > 0 {
                        self.storage.save(transactions: transactions)
                        self.delegate?.didSync(transactions: transactions)
                    }

                    if (syncedUntil < currentTime) {
                        return self.syncTransactionsPartially(startTime: syncedUntil)
                    } else {
                        return Single.just(())
                    }
                }
    }

    func sendSingle(symbol: String, to: String, amount: Decimal, memo: String) -> Single<String> {
        accountSyncer.sync(wallet: wallet)
                .flatMap {
                    let amountDouble = Double(truncating: amount as NSNumber)
                    return self.apiProvider.sendSingle(symbol: symbol, to: to, amount: amountDouble, memo: memo, wallet: self.wallet)
                }
    }

    func moveToBscSingle(symbol: String, bscPublicKeyHash: Data, amount: Decimal) -> Single<String> {
        accountSyncer.sync(wallet: wallet)
                .flatMap {
                    let amountDouble = Double(truncating: amount as NSNumber)
                    return self.apiProvider.transferOutSingle(symbol: symbol, bscPublicKeyHash: bscPublicKeyHash, amount: amountDouble, expireTime: Int64(Date().timeIntervalSince1970 + 600), wallet: self.wallet)
                }
    }

    func blockHeightSingle(forTransaction hash: String, retriesCount: Int = 0) -> Single<Int> {
        guard retriesCount < 5 else {
            return Single.error(TransactionManagerError.transactionNotIncludedInBlock)
        }

        logger?.verbose("Checking blockHeight of transaction \(hash) for \(retriesCount) time")
        return apiProvider.blockHeightSingle(forTransaction: hash)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .flatMap { blockHeight in
                    guard blockHeight > 0 else {
                        self.logger?.verbose("Transaction not in block yet")
                        sleep(1)
                        return self.blockHeightSingle(forTransaction: hash, retriesCount: retriesCount + 1)
                    }

                    self.logger?.verbose("Transaction in blockHeight: \(blockHeight)")
                    return Single.just(blockHeight)
                }
    }

}
