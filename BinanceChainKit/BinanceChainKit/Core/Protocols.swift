import RxSwift

protocol IApiProvider {
    func nodeInfoSingle() -> Single<NodeInfo>
    func transactionsSingle(symbol: String) -> Single<[Tx]>
    func accountSingle() -> Single<Account>
    func sendSingle(symbol: String, to: String, amount: Double, wallet: Wallet) -> Single<Tx>
}
