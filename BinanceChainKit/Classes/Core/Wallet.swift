import Foundation
import HdWalletKit
import OpenSslKit
import Secp256k1Kit

class Wallet {

    static let accountPrivateKeyPath = "m/44'/714'/0'/0/0"

    var sequence: Int = 0
    var accountNumber: Int = 0
    var chainId: String = ""

    let publicKey: Data
    let address: String

    private let privateKey: Data
    private let publicKeyHash: Data
    private let segWitHelper: SegWitBech32

    init(hdWallet: HDWallet, segWitHelper: SegWitBech32) throws {
        self.segWitHelper = segWitHelper

        privateKey = try hdWallet.privateKey(path: Wallet.accountPrivateKeyPath).raw
        publicKey = Data(Kit.createPublicKey(fromPrivateKeyData: privateKey, compressed: true))
        publicKeyHash = Kit.ripemd160(Kit.sha256(publicKey))
        address = try segWitHelper.encode(program: publicKeyHash)
    }

    func incrementSequence() {
        sequence += 1
    }

    func nextAvailableOrderId() -> String {
        return String(format: "%@-%d", self.publicKeyHashHex.uppercased(), self.sequence + 1)
    }

    var publicKeyHashHex: String {
        return publicKeyHash.hexlify
    }

    func publicKeyHash(from address: String) throws -> Data {
        return try segWitHelper.decode(addr: address)
    }

    func sign(message: Data) throws -> Data {
        let hash = Kit.sha256(message)
        return try Kit.compactSign(hash, privateKey: self.privateKey)
    }

}

extension Wallet : CustomStringConvertible {

    var description: String {
        return String(format: "Wallet [address=%@ accountNumber=%d, sequence=%d, chain_id=%@, account=%@, publicKey=%@]",
                address, accountNumber, sequence, chainId, address, publicKey.hexlify)
    }

}
