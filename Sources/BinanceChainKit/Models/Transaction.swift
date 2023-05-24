import Foundation
import GRDB

class Transaction: Record {
    static let decimal = 8 // 8-digit decimals

    let hash: String
    let blockHeight: Int
    let date: Date
    let from: String
    let to: String
    let amount: Decimal
    let fee: Decimal
    let symbol: String
    let memo: String?


    init?(tx: Tx) {
        guard let txValue = Decimal(string: tx.value),
              let txFee = Decimal(string: tx.txFee) else {
            return nil
        }

        hash = tx.txHash
        blockHeight = Int(tx.blockHeight)
        date = tx.timestamp
        from = tx.fromAddr
        to = tx.toAddr
        amount = txValue
        fee = txFee
        symbol = tx.txAsset
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

    required init(row: Row) throws {
        hash = row[Columns.hash]
        blockHeight = row[Columns.blockNumber]
        date = row[Columns.date]
        from = row[Columns.from]
        to = row[Columns.to]
        amount = Transaction.decimalValue(of: row[Columns.amount])
        fee = Transaction.decimalValue(of: row[Columns.fee])
        symbol = row[Columns.symbol]
        memo = row[Columns.memo]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.hash] = hash
        container[Columns.blockNumber] = blockHeight
        container[Columns.date] = date
        container[Columns.from] = from
        container[Columns.to] = to
        container[Columns.amount] = Transaction.int64Value(of: amount)
        container[Columns.fee] = Transaction.int64Value(of: fee)
        container[Columns.symbol] = symbol
        container[Columns.memo] = memo
    }

    private static func decimalValue(of int64: Int64) -> Decimal {
        return Decimal(sign: .plus, exponent: -decimal, significand: Decimal(int64))
    }

    private static func int64Value(of decimalValue: Decimal) -> Int64 {
        return Int64(truncating: Decimal(sign: .plus, exponent: decimal, significand: decimalValue) as NSNumber)
    }

}
