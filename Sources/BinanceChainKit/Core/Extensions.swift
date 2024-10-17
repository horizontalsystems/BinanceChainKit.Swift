import Alamofire
import Foundation
import SwiftyJSON

extension String {

    var unhexlify: Data {
        let length = self.count / 2
        var data = Data(capacity: length)
        for i in 0 ..< length {
            let j = self.index(self.startIndex, offsetBy: i * 2)
            let k = self.index(j, offsetBy: 2)
            let bytes = self[j..<k]
            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            }
        }
        return data
    }

}

extension Data {

    var hexdata: Data {
        return Data(self.hexlify.utf8)
    }

    var hexlify: String {
        let hexDigits = Array("0123456789abcdef".utf16)
        var hexChars = [UTF16.CodeUnit]()
        hexChars.reserveCapacity(count * 2)
        for byte in self {
            let (index1, index2) = Int(byte).quotientAndRemainder(dividingBy: 16)
            hexChars.append(hexDigits[index1])
            hexChars.append(hexDigits[index2])
        }
        return String(utf16CodeUnits: hexChars, count: hexChars.count)
    }

}

extension Int {

    var varint: Data {
        var data = Data()
        var v = UInt64(self)
        while (v > 127) {
            data.append(UInt8(v & 0x7f | 0x80))
            v >>= 7
        }
        data.append(UInt8(v))
        return data
    }

}

public extension CustomStringConvertible {

    var description: String {

        // Use reflection to describe the object and its properties
        let name = String(describing: type(of: self))
        let mirror = Mirror(reflecting: self)
        let properties: [String] = mirror.children.compactMap ({
            guard let name = $0.label else { return nil }
            if let value = $0.value as? Double { return String(format: "%@: %f", name, value) }
            return String(format: "%@: %@", name, String(describing: $0.value))
        })
        return String(format: "%@ [%@]", name, properties.joined(separator: ", "))

    }

}

extension JSON {

    // Handle doubles returned as strings, eg. "199.97207842"
    var doubleString: Double? {
        guard (self.exists()) else { return nil }
        return self.doubleValue
    }

}

extension Date {

    init(millisecondsSince1970: Double) {
        self.init(timeIntervalSince1970: millisecondsSince1970 / 1000)
    }

}

extension String {

    func toDateFromMilliseconds() -> Date? {
        guard let milliSeconds = Double(self) else {
            return nil
        }

        return Date(millisecondsSince1970: milliSeconds)
    }

    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!

        return formatter.date(from: self)
    }

}

extension Parameters {

    var query: String {
        let items: [URLQueryItem] = self.compactMap { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        let url = NSURLComponents()
        url.queryItems = items
        return url.query ?? ""
    }

}
