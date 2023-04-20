import Foundation

protocol IApiProvider {
    func nodeInfo() async throws -> NodeInfo
    func transactions(account: String, limit: Int, startTime: TimeInterval) async throws -> [Tx]
    func account(for: String) async throws -> Account
    func send(symbol: String, to: String, amount: Double, memo: String, wallet: Wallet) async throws -> String
    func transferOut(symbol: String, bscPublicKeyHash: Data, amount: Double, expireTime: Int64, wallet: Wallet) async throws -> String
    func blockHeight(forTransaction: String) async throws -> Int
}

protocol IStorage {
    var latestBlock: LatestBlock? { get }
    func save(latestBlock: LatestBlock)

    var syncState: SyncState? { get }
    func save(syncState: SyncState)

    func balance(symbol: String) -> Balance?
    func allBalances() -> [Balance]
    func remove(balances: [Balance])
    func save(balances: [Balance])
    func save(transactions: [Transaction])

    func transactions(symbol: String, fromAddress: String?, toAddress: String?, fromTransactionHash: String?, limit: Int?) -> [Transaction]
    func transaction(symbol: String, hash: String) -> Transaction?
}

protocol IBalanceManagerDelegate: AnyObject {
    func didSync(balances: [Balance], latestBlockHeight: Int)
    func didFailToSync(error: Error)
}

protocol ITransactionManagerDelegate: AnyObject {
    func didSync(transactions: [Transaction])
}
