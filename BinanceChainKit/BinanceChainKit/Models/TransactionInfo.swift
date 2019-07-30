public class TransactionInfo {
    public let hash: String
    public let blockNumber: Int
    public let date: Date
    public let from: String
    public let to: String
    public let amount: Decimal
    public let symbol: String
    public let fee: Decimal
    public let memo: String?

    init(transaction: Transaction) {
        self.hash = transaction.hash
        self.blockNumber = transaction.blockNumber
        self.date = transaction.date
        self.from = transaction.from
        self.to = transaction.to
        self.amount = transaction.amount
        self.symbol = transaction.symbol
        self.fee = transaction.fee
        self.memo = transaction.memo
    }

}
