import Foundation
import HsCryptoKit

struct EIP55 {

    static func format(address: Data) -> String {
        let address = address.reduce("") { $0 + String(format: "%02x", $1) }

        guard !address.isEmpty else {
            return address
        }

        guard address == address.lowercased() || address == address.uppercased() else {
            return "0x" + address
        }

        let hash = Crypto.sha3(address.lowercased().data(using: .ascii)!).reduce("") { $0 + String(format: "%02x", $1) }

        return "0x" + zip(address, hash)
                .map { a, h -> String in
                    switch (a, h) {
                    case ("0", _), ("1", _), ("2", _), ("3", _), ("4", _), ("5", _), ("6", _), ("7", _), ("8", _), ("9", _):
                        return String(a)
                    case (_, "8"), (_, "9"), (_, "a"), (_, "b"), (_, "c"), (_, "d"), (_, "e"), (_, "f"):
                        return String(a).uppercased()
                    default:
                        return String(a).lowercased()
                    }
                }
                .joined()
    }

}
