import Foundation
import GRDB

class Storage {
    private let dbPool: DatabasePool

    init(databaseDirectoryUrl: URL, databaseFileName: String) {
        let databaseURL = databaseDirectoryUrl.appendingPathComponent("\(databaseFileName).sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try? migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createBalance") { db in
            try db.create(table: Balance.databaseTableName) { t in
                t.column(Balance.Columns.symbol.name, .text).notNull()
                t.column(Balance.Columns.amount.name, .text).notNull()

                t.primaryKey([Balance.Columns.symbol.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createTransaction") { db in
            try db.create(table: Transaction.databaseTableName) { t in
                t.column(Transaction.Columns.hash.name, .text).notNull()
                t.column(Transaction.Columns.blockNumber.name, .integer).notNull()
                t.column(Transaction.Columns.date.name, .date).notNull()
                t.column(Transaction.Columns.from.name, .text).notNull()
                t.column(Transaction.Columns.to.name, .text).notNull()
                t.column(Transaction.Columns.amount.name, .integer).notNull()
                t.column(Transaction.Columns.fee.name, .integer).notNull()
                t.column(Transaction.Columns.symbol.name, .text).notNull()
                t.column(Transaction.Columns.memo.name, .text)

                t.primaryKey([Transaction.Columns.hash.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createLatestBlock") { db in
            try db.create(table: LatestBlock.databaseTableName) { t in
                t.column(LatestBlock.Columns.primaryKey.name, .text).notNull()
                t.column(LatestBlock.Columns.height.name, .integer).notNull()
                t.column(LatestBlock.Columns.hash.name, .text).notNull()
                t.column(LatestBlock.Columns.time.name, .date).notNull()

                t.primaryKey([LatestBlock.Columns.primaryKey.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createSyncStates") { db in
            try db.create(table: SyncState.databaseTableName) { t in
                t.column(SyncState.Columns.primaryKey.name, .text).notNull()
                t.column(SyncState.Columns.transactionSyncedUntilTime.name, .date).notNull()

                t.primaryKey([SyncState.Columns.primaryKey.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension Storage: IStorage {

    var latestBlock: LatestBlock? {
        try? dbPool.read { db in
            try LatestBlock.fetchOne(db)
        }
    }

    func save(latestBlock: LatestBlock) {
        _ = try? dbPool.write { db in
            try latestBlock.insert(db)
        }
    }

    var syncState: SyncState? {
        try? dbPool.read { db in
            try SyncState.fetchOne(db)
        }
    }

    func save(syncState: SyncState) {
        _ = try? dbPool.write { db in
            try syncState.insert(db)
        }
    }

    func balance(symbol: String) -> Balance? {
        try? dbPool.read { db in
            try Balance.filter(Balance.Columns.symbol == symbol).fetchOne(db)
        }
    }

    func allBalances() -> [Balance] {
        try! dbPool.read { db in
            try Balance.fetchAll(db)
        }
    }

    func remove(balances: [Balance]) {
        _ = try? dbPool.write { db in
            for balance in balances {
                try balance.delete(db)
            }
        }
    }

    func save(balances: [Balance]) {
        _ = try? dbPool.write { db in
            for balance in  balances {
                try balance.insert(db)
            }
        }
    }

    func save(transactions: [Transaction]) {
        _ = try? dbPool.write { db in
            for transaction in transactions {
                try transaction.insert(db)
            }
        }
    }

    func transactions(symbol: String, fromAddress: String?, toAddress: String?, fromTransactionHash: String?, limit: Int?) -> [Transaction] {
        try! dbPool.read { db in
            var request = Transaction.filter(Transaction.Columns.symbol == symbol)

            if let fromAddress = fromAddress {
                request = request.filter(Transaction.Columns.from == fromAddress)
            }

            if let toAddress = toAddress {
                request = request.filter(Transaction.Columns.to == toAddress)
            }

            if let transactionHash = fromTransactionHash,
               let transaction = try Transaction.filter(Transaction.Columns.hash == transactionHash).fetchOne(db) {
                request = request.filter(Transaction.Columns.date < transaction.date)
            }

            if let limit = limit {
                request = request.limit(limit)
            }

            return try request.order(Transaction.Columns.date.desc).fetchAll(db)
        }
    }

    func transaction(symbol: String, hash: String) -> Transaction? {
        try? dbPool.read { db in
            try Transaction.filter(Transaction.Columns.symbol == symbol && Transaction.Columns.hash == hash).fetchOne(db)
        }
    }

}
