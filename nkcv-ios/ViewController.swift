import UIKit
import Foundation


class ViewController: UIViewController {
    private weak var webView: GameView!
    @IBOutlet weak var containerView: ContainerView!

    override func viewDidLoad() {
        super.viewDidLoad()


        let webView = GameView(frame: .zero)
        self.containerView.addSubview(webView)
        self.webView = webView
    }
}
