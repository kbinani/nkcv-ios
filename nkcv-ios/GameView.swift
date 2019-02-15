import Foundation
import WebKit


class GameView : UIView {
    private var gameContentURL: URL? = nil
    private var gameContentLoadRequested: Bool = false
    private weak var webView: WKWebView!

    private static let kGameURL = URL(string: "http://www.dmm.com/netgame/social/-/gadgets/=/app_id=854854/")!

    override init(frame: CGRect) {
        super.init(frame: frame)

        let userController = WKUserContentController()
        userController.add(self, name: "callbackHandler")

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userController

        let webView = WKWebView(frame: frame, configuration: webConfiguration)
        webView.navigationDelegate = self

        self.addSubview(webView)
        self.webView = webView

        let request = URLRequest(url: GameView.kGameURL)
        webView.load(request)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.webView.frame = CGRect(origin: .zero, size: self.bounds.size)
    }
}


extension GameView : WKScriptMessageHandler {
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


extension GameView : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.gameContentLoadRequested {
            let script = """
            axios.interceptors.response.use((response) => {
                const data = {
                    url: response.config.url,
                    response: response.data,
                    request: response.config.data
                };
                window.webkit.messageHandlers.callbackHandler.postMessage(data);
                return response;
            }, (error) => {
                return Promise.reject(error);
            });
            """
            webView.evaluateJavaScript(script) { (value, error) in
                if let error = error {
                    print(error)
                }
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
        guard self.gameContentURL == nil else {
            decisionHandler(.allow)
            return
        }
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString
        if urlString.contains("/kcs2/") && urlString.contains("api_root") && urlString.contains("voice_root") && urlString.contains("api_starttime") {
            self.gameContentURL = url
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
