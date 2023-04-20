import HsToolKit

class AccountSyncer {
    private let apiProvider: IApiProvider
    private let logger: Logger?

    init(apiProvider: IApiProvider, logger: Logger?) {
        self.apiProvider = apiProvider
        self.logger = logger
    }

    func sync(wallet: Wallet) async throws {
        let (nodeInfo, account) = try await sync(account: wallet.address)

        wallet.accountNumber = account.accountNumber
        wallet.sequence = account.sequence
        wallet.chainId = nodeInfo.network
    }

    func sync(account: String) async throws -> (NodeInfo, Account) {
        async let nodeInfo = try apiProvider.nodeInfo()
        async let account = try apiProvider.account(for: account)

        return try await (nodeInfo, account)
    }

}
