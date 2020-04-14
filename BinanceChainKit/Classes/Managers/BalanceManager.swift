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
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] nodeInfo, account in
                    self?.handle(nodeInfo: nodeInfo, account: account)
                }, onError: { [weak self] error in
                    self?.logger?.error("Failed to sync nodeInfo and account: \(error)")
                    self?.delegate?.didFailToSync()
                })
                .disposed(by: disposeBag)
    }

    private func handle(nodeInfo: NodeInfo, account: Account) {
        logger?.debug("NodeInfo received with network: \(nodeInfo.network); latestBlockHeight: \(String(describing: nodeInfo.syncInfo["latest_block_height"]))")
        logger?.debug("Balances received for \(account.balances.map { "\($0.symbol): \($0.free)" }.joined(separator: ", "))")

        let oldBalances = storage.allBalances()
        let balances = account.balances.map { Balance(symbol: $0.symbol, amount: Decimal($0.free)) }
        var toRemove = [Balance]()

        for oldBalance in oldBalances {
            if !balances.contains(where: { $0.symbol == oldBalance.symbol }) {
                oldBalance.amount = 0
                toRemove.append(oldBalance)
            }
        }

        storage.save(balances: balances)
        storage.remove(balances: toRemove)

        guard let latestBlock = LatestBlock(syncInfo: nodeInfo.syncInfo) else {
            return
        }

        storage.save(latestBlock: latestBlock)
        delegate?.didSync(balances: balances + toRemove, latestBlockHeight: latestBlock.height)
    }

}
