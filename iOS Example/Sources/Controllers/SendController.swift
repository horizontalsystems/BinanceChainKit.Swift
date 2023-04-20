import UIKit
import SnapKit
import BinanceChainKit
import HsExtensions

class SendController: UIViewController {
    private let adapter: BinanceChainAdapter = Manager.shared.adapter
    private var tasks = Set<AnyTask>()

    private let addressTextField = UITextField()
    private let amountTextField = UITextField()
    private let memoTextField = UITextField()
    private let sendButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Send"

        let addressLabel = UILabel()

        view.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.textColor = .gray
        addressLabel.text = "Address:"

        let addressTextFieldWrapper = UIView()

        view.addSubview(addressTextFieldWrapper)
        addressTextFieldWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(addressLabel.snp.bottom).offset(8)
        }

        addressTextFieldWrapper.layer.borderWidth = 1
        addressTextFieldWrapper.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        addressTextFieldWrapper.layer.cornerRadius = 8

        addressTextFieldWrapper.addSubview(addressTextField)
        addressTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        addressTextField.font = .systemFont(ofSize: 13)

        let amountLabel = UILabel()

        view.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(addressTextFieldWrapper.snp.bottom).offset(24)
        }

        amountLabel.font = .systemFont(ofSize: 14)
        amountLabel.textColor = .gray
        amountLabel.text = "Amount:"

        let amountTextFieldWrapper = UIView()

        view.addSubview(amountTextFieldWrapper)
        amountTextFieldWrapper.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(amountLabel.snp.bottom).offset(8)
        }

        amountTextFieldWrapper.layer.borderWidth = 1
        amountTextFieldWrapper.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        amountTextFieldWrapper.layer.cornerRadius = 8

        amountTextFieldWrapper.addSubview(amountTextField)
        amountTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        amountTextField.font = .systemFont(ofSize: 13)

        let ethLabel = UILabel()

        view.addSubview(ethLabel)
        ethLabel.snp.makeConstraints { make in
            make.leading.equalTo(amountTextFieldWrapper.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(amountTextFieldWrapper)
        }

        ethLabel.font = .systemFont(ofSize: 13)
        ethLabel.textColor = .black
        ethLabel.text = "ETH"

        let memoLabel = UILabel()

        view.addSubview(memoLabel)
        memoLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(amountTextFieldWrapper.snp.bottom).offset(24)
        }

        memoLabel.font = .systemFont(ofSize: 14)
        memoLabel.textColor = .gray
        memoLabel.text = "Memo:"

        let memoTextFieldWrapper = UIView()

        view.addSubview(memoTextFieldWrapper)
        memoTextFieldWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(memoLabel.snp.bottom).offset(8)
        }

        memoTextFieldWrapper.layer.borderWidth = 1
        memoTextFieldWrapper.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        memoTextFieldWrapper.layer.cornerRadius = 8

        memoTextFieldWrapper.addSubview(memoTextField)
        memoTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        memoTextField.font = .systemFont(ofSize: 13)

        view.addSubview(sendButton)
        sendButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(memoTextFieldWrapper.snp.bottom).offset(24)
        }

        sendButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        sendButton.setTitleColor(.systemBlue, for: .normal)
        sendButton.setTitleColor(.lightGray, for: .disabled)
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc private func send() {
        present(UINavigationController(rootViewController: MoveToBscController()), animated: true)
//        guard let address = addressTextField.text?.trimmingCharacters(in: .whitespaces) else {
//            return
//        }
//
//        do {
//            try adapter.validate(address: address)
//        } catch {
//            show(error: "Invalid address")
//            return
//        }
//
//        guard let amountString = amountTextField.text, let amount = Decimal(string: amountString, locale: .current) else {
//            show(error: "Invalid amount")
//            return
//        }
//
//        let memo = memoTextField.text ?? ""

//        adapter.sendSingle(to: address, amount: amount, memo: memo)
//                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
//                .observeOn(MainScheduler.instance)
//                .subscribe(onSuccess: { [weak self] _ in
//                    self?.addressTextField.text = ""
//                    self?.amountTextField.text = ""
//                    self?.memoTextField.text = ""
//
//                    self?.showSuccess(address: address, amount: amount)
//                }, onError: { [weak self] error in
//                    self?.show(error: "Send failed: \(error)")
//                })
//                .disposed(by: disposeBag)
    }

    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showSuccess(address: String, amount: Decimal) {
        let alert = UIAlertController(title: "Success", message: "\(amount.description) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

}
