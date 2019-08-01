import RxSwift

protocol IApiProvider {
    func nodeInfoSingle() -> Single<NodeInfo>
    func transactionsSingle(account: String, limit: Int, startTime: TimeInterval) -> Single<[Tx]>
    func accountSingle(for: String) -> Single<Account>
    func sendSingle(symbol: String, to: String, amount: Double, memo: String, wallet: Wallet) -> Single<String>
    func blockHeightSingle(forTransaction: String) -> Single<Int>
}

protocol IStorage {
    var latestBlock: LatestBlock? { get }
    func save(latestBlock: LatestBlock)

    var syncState: SyncState? { get }
    func save(syncState: SyncState)

    func balance(symbol: String) -> Balance?
    func save(balances: [Balance])
    func save(transactions: [Transaction])

    func transactionsSingle(symbol: String, fromTransactionHash: String?, limit: Int?) -> Single<[Transaction]>
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
}

protocol IBalanceManagerDelegate: AnyObject {
    func didSync(balances: [Balance], latestBlockHeight: Int)
    func didFailToSync()
}

protocol ITransactionManagerDelegate: AnyObject {
    func didSync(transactions: [Transaction])
}
