import BinanceChainKit
import RxSwift

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

}

extension BinanceChainAdapter {

    var name: String {
        return asset.symbol
    }

    var coin: String {
        return asset.symbol
    }

    var latestBlockHeight: Int? {
        return binanceChainKit.latestBlockHeight
    }

    var syncState: BinanceChainKit.SyncState {
        return binanceChainKit.syncState
    }

    var balance: Decimal {
        return asset.balance
    }

    var lastBlockHeightObservable: Observable<Void> {
        return binanceChainKit.lastBlockHeightObservable.map { _ in () }
    }

    var syncStateObservable: Observable<Void> {
        return binanceChainKit.syncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        return asset.balanceObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        return asset.transactionsObservable.map { _ in () }
    }

    func validate(address: String) throws {

    }

    func sendSingle(to: String, amount: Decimal, memo: String) -> Single<String> {
        return binanceChainKit.sendSingle(symbol: asset.symbol, to: to, amount: amount, memo: memo)
    }

    func transactionsSingle(fromTransactionHash: String?, limit: Int?) -> Single<[TransactionRecord]> {
        return binanceChainKit.transactionsSingle(symbol: asset.symbol, fromTransactionHash: fromTransactionHash, limit: limit).map {
            $0.map { transaction in self.transactionRecord(fromTransaction: transaction) }
        }
    }

}
