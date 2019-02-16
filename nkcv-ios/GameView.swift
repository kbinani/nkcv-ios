import Foundation
import WebKit


protocol GameViewDelegate : AnyObject {
    func gameViewDidReceive(api: String, parameter: String, response: String)
}


class GameView : UIView {
    weak var delegate: GameViewDelegate? = nil

    private var gameContentURL: URL? = nil
    private var gameContentLoadRequested: Bool = false
    private var webView: WKWebView?
    private let subscriber = NotificationCenterSubscriber()

    private let kGameURL = URL(string: "http://www.dmm.com/netgame/social/-/gadgets/=/app_id=854854/")!
    private let kDefaultSize = CGSize(width: 1200, height: 720)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.autoresizesSubviews = false

        let userController = WKUserContentController()
        userController.add(self, name: "onGameApiResponse")
        userController.add(self, name: "debug")

        if let sourceFileURL = Bundle.main.url(forResource: "user-script", withExtension: "js"), let source = try? String(contentsOf: sourceFileURL) {
            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            userController.addUserScript(script)
        }

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userController

        let webView = WKWebView(frame: frame, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false

        self.addSubview(webView)
        self.webView = webView

        let request = URLRequest(url: kGameURL)
        webView.load(request)

        subscribe()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribe()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scale = kDefaultSize.scaleAspectFit(within: self.bounds.size)
        webView?.transform = CGAffineTransform(scaleX: scale, y: scale)
        let size = kDefaultSize.aspectFit(within: self.bounds.size)
        webView?.frame = CGRect(origin: .zero, size: size)
    }

    private func subscribe() {
        subscriber.subscribe(for: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] (subscriber, note) in
            runOnMain {
                self?.detachWebView()
            }
        }
        subscriber.subscribe(for: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] (subscriber, note) in
            runOnMain {
                self?.attachWebView()
            }
        }
    }

    private func unsubscribe() {
        subscriber.unsubscribeAll()
    }

    private func attachWebView() {
        guard let webView = self.webView else {
            return
        }
        self.callUserScript(function: "unmute")
        webView.isHidden = false;
    }

    private func detachWebView() {
        guard let webView = self.webView else {
            return
        }
        self.callUserScript(function: "mute")
        webView.isHidden = true
    }

    fileprivate func callUserScript(function: String, args: String = "") {
        let code = """
        (() => {
            if (typeof window.nkcv.\(function) == 'undefined') {
                return;
            }
            window.nkcv.\(function)(\(args));
        })();
        """
        webView?.evaluateJavaScript(code, completionHandler: { (_, error) in
            if let error = error {
                print(error)
            }
        })
    }
}


extension CGSize {
    func scaleAspectFit(within size: CGSize) -> CGFloat {
        return min(size.width / self.width, size.height / self.height)
    }

    func aspectFit(within size: CGSize) -> CGSize {
        let scale = self.scaleAspectFit(within: size)
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
}


extension GameView : WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "onGameApiResponse":
            guard let body = message.body as? [String: Any] else {
                return
            }
            guard let api = body["url"] as? String, let response = body["response"] as? String, let request = body["request"] as? String else {
                return
            }
            self.delegate?.gameViewDidReceive(api: api, parameter: request, response: response)
        case "debug":
            print(message.body)
        default:
            break
        }
    }
}


extension GameView : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.gameContentLoadRequested {
            self.callUserScript(function: "injectApiHook")
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


class NotificationCenterSubscriber {
    private var observers: [NSObjectProtocol] = []

    func subscribe(for name: Notification.Name, object: Any?, queue: OperationQueue?, using block: @escaping (NotificationCenterSubscriber, Notification) -> Void) {
        let observer = NotificationCenter.default.addObserver(forName: name, object: object, queue: queue) { [weak self] (note) in
            guard let self = self else {
                return
            }
            block(self, note)
        }
        runOnMain { [weak self] in
            guard let self = self else {
                return
            }
            self.observers.append(observer)
        }
    }

    func unsubscribeAll() {
        runOnMain { [weak self] in
            self?.unsubscribe()
        }
    }

    deinit {
        self.unsubscribe()
    }

    private func unsubscribe() {
        self.observers.reversed().forEach { (it) in
            NotificationCenter.default.removeObserver(it)
        }
        self.observers.removeAll()
    }
}


func runOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}
