import RxSwift
import HdWalletKit
import HsToolKit

public class BinanceChainKit {
    private let disposeBag = DisposeBag()

    private let balanceManager: BalanceManager
    private let transactionManager: TransactionManager
    private let reachabilityManager: ReachabilityManager
    private let segWitHelper: SegWitBech32
    private let networkType: NetworkType
    private let logger: Logger?

    private let wallet: Wallet
    private let lastBlockHeightSubject = PublishSubject<Int>()
    private let syncStateSubject = PublishSubject<SyncState>()

    private var assets = [Asset]()

    public var syncState: SyncState = .notSynced(error: BinanceChainKit.SyncError.notStarted) {
        didSet {
            syncStateSubject.onNext(syncState)
        }
    }

    public var lastBlockHeight: Int? {
        didSet {
            if let lastBlockHeight = lastBlockHeight {
                lastBlockHeightSubject.onNext(lastBlockHeight)
            }
        }
    }

    public var binanceBalance: Decimal {
        balanceManager.balance(symbol: "BNB")?.amount ?? 0
    }

    public var account: String {
        wallet.address
    }

    init(wallet: Wallet, balanceManager: BalanceManager, transactionManager: TransactionManager, reachabilityManager: ReachabilityManager, segWitHelper: SegWitBech32, networkType: NetworkType, logger: Logger? = nil) {
        self.wallet = wallet
        self.balanceManager = balanceManager
        self.transactionManager = transactionManager
        self.reachabilityManager = reachabilityManager
        self.segWitHelper = segWitHelper
        self.networkType = networkType
        self.logger = logger

        lastBlockHeight = balanceManager.latestBlock?.height

        reachabilityManager.reachabilityObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.refresh()
                })
                .disposed(by: disposeBag)
    }

    private func asset(symbol: String) -> Asset? {
        assets.first { $0.symbol == symbol }
    }

    private func watchOnChain(transaction hash: String) {
        transactionManager.blockHeightSingle(forTransaction: hash)
                .subscribe(
                        onSuccess: { [weak self] blockHeight in
                            self?.refresh()
                        }, onError: { [weak self] error in
                            self?.logger?.error("Transaction send error: \(error)")
                        }
                )
                .disposed(by: disposeBag)
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
            syncState = .notSynced(error: ReachabilityManager.ReachabilityError.notReachable)
            return
        }

        guard syncState != .syncing else {
            logger?.debug("Already syncing balances")
            return
        }

        logger?.debug("Syncing")
        syncState = .syncing

        balanceManager.sync(account: wallet.address)
        transactionManager.sync()
    }

    public var lastBlockHeightObservable: Observable<Int> {
        lastBlockHeightSubject.asObservable()
    }

    public var syncStateObservable: Observable<SyncState> {
        syncStateSubject.asObservable()
    }

    public func validate(address: String) throws {
        try _ = segWitHelper.decode(addr: address)
    }

    public func transactionsSingle(symbol: String, fromTransactionHash: String? = nil, limit: Int? = nil) -> Single<[TransactionInfo]> {
        transactionManager.transactionsSingle(symbol: symbol, fromTransactionHash: fromTransactionHash, limit: limit).map {
            $0.map { transaction in TransactionInfo(transaction: transaction) }
        }
    }

    public func transaction(symbol: String, hash: String) -> TransactionInfo? {
        transactionManager.transaction(symbol: symbol, hash: hash).map { TransactionInfo(transaction: $0) }
    }

    public func sendSingle(symbol: String, to: String, amount: Decimal, memo: String) -> Single<String> {
        logger?.debug("Sending \(amount) \(symbol) to \(to)")

        return transactionManager.sendSingle(symbol: symbol, to: to, amount: amount, memo: memo)
                .do(onSuccess: { [weak self] hash in
                    self?.watchOnChain(transaction: hash)
                })
    }

    public func moveToBSCSingle(symbol: String, amount: Decimal) -> Single<String> {
        logger?.debug("Moving \(amount) \(symbol) to BSC")

        let bscPublicKeyHash: Data
        do {
            bscPublicKeyHash = try wallet.publicKeyHash(path: networkType == .mainNet ? Wallet.bscMainNetKeyPath : Wallet.bscTestNetKeyPath)
        } catch {
            return Single.error(error)
        }

        return transactionManager.moveToBscSingle(symbol: symbol, bscPublicKeyHash: bscPublicKeyHash, amount: amount)
                .do(onSuccess: { [weak self] hash in
                    self?.watchOnChain(transaction: hash)
                })
    }

    public var statusInfo: [(String, Any)] {
        [
            ("Synced Until", balanceManager.latestBlock?.time ?? "N/A"),
            ("Last Block Height", balanceManager.latestBlock?.height ?? "N/A"),
            ("Sync State", syncState.description),
            ("RPC Host", networkType.endpoint),
        ]
    }

}


