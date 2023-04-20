import Foundation
import Combine
import BinanceChainKit

class BinanceChainAdapter {
    private let binanceChainKit: BinanceChainKit
    private let asset: Asset

    init(binanceChainKit: BinanceChainKit, symbol: String) {
        self.binanceChainKit = binanceChainKit

        asset = binanceChainKit.register(symbol: symbol)
    }

    private func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from == binanceChainKit.account
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to == binanceChainKit.account
        )

        let sign: FloatingPointSign = from.mine ? .minus : .plus
        let amount = Decimal(sign: sign, exponent: 0, significand: transaction.amount)

        return TransactionRecord(
                hash: transaction.hash,
                blockNumber: transaction.blockHeight,
                date: transaction.date,
                from: from,
                to: to,
                amount: amount,
                symbol: transaction.symbol,
                fee: transaction.fee,
                memo: transaction.memo
        )
    }

    func moveToBSC(symbol: String, amount: Decimal) async throws -> String {
        try await binanceChainKit.moveToBSC(symbol: symbol, amount: amount)
    }

}

extension BinanceChainAdapter {

    var name: String {
        asset.symbol
    }

    var coin: String {
        asset.symbol
    }

    var latestBlockHeight: Int? {
        binanceChainKit.lastBlockHeight
    }

    var syncState: BinanceChainKit.SyncState {
        binanceChainKit.syncState
    }

    var balance: Decimal {
        asset.balance
    }

    var lastBlockHeightPublisher: some Publisher<Void, Never> {
        binanceChainKit.$lastBlockHeight.map { _ in () }
    }

    var syncStatePublisher: some Publisher<Void, Never> {
        binanceChainKit.$syncState.map { _ in () }
    }

    var balancePublisher: some Publisher<Void, Never> {
        asset.$balance.map { _ in () }
    }

    var transactionsPublisher: some Publisher<Void, Never> {
        asset.transactionsPublisher().map { _ in  () }
    }

    func validate(address: String) throws {

    }

    func send(to: String, amount: Decimal, memo: String) async throws -> String {
        try await binanceChainKit.send(symbol: asset.symbol, to: to, amount: amount, memo: memo)
    }

    func transactions(fromTransactionHash: String?, limit: Int?) -> [TransactionRecord] {
        binanceChainKit.transactions(symbol: asset.symbol, fromTransactionHash: fromTransactionHash, limit: limit)
                .map { transaction in
                    transactionRecord(fromTransaction: transaction)
                }
    }

    func transaction(hash: String) -> TransactionRecord? {
        binanceChainKit.transaction(symbol: asset.symbol, hash: hash).map { transactionRecord(fromTransaction: $0) }
    }

}
