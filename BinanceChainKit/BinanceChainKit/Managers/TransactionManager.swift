import RxSwift

class TransactionManager {
    weak var delegate: ITransactionManagerDelegate?

    private let storage: IStorage
    private let wallet: Wallet
    private let apiProvider: IApiProvider
    private let logger: Logger

    private let disposeBag = DisposeBag()

    init(storage: IStorage, wallet: Wallet, apiProvider: IApiProvider, logger: Logger) {
        self.storage = storage
        self.wallet = wallet
        self.apiProvider = apiProvider
        self.logger = logger
    }

    func transactionsSingle(symbol: String, fromTransactionHash: String?, limit: Int?) -> Single<[Transaction]> {
        return storage.transactionsSingle(symbol: symbol, fromTransactionHash: fromTransactionHash, limit: limit)
    }

    func sync(account: String) {
        logger.verbose("Syncing transactions starting from \(0)")

        let startTime = Date().addingTimeInterval(-3*30*24*60*60).timeIntervalSince1970
        apiProvider.transactionsSingle(account: account, offset: 0, startTime: startTime)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] transactions in
                    self?.handle(transactions: transactions)
                }, onError: { [weak self] error in
                    self?.logger.error("TransactionManager sync failure: \(error.localizedDescription)")
                }
        ).disposed(by: disposeBag)
    }

    private func handle(transactions: [Tx]) {
        logger.debug("Transactions received: \(transactions.count)")

        let transactions = transactions.compactMap { Transaction(tx: $0) }

        guard !transactions.isEmpty else {
            return
        }

        storage.save(transactions: transactions)
        delegate?.didSync(transactions: transactions)

//        sync(account: account)
    }

    func sendSingle(account: String, symbol: String, to: String, amount: Decimal, memo: String) -> Single<String?> {
        return Single.just(nil)
    }
}
