import Foundation
import Alamofire

public class BinanceError: Error {

    public var code: Int
    public var message: String
    public var httpStatus: Int? = nil

    required init(code: Int, message: String, httpStatus: Int?) {
        self.code = code
        self.message = message
        self.httpStatus = httpStatus
    }

}

extension BinanceError: LocalizedError {
    public var errorDescription: String? {
        var str = "(\(code)"

        if let status = httpStatus {
            str += "|HTTP STATUS:\(status)"
        }

        return str + " \(message)"
    }
}