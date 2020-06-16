import Foundation
import HsToolKit
import Alamofire
import RxSwift

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


    private func time() {
        self.api(path: .time, method: .get, parser: TimesParser())
    }

    private func nodeInfo() -> Single<NodeInfo> {
        self.api(path: .nodeInfo, method: .get, parser: NodeInfoParser()).map { $0.nodeInfo }
    }

    private func validators() {
        self.api(path: .validators, method: .get, parser: ValidatorsParser())
    }

    private func peers() {
        self.api(path: .peers, method: .get, parser: PeerParser())
    }

    private func account(address: String) -> Single<Account> {
        let path = String(format: "%@/%@", Path.account.rawValue, address)
        return self.api(path: path, method: .get, parser: AccountParser()).map { $0.account }
    }

    private func sequence(address: String) -> Single<Int> {
        let path = String(format: "%@/%@/%@", Path.account.rawValue, address, Path.sequence.rawValue)
        return self.api(path: path, method: .get, parser: SequenceParser()).map { $0.sequence }
    }

    private func tx(hash: String) -> Single<ApiTransaction> {
        let path = String(format: "%@/%@?format=json", Path.tx.rawValue, hash)
        return self.api(path: path, method: .get, parser: ApiTransactionParser()).map { $0.apiTransaction }
    }

    private func tokens(limit: Limit? = nil, offset: Int? = nil) {
        var parameters: Parameters = [:]
        if let limit = limit {
            parameters["limit"] = limit.rawValue
        }
        if let offset = offset {
            parameters["offset"] = offset
        }
        self.api(path: .tokens, method: .get, parameters: parameters, parser: TokenParser())
    }

    private func markets(limit: Limit? = nil, offset: Int? = nil) {
        var parameters: Parameters = [:]
        if let limit = limit {
            parameters["limit"] = limit.rawValue
        }
        if let offset = offset {
            parameters["offset"] = offset
        }
        self.api(path: .markets, method: .get, parameters: parameters, parser: MarketsParser())
    }

    private func fees() {
        self.api(path: .fees, method: .get, parser: FeesParser())
    }

    private func marketDepth(symbol: String, limit: Limit? = nil) {
        var parameters: Parameters = [:]
        parameters["symbol"] = symbol
        if let limit = limit {
            parameters["limit"] = limit.rawValue
        }
        self.api(path: .depth, method: .get, parameters: parameters, parser: MarketDepthParser())
    }

    private func broadcast(message: Message, sync: Bool = true) -> Single<[ApiTransaction]> {
        do {
            let bytes = try message.encode()
            return self.broadcast(message: bytes, sync: sync)
        } catch let error {
            return Single.error(error)
        }

    }

    private func broadcast(message bytes: Data, sync: Bool = true) -> Single<[ApiTransaction]> {
        var path = Path.broadcast.rawValue
        if (sync) {
            path += "/?sync=1"
        }

        return self.api(path: path, method: .post, body: bytes, parser: BroadcastParser()).map { $0.broadcast }
    }

    private func klines(symbol: String, interval: Interval? = nil, limit: Limit? = nil, startTime: TimeInterval? = nil, endTime: TimeInterval? = nil) {
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
        self.api(path: .klines, method: .get, parameters: parameters, parser: CandlestickParser())
    }

    private func closedOrders(address: String, endTime: TimeInterval? = nil, limit: Limit? = nil, offset: Int? = nil, side: Side? = nil, startTime: TimeInterval? = nil,
                              status: Status? = nil, symbol: String? = nil, total: Total = .required) -> Single<OrderList> {
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
        return self.api(path: path, method: .get, parser: OrderListParser()).map { $0.orderList }
    }

    private func openOrders(address: String, limit: Limit? = nil, offset: Int? = nil, symbol: String? = nil, total: Total = .required) -> Single<OrderList> {
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
        return self.api(path: path, method: .get, parser: OrderListParser()).map { $0.orderList }
    }

    private func order(id: String) -> Single<Order> {
        let path = String(format: "%@/%@", Path.orders.rawValue, id)
        return self.api(path: path, method: .get, parser: OrderParser()).map { $0.order }
    }

    private func ticker(symbol: String) -> Single<[TickerStatistics]> {
        let path = String(format: "%@/?symbol=%@", Path.ticker.rawValue, symbol)
        return self.api(path: path, method: .get, parser: TickerStatisticsParser()).map { $0.ticker }
    }

    private func trades(address: String? = nil, buyerOrderId: String? = nil, end: TimeInterval? = nil, height: Double? = nil, offset: Int? = nil, quoteAsset: String? = nil, sellerOrderId: String? = nil, side: Side? = nil, start: TimeInterval? = nil, symbol: String? = nil, total: Total? = nil) {
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
        self.api(path: .trades, method: .get, parameters: parameters, parser: TradeParser())
    }

    private func transactions(address: String, blockHeight: Double? = nil, endTime: TimeInterval? = nil, limit: Limit? = nil, offset: Int? = nil, side: Side? = nil, startTime: TimeInterval? = nil, txAsset: String? = nil, txType: TxType? = nil) -> Single<Transactions> {
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
        return self.api(path: .transactions, method: .get, parameters: parameters, parser: TransactionsParser()).map { $0.transactions }
    }

    // MARK: - Utils

    @discardableResult
    func api(path: Path, method: HTTPMethod = .get, parameters: Parameters = [:], body: Data? = nil, parser: Parser = Parser()) -> Single<BinanceChainApiProvider.Response> {
        self.api(path: path.rawValue, method: method, parameters: parameters, parser: parser)
    }

    func api(path: String, method: HTTPMethod = .get, parameters: Parameters = [:], body: Data? = nil, parser: Parser = Parser()) -> Single<BinanceChainApiProvider.Response> {
        var encoding: ParameterEncoding = URLEncoding.default
        if let body = body {
            encoding = HexEncoding(data: body)
        }
        let url = String(format: "%@/api/v1/%@", self.endpoint, path)
        let request = networkManager.session
                .request(url, method: method, parameters: parameters, encoding: encoding, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request, mapper: parser)
    }

}

extension BinanceChainApiProvider: RequestInterceptor {

    class RateLimitRetrier: RequestInterceptor {
        private var attempt = 0

        func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> ()) {
            let error = NetworkManager.unwrap(error: error)

            if let binanceError = error as? BinanceError, binanceError.httpStatus == 429 {
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

    func nodeInfoSingle() -> Single<NodeInfo> {
        nodeInfo()
    }

    func transactionsSingle(account: String, limit: Int, startTime: TimeInterval) -> Single<[Tx]> {
        transactions(address: account, limit: Limit(rawValue: limit), startTime: startTime, txType: .transfer).map { $0.tx }
    }

    func accountSingle(for address: String) -> Single<Account> {
        account(address: address)
    }

    func sendSingle(symbol: String, to: String, amount: Double, memo: String, wallet: Wallet) -> Single<String> {
        let message = Message.transfer(symbol: symbol, amount: amount, to: to, memo: memo, wallet: wallet)

        return broadcast(message: message, sync: true).map { transactions in
            guard let transaction = transactions.first else {
                throw BinanceChainKit.ApiError.noTransactionReturned
            }

            guard transaction.ok else {
                throw BinanceChainKit.ApiError.wrongTransaction
            }

            return transaction.hash
        }
    }

    func blockHeightSingle(forTransaction hash: String) -> Single<Int> {
        tx(hash: hash).map { Int($0.height) ?? 0 }
    }
}
