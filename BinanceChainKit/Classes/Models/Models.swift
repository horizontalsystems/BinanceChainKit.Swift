import Foundation

class Times: CustomStringConvertible {
    var apTime: Date = Date()
    var blockTime: Date = Date()
}

class Validators: CustomStringConvertible {
    var blockHeight: Int = 0
    var validators: [Validator] = []
}

class Validator: CustomStringConvertible {
    var address: String = ""
    var publicKey: Data = Data()
    var votingPower: Int = 0
}

class Peer: CustomStringConvertible {
    var id: String = ""
    var originalListenAddr: String = ""
    var listenAddr: String = ""
    var accessAddr: String = ""
    var streamAddr: String = ""
    var network: String = ""
    var version: String = ""
    var moniker: String = ""
    var capabilities: [String] = []
    var accelerated: Bool = false
}

class NodeInfo: CustomStringConvertible {
    var id: String = ""
    var listenAddr: String = ""
    var network: String = ""
    var version: String = ""
    var moniker: String = ""
    var address: String = ""
    var channels: String = ""
    var other: [String:String] = [:]
    var syncInfo: [String:Any] = [:]
    var validatorInfo: Validator = Validator()
}

class Transactions: CustomStringConvertible {
    var total: Int = 0
    var tx: [Tx] = []
}

class ApiTransaction: CustomStringConvertible {
    var hash: String = ""
    var log: String = ""
    var data: String = ""
    var height: String = ""
    var code: Int = 0
    var ok: Bool = false
    var tx: Tx = Tx()
}

public class Account: CustomStringConvertible {
    public var accountNumber: Int = 0
    public var address: String = ""
    public var balances: [ApiBalance] = []
    public var publicKey: Data = Data()
    public var sequence: Int = 0
}

class AccountSequence: CustomStringConvertible {
    var sequence: Int = 0
}

public class ApiBalance: CustomStringConvertible {
    public var symbol: String = ""
    public var free: Double = 0
    public var locked: Double = 0
    public var frozen: Double = 0
}

class Token: CustomStringConvertible {
    var name: String = ""
    var symbol: String = ""
    var originalSymbol: String = ""
    var totalSupply: Double = 0
    var owner: String = ""
}

class Market: CustomStringConvertible {
    var baseAssetSymbol: String = ""
    var quoteAssetSymbol: String = ""
    var price: Double = 0
    var tickSize: Double = 0
    var lotSize: Double = 0
}

class Fee: CustomStringConvertible {
    var msgType: String = ""
    var fee: String = ""
    var feeFor: FeeFor = .all
    var multiTransferFee: Int = 0
    var lowerLimitAsMulti: Int = 0
    var fixedFeeParams: FixedFeeParams?
}

class FixedFeeParams: CustomStringConvertible {
    var msgType: String = ""
    var fee: String = ""
    var feeFor: FeeFor = .all
}

class PriceQuantity: CustomStringConvertible {
    var price: Double = 0
    var quantity: Double = 0
}

class MarketDepth: CustomStringConvertible {
    var asks: [PriceQuantity] = []
    var bids: [PriceQuantity] = []
}

class MarketDepthUpdate: CustomStringConvertible {
    var symbol: String = ""
    var depth: MarketDepth = MarketDepth()
}

class BlockTradePage: CustomStringConvertible {
    var total: Int = 0
    var blockTrade: [BlockTrade] = []
}

class BlockTrade: CustomStringConvertible {
    var blockTime: TimeInterval = 0
    var fee: Int = 0
    var height: Int = 0
    var trade: [Trade] = []
}

class Candlestick: CustomStringConvertible {
    var close: Double = 0
    var closeTime: Date = Date()
    var high: Double = 0
    var low: Double = 0
    var numberOfTrades: Int = 0
    var open: Double = 0
    var openTime: Date = Date()
    var quoteAssetVolume: Double = 0
    var volume: Double = 0
    var closed: Bool = false
}

class OrderList: CustomStringConvertible {
    var total: Int = 0
    var orders: [Order] = []
}

class Order: CustomStringConvertible {
    var cumulateQuantity: String = ""
    var fee: String = ""
    var lastExecutedPrice: String = ""
    var lastExecuteQuantity: String = ""
    var orderCreateTime: Date = Date()
    var orderId: String = ""
    var owner: String = ""
    var price: Double = 0
    var side: Side = .buy
    var status: Status = .acknowledge
    var symbol: String = ""
    var timeInForce: TimeInForce = .immediateOrCancel
    var tradeId: String = ""
    var transactionHash: String = ""
    var transactionTime: Date = Date()
    var type: OrderType = .limit
}

class TickerStatistics: CustomStringConvertible {
    var askPrice: Double = 0
    var askQuantity: Double = 0
    var bidPrice: Double = 0
    var bidQuantity: Double = 0
    var closeTime: Date = Date()
    var count: Int = 0
    var firstId: String = ""
    var highPrice: Double = 0
    var lastId: String = ""
    var lastPrice: Double = 0
    var lastQuantity: Double = 0
    var lowPrice: Double = 0
    var openPrice: Double = 0
    var openTime: Date = Date()
    var prevClosePrice: Double = 0
    var priceChange: Double = 0
    var priceChangePercent: Double = 0
    var quoteVolume: Double = 0
    var symbol: String = ""
    var volume: Double = 0
    var weightedAvgPrice: Double = 0
}

class TradePage: CustomStringConvertible {
    var total: Int = 0
    var trade: [Trade] = []
}

class Trade: CustomStringConvertible {
    var baseAsset: String = ""
    var blockHeight: Int = 0
    var buyFee: String = ""
    var buyerId: String = ""
    var buyerOrderId: String = ""
    var price: String = ""
    var quantity: String = ""
    var quoteAsset: String = ""
    var sellFee: String = ""
    var sellerId: String = ""
    var symbol: String = ""
    var time: Date = Date()
    var tradeId: String = ""
}

class TxPage: CustomStringConvertible {
    var total: Int = 0
    var tx: [Tx] = []
}

class Tx: CustomStringConvertible {
    var blockHeight: Double = 0
    var code: Int = 0
    var confirmBlocks: Double = 0
    var data: String = ""
    var fromAddr: String = ""
    var orderId: String = ""
    var timestamp: Date = Date()
    var toAddr: String = ""
    var txAge: Double = 0
    var txAsset: String = ""
    var txFee: String = ""
    var txHash: String = ""
    var txType: TxType = .newOrder
    var value: String = ""
    var memo: String = ""
}

class Transfer: CustomStringConvertible {
    var height: Int = 0
    var transactionHash: String = ""
    var fromAddr: String = ""
    var transferred: [Transferred] = []
}

class Transferred: CustomStringConvertible {
    var toAddr: String = ""
    var amounts: [Amount] = []
}

class Amount: CustomStringConvertible {
    var asset: String = ""
    var amount: Double = 0
}