extension BinanceChainKit: IBalanceManagerDelegate {

    func didSync(balances: [Balance], latestBlockHeight: Int) {
        for balance in balances {
            asset(symbol: balance.symbol)?.balance = balance.amount
        }
        lastBlockHeight = latestBlockHeight
        syncState = .synced
    }

    func didFailToSync(error: Error) {
        syncState = .notSynced(error: error)
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

    public static func instance(seed: Data, networkType: NetworkType = .mainNet, walletId: String, minLogLevel: Logger.Level = .error) throws -> BinanceChainKit {
        let logger = Logger(minLogLevel: minLogLevel)

        let uniqueId = "\(walletId)-\(networkType)"
        let storage: IStorage = try Storage(databaseDirectoryUrl: dataDirectoryUrl(), databaseFileName: "binance-chain-\(uniqueId)")

        let segWitHelper = Self.segWitHelper(networkType: networkType)
        let wallet = try Self.wallet(seed: seed, segWitHelper: segWitHelper)

        let apiProvider = BinanceChainApiProvider(networkManager: NetworkManager(logger: logger), endpoint: networkType.endpoint)

        let accountSyncer = AccountSyncer(apiProvider: apiProvider, logger: logger)
        let balanceManager = BalanceManager(storage: storage, accountSyncer: accountSyncer, logger: logger)
        let transactionManager = TransactionManager(storage: storage, wallet: wallet, apiProvider: apiProvider, accountSyncer: accountSyncer, logger: logger)
        let reachabilityManager = ReachabilityManager()

        let binanceChainKit = BinanceChainKit(wallet: wallet, balanceManager: balanceManager, transactionManager: transactionManager, reachabilityManager: reachabilityManager, segWitHelper: segWitHelper, networkType: networkType, logger: logger)
        balanceManager.delegate = binanceChainKit
        transactionManager.delegate = binanceChainKit

        return binanceChainKit
    }

    public static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
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

    private static func segWitHelper(networkType: NetworkType) -> SegWitBech32 {
        SegWitBech32(hrp: networkType.addressPrefix)
    }

    private static func wallet(seed: Data, segWitHelper: SegWitBech32) throws -> Wallet {
        let hdWallet = HDWallet(seed: seed, coinType: 714, xPrivKey: 0, xPubKey: 0)
        return try Wallet(hdWallet: hdWallet, segWitHelper: segWitHelper)
    }
}


extension BinanceChainKit {

    public enum SyncState: Equatable, CustomStringConvertible {
        case synced
        case syncing
        case notSynced(error: Error)

        public static func ==(lhs: SyncState, rhs: SyncState) -> Bool {
            switch (lhs, rhs) {
            case (.synced, .synced): return true
            case (.syncing, .syncing): return true
            case (.notSynced(let lhsError), .notSynced(let rhsError)): return "\(lhsError)" == "\(rhsError)"
            default: return false
            }
        }


        public var description: String {
            switch self {
            case .synced: return "synced"
            case .syncing: return "syncing"
            case .notSynced(let error): return "not synced: \(error)"
            }
        }
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

    public enum ApiError: Error {
        case noTransactionReturned
        case wrongTransaction
    }

    public enum SyncError: Error {
        case notStarted
    }

    public enum CoderError: Error {
        case bitsConversionFailed
        case hrpMismatch(String, String)
        case checksumSizeTooLow
        case dataSizeMismatch(Int)
        case encodingCheckFailed
    }

}

extension BinanceChainKit {

    public class BinanceAccountProvider {
        private let segWitHelper: SegWitBech32
        private let apiProvider: BinanceChainApiProvider

        public init(networkType: NetworkType = .mainNet) {
            segWitHelper = BinanceChainKit.segWitHelper(networkType: networkType)
            apiProvider = BinanceChainApiProvider(networkManager: NetworkManager(), endpoint: networkType.endpoint)
        }

        public func accountSingle(seed: Data) throws -> Single<Account> {
            let wallet = try BinanceChainKit.wallet(seed: seed, segWitHelper: segWitHelper)
            return apiProvider.accountSingle(for: wallet.address)
        }

    }

}
