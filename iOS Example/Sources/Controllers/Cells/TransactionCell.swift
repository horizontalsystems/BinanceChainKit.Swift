import Foundation
import UIKit
import SnapKit

class TransactionCell: UITableViewCell {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, HH:mm:ss")
        return formatter
    }()

    private let titlesLabel = UILabel()
    private let valuesLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(titlesLabel)
        titlesLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(24)
        }

        titlesLabel.numberOfLines = 0
        titlesLabel.font = .systemFont(ofSize: 12)
        titlesLabel.textColor = .gray

        contentView.addSubview(valuesLabel)
        valuesLabel.snp.makeConstraints { make in
            make.top.equalTo(titlesLabel)
            make.trailing.equalToSuperview().inset(16)
        }

        valuesLabel.numberOfLines = 0
        valuesLabel.font = .systemFont(ofSize: 12)
        valuesLabel.textColor = .black
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(transaction: TransactionRecord, coin: String, lastBlockHeight: Int?) {
        var confirmations = "n/a"

        if let lastBlockHeight = lastBlockHeight {
            confirmations = "\(lastBlockHeight - transaction.blockNumber + 1)"
        }

        titlesLabel.set(string: """
                                Tx Id:
                                Block number:
                                Date:
                                Amount:
                                From:
                                To:
                                Fee:
                                Memo:
                    """, alignment: .left)

        valuesLabel.set(string: """
                                \(shorten(string: transaction.hash))
                                \(String(describing: transaction.blockNumber))
                                \(TransactionCell.dateFormatter.string(from: transaction.date))
                                \(transaction.amount) \(transaction.symbol)
                                \(transaction.from.address)\(transaction.from.mine ? ": mine" : "")
                                \(transaction.to.address)\(transaction.to.mine ? ": mine" : "")
                                \(transaction.fee)
                                \(transaction.memo.map { shorten(string: $0) } ?? "nil")
                    """, alignment: .right)
    }

    private func shorten(string: String) -> String {
        guard string.count > 22 else {
            return string
        }

        return "\(string[..<string.index(string.startIndex, offsetBy: 10)])...\(string[string.index(string.endIndex, offsetBy: -10)...])"
    }

}
