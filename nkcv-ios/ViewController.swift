import UIKit
import WebKit

class ViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!

    private static let kGameURL = URL(string: "http://www.dmm.com/netgame/social/-/gadgets/=/app_id=854854/")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.navigationDelegate = self
        
        let request = URLRequest(url: ViewController.kGameURL)
        self.webView.load(request)
    }
}


extension ViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(#function, error)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#function)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print(#function)
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print(#function)
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print(#function)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(#function, error)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print(#function)
        completionHandler(.performDefaultHandling, nil)
    }
}
