import Foundation
import GRDB

class Balance: Record {
    let symbol: String
    var amount: Decimal

    init(symbol: String, amount: Decimal) {
        self.symbol = symbol
        self.amount = amount

        super.init()
    }

    override class var databaseTableName: String {
        return "balances"
    }

    enum Columns: String, ColumnExpression {
        case amount
        case symbol
    }

    required init(row: Row) {
        symbol = row[Columns.symbol]
        amount = row[Columns.amount]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.symbol] = symbol
        container[Columns.amount] = amount
    }

}

extension Balance: CustomStringConvertible {

    public var description: String {
        return "BALANCE: [symbol: \(symbol); amount: \(amount)]"
    }

}
