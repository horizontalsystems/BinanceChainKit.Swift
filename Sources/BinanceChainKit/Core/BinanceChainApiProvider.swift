import Foundation
import HsToolKit
import Alamofire

// https://binance-chain.github.io/api-reference/dex-api/paths.html

class BinanceChainApiProvider {

    internal enum Path: String {
        case time = "time"
        case nodeInfo = "node-info"
        case validators = "validators"
        case peers = "peers"
        case account = "account"
        case sequence = "sequence"
        case tx = "tx"
        case tokens = "tokens"
        case markets = "markets"
        case fees = "fees"
        case depth = "depth"
        case broadcast = "broadcast"
        case klines = "klines"
        case closedOrders = "orders/closed"
        case openOrders = "orders/open"
        case orders = "orders"
        case ticker = "ticker/24hr"
        case trades = "trades"
        case transactions = "transactions"
    }

    public class Response {
        public var sequence: Int = 0
        public var blockHeight: Int = 0
        public var fees: [Fee] = []
        public var peers: [Peer] = []
        public var tokens: [Token] = []
        public var trades: [Trade] = []
        public var markets: [Market] = []
        public var candlesticks: [Candlestick] = []
        public var ticker: [TickerStatistics] = []
        public var broadcast: [ApiTransaction] = []
        public var apiTransaction: ApiTransaction = ApiTransaction()
        public var orders: [Order] = []
        public var order: Order = Order()
        public var orderList: OrderList = OrderList()
        public var tx: Tx = Tx()
        public var transfer: Transfer = Transfer()
        public var time: Times = Times()
        public var account: Account = Account()
        public var validators: Validators = Validators()
        public var marketDepth: MarketDepth = MarketDepth()
        public var marketDepthUpdate: MarketDepthUpdate = MarketDepthUpdate()
        public var nodeInfo: NodeInfo = NodeInfo()
        public var transactions: Transactions = Transactions()
    }

    private let networkManager: NetworkManager
    private var endpoint: String

    init(networkManager: NetworkManager, endpoint: String) {
        self.networkManager = networkManager
        self.endpoint = endpoint
    }


    private func time() async throws {
        try await self.api(path: .time, method: .get, parser: TimesParser())
    }

    private func validators() async throws {
        try await self.api(path: .validators, method: .get, parser: ValidatorsParser())
    }

    private func peers() async throws {
        try await self.api(path: .peers, method: .get, parser: PeerParser())
    }

    private func account(address: String) async throws -> Account {
        let path = String(format: "%@/%@", Path.account.rawValue, address)
        return try await api(path: path, method: .get, parser: AccountParser()).account
    }

    private func sequence(address: String) async throws -> Int {
        let path = String(format: "%@/%@/%@", Path.account.rawValue, address, Path.sequence.rawValue)
        return try await api(path: path, method: .get, parser: SequenceParser()).sequence
    }

    private func tx(hash: String) async throws -> ApiTransaction {
        let path = String(format: "%@/%@?format=json", Path.tx.rawValue, hash)
        return try await api(path: path, method: .get, parser: ApiTransactionParser()).apiTransaction
    }

    private func tokens(limit: Limit? = nil, offset: Int? = nil) async throws {
        var parameters: Parameters = [:]
        if let limit = limit {
            parameters["limit"] = limit.rawValue
        }
        if let offset = offset {
            parameters["offset"] = offset
        }
        try await self.api(path: .tokens, method: .get, parameters: parameters, parser: TokenParser())
    }

    private func markets(limit: Limit? = nil, offset: Int? = nil) async throws {
        var parameters: Parameters = [:]
        if let limit = limit {
            parameters["limit"] = limit.rawValue
        }
        if let offset = offset {
            parameters["offset"] = offset
        }
        try await self.api(path: .markets, method: .get, parameters: parameters, parser: MarketsParser())
    }

    private func fees() async throws {
        try await self.api(path: .fees, method: .get, parser: FeesParser())
    }

    private func marketDepth(symbol: String, limit: Limit? = nil) async throws {
        var parameters: Parameters = [:]
        parameters["symbol"] = symbol
        if let limit = limit {
            parameters["limit"] = limit.rawValue
        }
        try await self.api(path: .depth, method: .get, parameters: parameters, parser: MarketDepthParser())
    }

    private func broadcast(message: Message, sync: Bool = true) async throws -> [ApiTransaction] {
        let bytes = try message.encode()
        return try await broadcast(message: bytes, sync: sync)
    }

