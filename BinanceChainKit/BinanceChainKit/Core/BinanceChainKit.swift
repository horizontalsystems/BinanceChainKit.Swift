import RxSwift
import HSHDWalletKit

public class BinanceChainKit {
    private let disposeBag = DisposeBag()

    private let balanceManager: BalanceManager
    private let transactionManager: TransactionManager
    private let reachabilityManager: ReachabilityManager
    private let segWitHelper: SegWitBech32
    private let logger: Logger?

    public let account: String
    public var latestBlockHeight: Int?
    private let lastBlockHeightSubject = PublishSubject<Int>()
    private let syncStateSubject = PublishSubject<BinanceChainKit.SyncState>()

    private var assets = [Asset]()

    public var syncState: BinanceChainKit.SyncState = .notSynced {
        didSet {
            syncStateSubject.onNext(syncState)
        }
    }

    init(account: String, balanceManager: BalanceManager, transactionManager: TransactionManager, reachabilityManager: ReachabilityManager, segWitHelper: SegWitBech32, logger: Logger? = nil) {
        self.account = account
        self.balanceManager = balanceManager
        self.transactionManager = transactionManager
        self.reachabilityManager = reachabilityManager
        self.segWitHelper = segWitHelper
        self.logger = logger

        latestBlockHeight = balanceManager.latestBlock?.height

        reachabilityManager.reachabilitySignal
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.refresh()
                })
                .disposed(by: disposeBag)
    }

    private func asset(symbol: String) -> Asset? {
        return assets.first { $0.symbol == symbol }
    }

}

// Public API Extension

extension BinanceChainKit {

    public func register(symbol: String) -> Asset {
        let balance = balanceManager.balance(symbol: symbol)?.amount ?? 0
        let asset = Asset(symbol: symbol, balance: balance)

        assets.append(asset)

        return asset
    }

    public func unregister(asset: Asset) {
        assets.removeAll { $0 == asset }
    }

    public func refresh() {
        guard reachabilityManager.isReachable else {
            syncState = .notSynced
            return
        }

        guard syncState != .syncing else {
            logger?.debug("Already syncing balances")
            return
        }

        logger?.debug("Syncing")
        syncState = .syncing

        balanceManager.sync(account: account)
        transactionManager.sync(account: account)
    }

    public var lastBlockHeightObservable: Observable<Int> {
        return lastBlockHeightSubject.asObservable()
    }

    public var syncStateObservable: Observable<BinanceChainKit.SyncState> {
        return syncStateSubject.asObservable()
    }

    public func validate(address: String) throws {
        try _ = segWitHelper.decode(addr: address)
    }

    public func transactionsSingle(symbol: String, fromTransactionHash: String? = nil, limit: Int? = nil) -> Single<[TransactionInfo]> {
        return transactionManager.transactionsSingle(symbol: symbol, fromTransactionHash: fromTransactionHash, limit: limit).map {
            $0.map { transaction in TransactionInfo(transaction: transaction) }
        }
    }

    public func sendSingle(symbol: String, to: String, amount: Decimal, memo: String) -> Single<String> {
        logger?.debug("Sending \(amount) \(symbol) to \(to)")

        return transactionManager.sendSingle(account: account, symbol: symbol, to: to, amount: amount, memo: memo)
                .do(onSuccess: { [weak self] hash in
                    guard let kit = self else {
                        return
                    }

                    kit.transactionManager.blockHeightSingle(forTransaction: hash).subscribe(
                            onSuccess: { blockHeight in
                                kit.refresh()
                            }, onError: { error in
                                kit.logger?.error("Transaction send error: \(error)")
                            })
                            .disposed(by: kit.disposeBag)
                })
    }

}


extension BinanceChainKit: IBalanceManagerDelegate {

    func didSync(balances: [Balance], latestBlockHeight: Int) {
        for balance in balances {
            asset(symbol: balance.symbol)?.balance = balance.amount
        }
        self.latestBlockHeight = latestBlockHeight

        syncState = .synced
    }

    func didFailToSync() {
        syncState = .notSynced
    }

}

extension BinanceChainKit: ITransactionManagerDelegate {

    func didSync(transactions: [Transaction]) {
        let transactionsMap = Dictionary(grouping: transactions, by: { $0.symbol })

        for (symbol, transactions) in transactionsMap {
            asset(symbol: symbol)?.transactionsSubject.onNext(transactions.map { TransactionInfo(transaction: $0) })
        }
    }

}

extension BinanceChainKit {

    public static func instance(words: [String], networkType: NetworkType = .mainNet, walletId: String = "default", minLogLevel: Logger.Level = .error) throws -> BinanceChainKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let uniqueId = "\(walletId)-\(networkType)"
        let storage: IStorage = try Storage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "binance-chain-\(uniqueId)")

        let hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), coinType: 714, xPrivKey: 0, xPubKey: 0)
        let segWitHelper = SegWitBech32(hrp: networkType.addressPrefix)
        let wallet = try Wallet(hdWallet: hdWallet, segWitHelper: segWitHelper)

        let apiProvider = BinanceChainApiProvider(endpoint: networkType.endpoint, logger: logger)

        let accountSyncer = AccountSyncer(apiProvider: apiProvider, logger: logger)
        let balanceManager = BalanceManager(storage: storage, accountSyncer: accountSyncer, logger: logger)
        let transactionManager = TransactionManager(storage: storage, wallet: wallet, apiProvider: apiProvider, accountSyncer: accountSyncer, logger: logger)
        let reachabilityManager = ReachabilityManager()

        let binanceChainKit = BinanceChainKit(account: wallet.address, balanceManager: balanceManager, transactionManager: transactionManager, reachabilityManager: reachabilityManager, segWitHelper: segWitHelper, logger: logger)
        balanceManager.delegate = binanceChainKit
        transactionManager.delegate = binanceChainKit

        return binanceChainKit
    }

    public static func clear() throws {
        let fileManager = FileManager.default

        let urls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for url in urls {
            try fileManager.removeItem(at: url)
        }
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("binance-chain-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }

}


extension BinanceChainKit {

    public enum SyncState {
        case synced
        case syncing
        case notSynced
    }

    public enum NetworkType {
        case mainNet
        case testNet

        var addressPrefix: String {
            switch self {
            case .mainNet: return "bnb"
            case .testNet: return "tbnb"
            }
        }

        var endpoint: String {
            switch self {
            case .mainNet: return "https://dex.binance.org"
            case .testNet: return "https://testnet-dex.binance.org"
            }
        }
    }

}
