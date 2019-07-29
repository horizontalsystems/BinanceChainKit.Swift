public class TransactionInfo {
    public let hash: String
    public let from: String
    public let to: String
    public let value: String
    public let timestamp: TimeInterval

    public let blockHash: String?
    public let blockNumber: Int?
    public let transactionIndex: Int?

    init(hash: String, from: String, to: String, value: String, timestamp: Double) {
        self.hash = hash
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp
        self.blockHash = nil
        self.blockNumber = nil
        self.transactionIndex = nil
    }

    init(tx: Tx) {
        hash = tx.txHash
        from = tx.fromAddr
        to = tx.toAddr
        value = tx.value
        timestamp = tx.timestamp.timeIntervalSince1970
        blockNumber = Int(tx.blockHeight)
        blockHash = nil
        transactionIndex = nil
    }

}
