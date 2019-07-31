import UIKit
import RxSwift

class SendController: UIViewController {
    private let disposeBag = DisposeBag()

    @IBOutlet weak var addressTextField: UITextField?
    @IBOutlet weak var amountTextField: UITextField?
    @IBOutlet weak var memoTextField: UITextField?
    @IBOutlet weak var coinLabel: UILabel?

    private let adapters = Manager.shared.binanceAdapters
    private let segmentedControl = UISegmentedControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        for (index, adapter) in adapters.enumerated() {
            segmentedControl.insertSegment(withTitle: adapter.coin, at: index, animated: false)
        }

        segmentedControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)

        navigationItem.titleView = segmentedControl

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.sendActions(for: .valueChanged)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc func onSegmentChanged() {
        coinLabel?.text = currentAdapter.coin
    }

    @IBAction func send() {
        guard let address = addressTextField?.text?.trimmingCharacters(in: .whitespaces) else {
            return
        }

        do {
            try currentAdapter.validate(address: address)
        } catch {
            show(error: "Invalid address")
            return
        }

        guard let amountString = amountTextField?.text, let amount = Decimal(string: amountString) else {
            show(error: "Invalid amount")
            return
        }

        let memo = memoTextField?.text ?? ""

        currentAdapter.sendSingle(to: address, amount: amount, memo: memo)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] _ in
                    self?.addressTextField?.text = ""
                    self?.amountTextField?.text = ""
                    self?.memoTextField?.text = ""

                    self?.showSuccess(address: address, amount: amount)
                }, onError: { [weak self] error in
                    self?.show(error: "Send failed: \(error)")
                })
                .disposed(by: disposeBag)
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

    private var currentAdapter: BinanceChainAdapter {
        return adapters[segmentedControl.selectedSegmentIndex]
    }

}