    private func broadcast(message bytes: Data, sync: Bool = true) async throws -> [ApiTransaction] {
        var path = Path.broadcast.rawValue
        if (sync) {
            path += "/?sync=1"
        }

        return try await api(path: path, method: .post, body: bytes, parser: BroadcastParser()).broadcast
    }

    private func klines(symbol: String, interval: Interval? = nil, limit: Limit? = nil, startTime: TimeInterval? = nil, endTime: TimeInterval? = nil) async throws {
        var parameters: Parameters = [:]
        parameters["symbol"] = symbol
        if let interval = interval {
            parameters["interval"] = interval.rawValue
        }
        if let limit = limit {
            parameters["limit"] = limit
        }
        if let startTime = startTime {
            parameters["startTime"] = startTime
        }
        if let endTime = endTime {
            parameters["endTime"] = endTime
        }
        try await self.api(path: .klines, method: .get, parameters: parameters, parser: CandlestickParser())
    }

    private func closedOrders(address: String, endTime: TimeInterval? = nil, limit: Limit? = nil, offset: Int? = nil, side: Side? = nil, startTime: TimeInterval? = nil,
                              status: Status? = nil, symbol: String? = nil, total: Total = .required) async throws -> OrderList {
        var parameters: Parameters = [:]
        parameters["address"] = address
        parameters["total"] = total.rawValue
        if let endTime = endTime {
            parameters["endTime"] = endTime
        }
        if let limit = limit {
            parameters["limit"] = limit.rawValue
        }
        if let offset = offset {
            parameters["offset"] = offset
        }
        if let side = side {
            parameters["side"] = side.rawValue
        }
        if let startTime = startTime {
            parameters["startTime"] = startTime
        }
        if let status = status {
            parameters["status"] = status.rawValue
        }
        if let symbol = symbol {
            parameters["symbol"] = symbol
        }
        let path = String(format: "%@/?%@", Path.closedOrders.rawValue, parameters.query)
        return try await self.api(path: path, method: .get, parser: OrderListParser()).orderList
    }

    private func openOrders(address: String, limit: Limit? = nil, offset: Int? = nil, symbol: String? = nil, total: Total = .required) async throws -> OrderList {
        var parameters: Parameters = [:]
        parameters["address"] = address
        parameters["total"] = total.rawValue
        if let limit = limit {
            parameters["limit"] = limit.rawValue
        }
        if let offset = offset {
            parameters["offset"] = offset
        }
        if let symbol = symbol {
            parameters["symbol"] = symbol
        }
        let path = String(format: "%@/?%@", Path.openOrders.rawValue, parameters.query)
        return try await self.api(path: path, method: .get, parser: OrderListParser()).orderList
    }

    private func order(id: String) async throws -> Order {
        let path = String(format: "%@/%@", Path.orders.rawValue, id)
        return try await self.api(path: path, method: .get, parser: OrderParser()).order
    }

    private func ticker(symbol: String) async throws -> [TickerStatistics] {
        let path = String(format: "%@/?symbol=%@", Path.ticker.rawValue, symbol)
        return try await self.api(path: path, method: .get, parser: TickerStatisticsParser()).ticker
    }

    private func trades(address: String? = nil, buyerOrderId: String? = nil, end: TimeInterval? = nil, height: Double? = nil, offset: Int? = nil, quoteAsset: String? = nil, sellerOrderId: String? = nil, side: Side? = nil, start: TimeInterval? = nil, symbol: String? = nil, total: Total? = nil) async throws {
        var parameters: Parameters = [:]
        parameters["address"] = address
        if let end = end {
            parameters["end"] = end
        }
        if let height = height {
            parameters["height"] = height
        }
        if let offset = offset {
            parameters["offset"] = offset
        }
        if let quoteAsset = quoteAsset {
            parameters["quoteAsset"] = quoteAsset
        }
        if let sellerOrderId = sellerOrderId {
            parameters["sellerOrderId"] = sellerOrderId
        }
        if let side = side {
            parameters["side"] = side.rawValue
        }
        if let start = start {
            parameters["start"] = start
        }
        if let symbol = symbol {
            parameters["symbol"] = symbol
        }
        if let total = total {
            parameters["total"] = total.rawValue
        }
        try await self.api(path: .trades, method: .get, parameters: parameters, parser: TradeParser())
    }

