import Foundation
import Combine
import HsExtensions

public class Asset {
    public let symbol: String
    public let address: String

    @DistinctPublished public var balance: Decimal

    let transactionsSubject = PassthroughSubject<[TransactionInfo], Never>()

    init(symbol: String, balance: Decimal, address: String) {
        self.symbol = symbol
        self.balance = balance
        self.address = address
    }

    public func transactionsPublisher(filterType: TransactionFilterType? = nil) -> some Publisher<[TransactionInfo], Never> {
        transactionsSubject
                .map { [weak self] (transactions: [TransactionInfo]) -> [TransactionInfo] in
                    guard let address = self?.address else {
                        return []
                    }

                    return transactions.filter { transaction in
                        switch filterType {
                        case .incoming: return transaction.to == address
                        case .outgoing: return transaction.from == address
                        case nil: return true
                        }
                    }
                }
                .filter { !$0.isEmpty }
    }

}

extension Asset: Equatable {

    public static func ==(lhs: Asset, rhs: Asset) -> Bool {
        lhs.symbol == rhs.symbol
    }

}

extension Asset: CustomStringConvertible {

    public var description: String {
        "ASSET: [symbol: \(symbol); balance: \(balance)]"
    }

}
