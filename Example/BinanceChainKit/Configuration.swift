import BinanceChainKit

class Configuration {
    static let shared = Configuration()

    let networkType: BinanceChainKit.NetworkType = .testNet
    let minLogLevel: Logger.Level = .error

    let defaultWords = "error sound chuckle illness reveal echo close lock buddy large cook apple saddle rural trouble matter pluck inner window need sphere census smooth sun"
}
