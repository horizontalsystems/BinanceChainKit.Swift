import UIKit
import RxSwift
import SnapKit

class MoveToBscController: UIViewController {
    private let disposeBag = DisposeBag()

    private let amountTextField = UITextField()
    private let coinLabel = UILabel()
    private let button = UIButton(type: .system)

    private let adapter = Manager.shared.binanceAdapters.first

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Move to BSC chain"

        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        view.addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(200)
            maker.leading.equalToSuperview().inset(20)
            maker.width.equalTo(70)
            maker.height.equalTo(30)
        }
        coinLabel.text = adapter?.coin

        view.addSubview(amountTextField)
        amountTextField.snp.makeConstraints { maker in
            maker.top.equalTo(coinLabel.snp.top)
            maker.leading.equalTo(coinLabel.snp.trailing).offset(20)
            maker.trailing.equalToSuperview().inset(20)
            maker.height.equalTo(30)
        }
        amountTextField.borderStyle = .line
        amountTextField.keyboardType = .decimalPad

        view.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.top.equalTo(coinLabel.snp.bottom).offset(100)
            maker.leading.trailing.equalToSuperview().inset(50)
            maker.height.equalTo(50)
        }

        button.setTitle("MOVE", for: .normal)
        button.addTarget(self, action: #selector(onTapMove), for: .touchUpInside)
        button.isEnabled = true
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func onTapMove() {
        guard let adapter = adapter else {
            return
        }

        guard let amountString = amountTextField.text, let amount = Decimal(string: amountString, locale: .current) else {
            return
        }

        adapter.moveToBSC(symbol: adapter.coin, amount: amount)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] address in
                    let alert = UIAlertController(title: "Success", message: "\(amount.description) sent to \(address)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self?.present(alert, animated: true)
                    self?.view.endEditing(true)
                }, onError: { [weak self] error in
                    let alert = UIAlertController(title: "Send Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self?.present(alert, animated: true)
                    self?.view.endEditing(true)
                })
                .disposed(by: disposeBag)
    }

}
