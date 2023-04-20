import Foundation
import HsToolKit

class BalanceManager {
    weak var delegate: IBalanceManagerDelegate?

    private let storage: IStorage
    private let accountSyncer: AccountSyncer
    private let logger: Logger?

    init(storage: IStorage, accountSyncer: AccountSyncer, logger: Logger? = nil) {
        self.storage = storage
        self.accountSyncer = accountSyncer
        self.logger = logger
    }

    var latestBlock: LatestBlock? {
        storage.latestBlock
    }

    func balance(symbol: String) -> Balance? {
        storage.balance(symbol: symbol)
    }

    func sync(account: String) async {
        do {
            let (nodeInfo, account) = try await accountSyncer.sync(account: account)
            handle(nodeInfo: nodeInfo, account: account)
        } catch {
            logger?.error("Failed to sync nodeInfo and account: \(error)")
            delegate?.didFailToSync(error: error)
        }
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
