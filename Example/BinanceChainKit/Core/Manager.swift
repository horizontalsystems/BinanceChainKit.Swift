import RxSwift
import BinanceChainKit
import HdWalletKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"
    private var walletId: String?

    var binanceChainKit: BinanceChainKit!

    var binanceAdapters = [BinanceChainAdapter]()

    init() {
        if let words = savedWords {
            try? initBinanceChainKit(words: words)
        }
    }

    func login(words: [String]) throws {
        if let walletId = self.walletId {
            try BinanceChainKit.clear(exceptFor: [walletId])
        }

        try initBinanceChainKit(words: words)
        save(words: words)
    }

    func logout() {
        clearAuth()

        binanceChainKit = nil
        binanceAdapters = []
    }

    private func initBinanceChainKit(words: [String]) throws {
        let configuration = Configuration.shared
        walletId = NSUUID().uuidString

        let seed = Mnemonic.seed(mnemonic: words)
        let binanceChainKit = try BinanceChainKit.instance(
                seed: seed,
                networkType: configuration.networkType,
                walletId: walletId!,
                minLogLevel: configuration.minLogLevel
        )

        binanceChainKit.refresh()

        binanceAdapters = [
            BinanceChainAdapter(binanceChainKit: binanceChainKit, symbol: "BNB"),
            BinanceChainAdapter(binanceChainKit: binanceChainKit, symbol: "AXPR-A6B"),
        ]

        self.binanceChainKit = binanceChainKit
    }

    private var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func clearAuth() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

}
