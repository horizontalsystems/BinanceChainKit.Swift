import Foundation
import BinanceChainKit
import HdWalletKit

class Manager {
    static let shared = Manager()

    private let keyWords = "mnemonic_words"

    var binanceChainKit: BinanceChainKit!
    var adapter: BinanceChainAdapter!

    init() {
        if let words = savedWords {
            try? initKit(words: words)
        }
    }

    private func initKit(words: [String]) throws {
        let configuration = Configuration.shared

        guard let seed = Mnemonic.seed(mnemonic: words) else {
            throw LoginError.seedGenerationFailed
        }

        let binanceChainKit = try BinanceChainKit.instance(
                seed: seed,
                networkType: configuration.networkType,
                walletId: "walletId",
                minLogLevel: configuration.minLogLevel
        )

        binanceChainKit.refresh()

        adapter = BinanceChainAdapter(binanceChainKit: binanceChainKit, symbol: "BNB")
//        adapter = BinanceChainAdapter(binanceChainKit: binanceChainKit, symbol: "AXPR-A6B")

        self.binanceChainKit = binanceChainKit
    }

    private var savedWords: [String]? {
        guard let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String else {
            return nil
        }

        return wordsString.split(separator: " ").map(String.init)
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func clearStorage() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

}

extension Manager {

    func login(words: [String]) throws {
        try BinanceChainKit.clear(exceptFor: ["walletId"])

        save(words: words)
        try initKit(words: words)
    }

    func logout() {
        clearStorage()

        binanceChainKit = nil
        adapter = nil
    }

}

extension Manager {

    enum LoginError: Error {
        case seedGenerationFailed
    }

}