    private func transactions(address: String, blockHeight: Double? = nil, endTime: TimeInterval? = nil, limit: Limit? = nil, offset: Int? = nil, side: Side? = nil, startTime: TimeInterval? = nil, txAsset: String? = nil, txType: TxType? = nil) async throws -> Transactions {
        var parameters: Parameters = [:]
        parameters["address"] = address
        if let blockHeight = blockHeight {
            parameters["blockHeight"] = blockHeight
        }
        if let endTime = endTime {
            parameters["endTime"] = endTime
        }
        if let limit = limit {
            parameters["limit"] = limit.rawValue
        }
        if let offset = offset {
            parameters["offset"] = offset
        }
        if let side = side {
            parameters["side"] = side.rawValue
        }
        if let startTime = startTime {
            parameters["startTime"] = Int(startTime * 1000)
        }
        if let txAsset = txAsset {
            parameters["txAsset"] = txAsset
        }
        if let txType = txType {
            parameters["txType"] = txType.rawValue
        }

        return try await api(path: .transactions, method: .get, parameters: parameters, parser: TransactionsParser()).transactions
    }

    private func broadcast(message: Message) async throws -> String {
        let transactions = try await broadcast(message: message, sync: true)

        guard let transaction = transactions.first else {
            throw BinanceChainKit.ApiError.noTransactionReturned
        }

        guard transaction.ok else {
            throw BinanceChainKit.ApiError.wrongTransaction
        }

        return transaction.hash
    }

    // MARK: - Utils

    @discardableResult
    func api(path: Path, method: HTTPMethod = .get, parameters: Parameters = [:], body: Data? = nil, parser: Parser) async throws -> BinanceChainApiProvider.Response {
        try await self.api(path: path.rawValue, method: method, parameters: parameters, parser: parser)
    }

    func api(path: String, method: HTTPMethod = .get, parameters: Parameters = [:], body: Data? = nil, parser: Parser) async throws -> BinanceChainApiProvider.Response {
        var encoding: ParameterEncoding = URLEncoding.default
        if let body = body {
            encoding = HexEncoding(data: body)
        }
        let url = String(format: "%@/api/v1/%@", endpoint, path)

        let data = try await networkManager.fetchData(url: url, method: method, parameters: parameters, encoding: encoding, interceptor: RateLimitRetrier(), responseCacherBehavior: .doNotCache)

        return try parser.parse(data: data)
    }

}

extension BinanceChainApiProvider: RequestInterceptor {

    class RateLimitRetrier: RequestInterceptor {
        private var attempt = 0

        func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> ()) {
            if let afError = error as? AFError, case let .responseValidationFailed(reason) = afError, case let .unacceptableStatusCode(code) = reason, code == 429 {
                completion(resolveResult())
            } else {
                completion(.doNotRetry)
            }
        }

        private func resolveResult() -> RetryResult {
            attempt += 1

            if attempt == 1 { return .retryWithDelay(1) }
            if attempt == 2 { return .retryWithDelay(3) }

            return .doNotRetry
        }

    }

}

extension BinanceChainApiProvider: IApiProvider {

    func nodeInfo() async throws -> NodeInfo {
        try await self.api(path: .nodeInfo, method: .get, parser: NodeInfoParser()).nodeInfo
    }

    func transactions(account: String, limit: Int, startTime: TimeInterval) async throws -> [Tx] {
        try await transactions(address: account, limit: Limit(rawValue: limit), startTime: startTime, txType: .transfer).tx
    }

    func account(for address: String) async throws -> Account {
        do {
            return try await account(address: address)
        } catch {
            if let networkError = error as? NetworkManager.ResponseError, networkError.statusCode == 404 {
                // New account
                return Account()
            }
            if let afError = error as? AFError, case let .responseValidationFailed(reason) = afError, case let .unacceptableStatusCode(code) = reason, code == 404 {
                // New account
                return Account()
            }

            throw error
        }
    }

    func send(symbol: String, to: String, amount: Double, memo: String, wallet: Wallet) async throws -> String {
        let message = Message.transfer(symbol: symbol, amount: amount, to: to, memo: memo, wallet: wallet)
        return try await broadcast(message: message)
    }

    func transferOut(symbol: String, bscPublicKeyHash: Data, amount: Double, expireTime: Int64, wallet: Wallet) async throws -> String {
        let message = Message.transferOut(symbol: symbol, bscPublicKeyHash: bscPublicKeyHash, amount: amount, expireTime: expireTime, wallet: wallet)
        return try await broadcast(message: message)
    }

    func blockHeight(forTransaction hash: String) async throws -> Int {
        let transaction = try await tx(hash: hash)
        return Int(transaction.height) ?? 0
    }

}
