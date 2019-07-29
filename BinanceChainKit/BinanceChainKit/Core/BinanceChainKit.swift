import Foundation
import HSCryptoKit
import HSHDWalletKit
import RxSwift

public class BinanceChainKit {

    private let wallet: Wallet
    private let symbol: String
    private let apiProvider: IApiProvider
    private let state: BinanceChainKitState

    private let logger: Logger?
    private let disposeBag = DisposeBag()

    private let lastBlockHeightSubject = PublishSubject<Int>()
    private let syncStateSubject = PublishSubject<SyncState>()
    private let balanceSubject = PublishSubject<String>()
    private let transactionsSubject = PublishSubject<[TransactionInfo]>()


    public private(set) var syncState: SyncState = .notSynced {
        didSet {
            if syncState != oldValue {
                syncStateSubject.onNext(syncState)
            }
        }
    }

    init(symbol: String, wallet: Wallet, apiProvider: IApiProvider, state: BinanceChainKitState = BinanceChainKitState(), logger: Logger? = nil) {
        self.symbol = symbol
        self.wallet = wallet
        self.apiProvider = apiProvider
        self.state = state
        self.logger = logger
    }

    func onUpdate(nodeInfo: NodeInfo) {
        wallet.chainId = nodeInfo.network

        guard let lastBlockHeightValue = nodeInfo.syncInfo["latest_block_height"],
              let lastBlockHeightNumber = lastBlockHeightValue as? NSNumber else {
            return
        }

        let lastBlockHeight = Int(lastBlockHeightNumber)
        guard state.lastBlockHeight != lastBlockHeight else {
            return
        }

        state.lastBlockHeight = lastBlockHeight
        lastBlockHeightSubject.onNext(lastBlockHeight)
    }

    func onUpdate(account: Account) {
        wallet.accountNumber = account.accountNumber
        wallet.sequence = account.sequence

        var balance: Double = 0
        for retrievedBalance in account.balances {
            if retrievedBalance.symbol == symbol {
                balance = Double(retrievedBalance.free)
            }
        }

        guard state.balance != balance else {
            return
        }

        state.balance = balance

        balanceSubject.onNext(balance.description)
    }

    func onUpdate(syncState: SyncState) {
        syncStateSubject.onNext(syncState)
    }

    func onUpdate(transactions: [Tx]) {
        transactionsSubject.onNext(transactions.map {
            TransactionInfo(tx: $0)
        })
    }

}

// Public API Extension

extension BinanceChainKit {

    public func start() {
        Single.zip(
                        apiProvider.nodeInfoSingle(),
                        apiProvider.accountSingle()
                )
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] nodeInfo, account in
                    self?.onUpdate(nodeInfo: nodeInfo)
                    self?.onUpdate(account: account)

                    self?.syncState = .synced
                }, onError: { [weak self] error in
                    self?.syncState = .notSynced
                    self?.logger?.error("Sync Failed: lastBlockHeight and balance: \(error)")
                })
                .disposed(by: disposeBag)
    }

    public func stop() {
    }

    public func refresh() {
    }

    public var lastBlockHeight: Int? {
        return state.lastBlockHeight
    }

    public var balance: String? {
        return state.balance?.description
    }

    public var receiveAddress: String {
        return wallet.address
    }

    public func transactionsSingle(fromHash: String?, limit: Int?) -> Single<[TransactionInfo]> {
        return apiProvider.transactionsSingle(symbol: symbol).map {
            $0.map { TransactionInfo(tx: $0) }
        }
    }

    public var lastBlockHeightObservable: Observable<Int> {
        return lastBlockHeightSubject.asObservable()
    }

    public var balanceObservable: Observable<String> {
        return balanceSubject.asObservable()
    }

    public var syncStateObservable: Observable<SyncState> {
        return syncStateSubject.asObservable()
    }

    public var transactionsObservable: Observable<[TransactionInfo]> {
        return transactionsSubject.asObservable()
    }

    public func sendSingle(to: String, value: Double) -> Single<TransactionInfo> {
        return apiProvider.sendSingle(symbol: symbol, to: to, amount: value, wallet: wallet).map {
            TransactionInfo(tx: $0)
        }
    }

    public func sendSingle(to: String, value: String) -> Single<TransactionInfo> {
        guard let value = Double(value) else {
            return Single.error(SendError.invalidValue)
        }

        return sendSingle(to: to, value: value)
    }

}

extension BinanceChainKit {

    public static func instance(words: [String], symbol: String, networkType: NetworkType = .mainNet, walletId: String = "default", minLogLevel: Logger.Level = .error) throws -> BinanceChainKit {
        let hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), coinType: 714, xPrivKey: 0, xPubKey: 0)
        let wallet = try Wallet(hdWallet: hdWallet, networkType: networkType)

        let apiProvider = AcceleratedNodeApiProvider(endpoint: networkType.endpoint, address: wallet.address)
        let logger = Logger(minLogLevel: minLogLevel)

        let binanceChainKit = BinanceChainKit(symbol: symbol, wallet: wallet, apiProvider: apiProvider, logger: logger)

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

    public enum NetworkError: Error {
        case invalidUrl
        case mappingError
        case noConnection
        case serverError(status: Int, data: Any?)
    }

    public enum SendError: Error {
        case invalidAddress
        case invalidContractAddress
        case invalidValue
        case nodeError(message: String)
    }

    public enum ApiError: Error {
        case invalidData
    }

    public enum SyncState: Equatable {
        case synced
        case syncing(progress: Double?)
        case notSynced

        public static func ==(lhs: BinanceChainKit.SyncState, rhs: BinanceChainKit.SyncState) -> Bool {
            switch (lhs, rhs) {
            case (.synced, .synced), (.notSynced, .notSynced): return true
            case (.syncing(let lhsProgress), .syncing(let rhsProgress)): return lhsProgress == rhsProgress
            default: return false
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

}
