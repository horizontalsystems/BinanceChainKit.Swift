import Foundation

struct TransactionRecord {
    let hash: String
    let blockNumber: Int
    let date: Date
    let from: TransactionAddress
    let to: TransactionAddress
    let amount: Decimal
    let symbol: String
    let fee: Decimal
    let memo: String?
}

struct TransactionAddress {
    let address: String
    let mine: Bool
}
