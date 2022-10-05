import Foundation
import HdWalletKit
import HsCryptoKit

class Wallet {

    static let bcPrivateKeyPath = "m/44'/714'/0'/0/0"
    static let bscMainNetKeyPath = "m/44'/60'/0'/0/0"
    static let bscTestNetKeyPath = "m/44'/1'/0'/0/0"

    var sequence: Int = 0
    var accountNumber: Int = 0
    var chainId: String = ""

    let publicKey: Data
    let address: String

    private let hdWallet: HDWallet
    private let publicKeyHash: Data
    private let segWitHelper: SegWitBech32

    init(hdWallet: HDWallet, segWitHelper: SegWitBech32) throws {
        self.segWitHelper = segWitHelper
        self.hdWallet = hdWallet

        let privateKey = try hdWallet.privateKey(path: Wallet.bcPrivateKeyPath).raw
        publicKey = Crypto.publicKey(privateKey: privateKey, compressed: true)
        publicKeyHash = Crypto.ripeMd160Sha256(publicKey)
        address = try segWitHelper.encode(program: publicKeyHash)
    }

    func publicKeyHash(path: String) throws -> Data {
        let privateKey = try hdWallet.privateKey(path: path).raw
        let publicKey = Data(Crypto.publicKey(privateKey: privateKey, compressed: false).dropFirst())
        let sha3Hash = Crypto.sha3(publicKey)

        return Data(sha3Hash.suffix(20))
    }

    func incrementSequence() {
        sequence += 1
    }

    func nextAvailableOrderId() -> String {
        String(format: "%@-%d", publicKeyHashHex.uppercased(), sequence + 1)
    }

    var publicKeyHashHex: String {
        publicKeyHash.hexlify
    }

    func publicKeyHash(fromAddress address: String) throws -> Data {
        try segWitHelper.decode(addr: address)
    }

    func sign(message: Data) throws -> Data {
        let hash = Crypto.sha256(message)
        return try Crypto.sign(data: hash, privateKey: try hdWallet.privateKey(path: Wallet.bcPrivateKeyPath).raw, compact: true)
    }

}

extension Wallet : CustomStringConvertible {

    var description: String {
        String(format: "Wallet [address=%@ accountNumber=%d, sequence=%d, chain_id=%@, account=%@, publicKey=%@]",
                address, accountNumber, sequence, chainId, address, publicKey.hexlify)
    }

}
