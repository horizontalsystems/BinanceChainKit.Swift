import Foundation

public class TransactionInfo {
    public let hash: String
    public let blockHeight: Int
    public let date: Date
    public let from: String
    public let to: String
    public let amount: Decimal
    public let fee: Decimal
    public let symbol: String
    public let memo: String?

    init(transaction: Transaction) {
        self.hash = transaction.hash
        self.blockHeight = transaction.blockHeight
        self.date = transaction.date
        self.from = transaction.from
        self.to = transaction.to
        self.amount = transaction.amount
        self.fee = transaction.fee
        self.symbol = transaction.symbol
        self.memo = transaction.memo
    }

}
