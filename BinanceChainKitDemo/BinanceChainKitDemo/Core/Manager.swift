import RxSwift
import BinanceChainKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    var binanceChainKit: BinanceChainKit!

    var eosAdapters = [BinanceChainAdapter]()

    init() {
        if let words = savedWords {
            try? initBinanceChainKit(words: words)
        }
    }

    func login(words: [String]) throws {
        try BinanceChainKit.clear()
        try initBinanceChainKit(words: words)
        save(words: words)
    }

    func logout() {
        clearAuth()

        binanceChainKit = nil
        eosAdapters = []
    }

    private func initBinanceChainKit(words: [String]) throws {
        let configuration = Configuration.shared

        let binanceChainKit = try BinanceChainKit.instance(
                words: words,
                networkType: configuration.networkType,
                minLogLevel: configuration.minLogLevel
        )

        binanceChainKit.refresh()

        eosAdapters = [
            BinanceChainAdapter(binanceChainKit: binanceChainKit, symbol: "BNB"),
            BinanceChainAdapter(binanceChainKit: binanceChainKit, symbol: "ZCB-F00"),
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
