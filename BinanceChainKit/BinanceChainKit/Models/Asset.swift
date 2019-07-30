import RxSwift

public class Asset {
    public let symbol: String

    public var balance: Decimal {
        didSet {
            balanceSubject.onNext(balance)
        }
    }

    private let balanceSubject = PublishSubject<Decimal>()
    let transactionsSubject = PublishSubject<[TransactionInfo]>()

    init(symbol: String, balance: Decimal) {
        self.symbol = symbol
        self.balance = balance
    }

    public var balanceObservable: Observable<Decimal> {
        return balanceSubject.asObservable()
    }

    public var transactionsObservable: Observable<[TransactionInfo]> {
        return transactionsSubject.asObservable()
    }

}

extension Asset: Equatable {

    public static func ==(lhs: Asset, rhs: Asset) -> Bool {
        return lhs.symbol == rhs.symbol
    }

}

extension Asset: CustomStringConvertible {

    public var description: String {
        return "ASSET: [symbol: \(symbol); balance: \(balance)]"
    }

}
