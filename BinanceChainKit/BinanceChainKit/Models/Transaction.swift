import GRDB

public class Transaction: Record {
    public let hash: String
    public let blockNumber: Int
    public let date: Date
    public let from: String
    public let to: String
    public let amount: Decimal
    public let fee: Decimal
    public let symbol: String
    public let memo: String?


    init?(tx: Tx) {
        guard let txValue = Decimal(string: tx.value),
              let txFee = Decimal(string: tx.txFee) else {
            return nil
        }

        hash = tx.txHash
        blockNumber = Int(tx.blockHeight)
        date = tx.timestamp
        from = tx.fromAddr
        to = tx.toAddr
        amount = txValue
        symbol = tx.txAsset
        fee = txFee
        memo = tx.memo
        
        super.init()
    }

    override public class var databaseTableName: String {
        return "transactions"
    }

    enum Columns: String, ColumnExpression {
        case hash
        case blockNumber
        case date
        case from
        case to
        case amount
        case symbol
        case fee
        case memo
    }

    required init(row: Row) {
        hash = row[Columns.hash]
        blockNumber = row[Columns.blockNumber]
        date = row[Columns.date]
        from = row[Columns.from]
        to = row[Columns.to]
        amount = row[Columns.amount]
        symbol = row[Columns.symbol]
        fee = row[Columns.fee]
        memo = row[Columns.memo]

        super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.hash] = hash
        container[Columns.blockNumber] = blockNumber
        container[Columns.date] = date
        container[Columns.from] = from
        container[Columns.to] = to
        container[Columns.amount] = amount
        container[Columns.symbol] = symbol
        container[Columns.fee] = fee
        container[Columns.memo] = memo
    }

}
