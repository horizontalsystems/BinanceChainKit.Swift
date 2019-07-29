import Foundation
import HSHDWalletKit
import HSCryptoKit

public class Wallet {

    public static let accountPrivateKeyPath = "m/44'/714'/0'/0/0"

    public var sequence: Int = 0
    public var accountNumber: Int = 0
    public var chainId: String = ""

    public let publicKey: Data
    public let publicKeyHash: Data
    public let address: String

    private let privateKey: Data
    private let hrp: String

    public init(hdWallet: HDWallet, networkType: BinanceChainKit.NetworkType) throws {
        privateKey = try hdWallet.privateKey(path: Wallet.accountPrivateKeyPath).raw
        hrp = networkType.addressPrefix

        let privateKey = try hdWallet.privateKey(path: Wallet.accountPrivateKeyPath).raw
        publicKey = Data(CryptoKit.createPublicKey(fromPrivateKeyData: privateKey, compressed: true))
        publicKeyHash = CryptoKit.ripemd160(CryptoKit.sha256(publicKey))
        address = try SegWitBech32.encode(hrp: networkType.addressPrefix, program: publicKeyHash)
    }

    public func incrementSequence() {
        sequence += 1
    }

    public func nextAvailableOrderId() -> String {
        return String(format: "%@-%d", self.publicKeyHashHex.uppercased(), self.sequence + 1)
    }

    public var publicKeyHashHex: String {
        return publicKeyHash.hexlify
    }

    public func publicKeyHash(from address: String) throws -> Data {
        return try SegWitBech32.decode(hrp: hrp, addr: address)
    }

    public func sign(message: Data) throws -> Data {
        let hash = CryptoKit.sha256(message)
        return try CryptoKit.compactsign(hash, privateKey: self.privateKey)
    }

}

extension Wallet : CustomStringConvertible {

    public var description: String {
        return String(format: "Wallet [address=%@ accountNumber=%d, sequence=%d, chain_id=%@, account=%@, publicKey=%@]",
                address, accountNumber, sequence, chainId, address, publicKey.hexlify)
    }

}
