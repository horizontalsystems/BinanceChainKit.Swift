import RxSwift

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let storage: IStorage
    private let accountSyncer: AccountSyncer
    private let logger: Logger?

    private let disposeBag = DisposeBag()


    init(storage: IStorage, accountSyncer: AccountSyncer, logger: Logger? = nil) {
        self.storage = storage
        self.accountSyncer = accountSyncer
        self.logger = logger
    }

    var latestBlock: LatestBlock? {
        return storage.latestBlock
    }

    func balance(symbol: String) -> Balance? {
        return storage.balance(symbol: symbol)
    }

    func sync(account: String) {
        accountSyncer.sync(account: account)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] nodeInfo, account in
                    self?.handle(nodeInfo: nodeInfo, account: account)
                }, onError: { [weak self] error in
                    self?.logger?.error("Sync Failed: lastBlockHeight and balance: \(error)")
                    self?.delegate?.didFailToSync()
                })
                .disposed(by: disposeBag)
    }

    private func handle(nodeInfo: NodeInfo, account: Account) {
        logger?.debug("Balances received")

        let balances = account.balances.map { Balance(symbol: $0.symbol, amount: Decimal($0.free)) }
        storage.save(balances: balances)

        guard let latestBlock = LatestBlock(syncInfo: nodeInfo.syncInfo) else {
            return
        }
        storage.save(latestBlock: latestBlock)

        delegate?.didSync(balances: balances, latestBlockHeight: latestBlock.height)
    }

}
