import UIKit
import WebKit
import Foundation

@IBDesignable
class ContainerView : UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let view = self.subviews.first else {
            return
        }
        view.frame = CGRect(origin: .zero, size: self.bounds.size)
    }
}


class ViewController: UIViewController {
    private weak var webView: WKWebView!
    @IBOutlet weak var containerView: ContainerView!
    private var gameContentURL: URL? = nil {
        didSet {
            print(gameContentURL)
        }
    }
    private var gameContentLoadRequested: Bool = false

    private static let kGameURL = URL(string: "http://www.dmm.com/netgame/social/-/gadgets/=/app_id=854854/")!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userController = WKUserContentController()
        userController.add(self, name: "callbackHandler")

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userController

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.containerView.addSubview(webView)
        self.webView = webView

        let request = URLRequest(url: ViewController.kGameURL)
        self.webView.navigationDelegate = self
        self.webView.load(request)
    }
}


extension ViewController : WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "callbackHandler" else {
            return
        }
        guard let body = message.body as? [String: Any] else {
            return
        }
        guard let api = body["url"] as? String, let response = body["response"] as? String, let request = body["request"] as? String else {
            return
        }
        print(api, request)
    }
}


extension ViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.gameContentLoadRequested {
            let script = """
            axios.interceptors.response.use(function (response) {
                const data = {
                    url: response.config.url,
                    response: response.data,
                    request: response.config.data
                };
                window.webkit.messageHandlers.callbackHandler.postMessage(data);
                return response;
            }, function (error) {
                return Promise.reject(error);
            });
            """
            webView.evaluateJavaScript(script) { (value, error) in
                print(error)
            }
        } else {
            guard let gameContentURL = self.gameContentURL else {
                return
            }
            let request = URLRequest(url: gameContentURL)
            webView.load(request)
            self.gameContentLoadRequested = true
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)

        guard self.gameContentURL == nil else {
            return
        }
        guard let url = navigationAction.request.url else {
            return
        }
        let urlString = url.absoluteString
        if urlString.contains("/kcs2/") && urlString.contains("api_root") && urlString.contains("voice_root") && urlString.contains("api_starttime") {
            self.gameContentURL = url
        }
    }
}
