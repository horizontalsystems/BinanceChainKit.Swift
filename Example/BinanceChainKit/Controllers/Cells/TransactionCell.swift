import UIKit
import BinanceChainKit

class TransactionCell: UITableViewCell {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, HH:mm:ss")
        return formatter
    }()

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var valueLabel: UILabel?

    func bind(transaction: TransactionRecord, coin: String) {
        set(string: """
                    Tx Id:
                    Block number:
                    Date:
                    Amount:
                    From:
                    To:
                    Fee:
                    Memo:
                    """, alignment: .left, label: titleLabel)

        set(string: """
                    \(shorten(string: transaction.hash))
                    \(String(describing: transaction.blockNumber))
                    \(TransactionCell.dateFormatter.string(from: transaction.date))
                    \(transaction.amount) \(transaction.symbol)
                    \(transaction.from.address)\(transaction.from.mine ? ": mine" : "")
                    \(transaction.to.address)\(transaction.to.mine ? ": mine" : "")
                    \(transaction.fee)
                    \(transaction.memo.map { shorten(string: $0) } ?? "nil")
                    """, alignment: .right, label: valueLabel)
    }

    private func set(string: String, alignment: NSTextAlignment, label: UILabel?) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = alignment

        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))

        label?.attributedText = attributedString
    }

    private func shorten(string: String) -> String {
        guard string.count > 22 else {
            return string
        }

        return "\(string[..<string.index(string.startIndex, offsetBy: 10)])...\(string[string.index(string.endIndex, offsetBy: -10)...])"
    }

}
