import UIKit
import BinanceChainKit
import HdWalletKit

class LoginController: UIViewController {

    @IBOutlet weak var textView: UITextView?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "BinanceChainKit Demo"

        textView?.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView?.layer.cornerRadius = 8

        textView?.text = Configuration.shared.defaultWords
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @IBAction func generateNewWords() {
        if let generatedWords = try? Mnemonic.generate(strength: .veryHigh) {
            textView?.text = generatedWords.joined(separator: " ")
        }
    }

    @IBAction func login() {
        let words = textView?.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty } ?? []

        do {
            try Mnemonic.validate(words: words, strength: .veryHigh)

            try Manager.shared.login(words: words)

            if let window = UIApplication.shared.keyWindow {
                UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = MainController()
                })
            }
        } catch {
            let alert = UIAlertController(title: "Validation Error", message: "\(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
    }

}
