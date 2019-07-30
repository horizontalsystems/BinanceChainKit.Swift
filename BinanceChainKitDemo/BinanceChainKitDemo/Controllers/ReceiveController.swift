import UIKit

class ReceiveController: UIViewController {

    @IBOutlet weak var accountLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Receive"

        accountLabel?.layer.cornerRadius = 8
        accountLabel?.clipsToBounds = true

        accountLabel?.text = "  \(Manager.shared.binanceChainKit!.account)  "
    }

    @IBAction func copyToClipboard() {
        UIPasteboard.general.setValue(Manager.shared.binanceChainKit!.account, forPasteboardType: "public.plain-text")

        let alert = UIAlertController(title: "Success", message: "Account copied", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

}
