import RxSwift
import HsToolKit

class AccountSyncer {
    private let apiProvider: IApiProvider
    private let logger: Logger?

    private let disposeBag = DisposeBag()

    init(apiProvider: IApiProvider, logger: Logger?) {
        self.apiProvider = apiProvider
        self.logger = logger
    }

    func sync(wallet: Wallet) -> Single<Void> {
        sync(account: wallet.address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .map({ nodeInfo, account in
                    wallet.accountNumber = account.accountNumber
                    wallet.sequence = account.sequence
                    wallet.chainId = nodeInfo.network
                })
    }

    func sync(account: String) -> Single<(NodeInfo, Account)> {
        Single.zip(
                apiProvider.nodeInfoSingle(),
                apiProvider.accountSingle(for: account).catchError { error in
                    guard let binanceError = error as? BinanceError else {
                        return Single.error(error)
                    }

                    if binanceError.code == 404 {
                        // New account
                        return Single.just(Account())
                    }

                    return Single.error(error)
                }
        )
    }

}
