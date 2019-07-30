import RxSwift

class AccountSyncer {
    private let apiProvider: IApiProvider
    private let logger: Logger?

    private let disposeBag = DisposeBag()

    init(apiProvider: IApiProvider, logger: Logger?) {
        self.apiProvider = apiProvider
        self.logger = logger
    }

    func sync(wallet: Wallet) -> Single<Void> {
        return sync(account: wallet.address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .map({ nodeInfo, account in
                    wallet.accountNumber = account.accountNumber
                    wallet.sequence = account.sequence
                    wallet.chainId = nodeInfo.network
                })
    }

    func sync(account: String) -> Single<(NodeInfo, Account)> {
        return Single.zip(
                        apiProvider.nodeInfoSingle(),
                        apiProvider.accountSingle(for: account)
                )
    }

}
