import UIKit

class ReceiveController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Receive"

        let addressLabel = UILabel()

        view.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(24)
        }

        addressLabel.numberOfLines = 0
        addressLabel.textAlignment = .center
        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.text = Manager.shared.binanceChainKit.account

        let copyButton = UIButton()

        view.addSubview(copyButton)
        copyButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(addressLabel.snp.bottom).offset(24)
        }

        copyButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        copyButton.setTitleColor(.systemBlue, for: .normal)
        copyButton.setTitleColor(.lightGray, for: .disabled)
        copyButton.setTitle("Copy", for: .normal)
        copyButton.addTarget(self, action: #selector(copyToClipboard), for: .touchUpInside)
    }

    @objc private func copyToClipboard() {
        UIPasteboard.general.string = Manager.shared.binanceChainKit.account
        print(Manager.shared.binanceChainKit!.account)

        let alert = UIAlertController(title: "Success", message: "Address copied", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

}
