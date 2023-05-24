import Foundation
import GRDB

class SyncState: Record {
    private let primaryKey = "sync_state"
    let transactionSyncedUntilTime: Date
    
    init(transactionSyncedUntilTime: TimeInterval) {
        self.transactionSyncedUntilTime = Date(timeIntervalSince1970: transactionSyncedUntilTime)
        
        super.init()
    }
    
    override class var databaseTableName: String {
        return "sync_states"
    }
    
    enum Columns: String, ColumnExpression {
        case primaryKey
        case transactionSyncedUntilTime
    }
    
    required init(row: Row) throws {
        transactionSyncedUntilTime = row[Columns.transactionSyncedUntilTime]
        
        try super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) throws {
        container[Columns.primaryKey] = primaryKey
        container[Columns.transactionSyncedUntilTime] = transactionSyncedUntilTime
    }
    
}
