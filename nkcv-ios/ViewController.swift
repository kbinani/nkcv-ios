import UIKit
import WebKit
import Foundation
import SafariServices

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

class URLSchemeHandler : NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        print(#function)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        print(#function)
    }
}

class ViewController: UIViewController {
//    private weak var webView: WKWebView!
//    private weak var webView: UIWebView!
    private let handler: URLSchemeHandler = URLSchemeHandler()
    @IBOutlet weak var containerView: ContainerView!

    private static let kGameURL = URL(string: "http://www.dmm.com/netgame/social/-/gadgets/=/app_id=854854/")!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        SFSafariViewController

        URLProtocol.registerClass(CaptureProtocol.self)
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [CaptureProtocol.self]

//        self.webView.configuration.

//        self.webView.configuration.setURLSchemeHandler(self.handler, forURLScheme: "http")

//        self.webView.configuration.


        let userController = WKUserContentController()
        userController.add(self, name: "callbackHandler")

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userController

//        let webView = UIWebView(frame: .zero)
//        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
//        self.containerView.addSubview(webView)
//        self.webView = webView

//        self.webView.configuration = webConfiguration

//        let request = URLRequest(url: ViewController.kGameURL)
//        self.webView.navigationDelegate = self
//        self.webView.load(request)

//        webView.delegate = self
//        webView.loadRequest(request)

        /*        addChild(toolContainerVC)
         toolHostView.insertSubview(toolContainerVC.view, at: 0)
         toolContainerVC.didMove(toParent: self)
*/
        let vc = SFSafariViewController(url: ViewController.kGameURL)
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.frame = self.view.bounds

        addChild(vc)
        self.view.addSubview(vc.view)
        vc.didMove(toParent: self)
    }

//    override func viewwill
}

extension ViewController : UIWebViewDelegate {

}

extension ViewController : WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        if(message.name == "callbackHandler") {
            print(message.body)
        }
    }

}

extension ViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let script = """
            axios.interceptors.request.use(function (config) {
                // Do something before request is sent
window.webkit.messageHandlers.callbackHandler.postMessage("webViewから呼び出し");
                return config;
            }, function (error) {
                // Do something with request error
                return Promise.reject(error);
            });

            // Add a response interceptor
            axios.interceptors.response.use(function (response) {
                // Do something with response data
window.webkit.messageHandlers.callbackHandler.postMessage("webViewから呼び出し");
               return response;
            }, function (error) {
                // Do something with response error
                return Promise.reject(error);
            });
"""
        webView.evaluateJavaScript(script) { (value, error) in
            print(error)
        }
    }
}


class CaptureProtocol : URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let session: URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        session.dataTask(with: request) { (data, response, error) -> Void in
            if error != nil{
                self.client?.urlProtocol(self, didFailWithError: error!)
                return
            }
            
            // クライアントに渡すところも実装してあげないとリダイレクトをしくじることがある
            self.client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: URLCache.StoragePolicy.allowed)
            self.client?.urlProtocol(self, didLoad: data!)
            self.client?.urlProtocolDidFinishLoading(self)
        }.resume()
    }

    override func stopLoading() {

    }

    func urlSession(session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: (URLRequest?) -> Void) {
        self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)

    }

    func urlSession(session: URLSession, dataTask: URLSessionDataTask, didReceiveData data: Data) {
        self.client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(session: URLSession, dataTask: URLSessionDataTask, didReceiveResponse response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.allowed)
    }

    func urlSession(session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil{
            self.client?.urlProtocol(self, didFailWithError: error!)
        }else{
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
}

extension CaptureProtocol : URLSessionDelegate {
    
}

/*
class CaptureProtocol: URLProtocol, URLSessionDelegate, URLSessionDataDelegate {
    
    
    override class func canInitWithRequest(request: URLRequest) -> Bool {
        // ここでtrueを返した場合、そのリクエストをこのプロトコルで行う
        return CaptureManager.sharedInstance.isNeedCheckRequest(request)
    }
    
    override class func canonicalRequestForRequest (request: URLRequest) -> URLRequest {
        return request;
    }
    
    override func startLoading() {
        
        // リクエストのタスクはこのプロトコルに移るのでここでリクエストを投げる
        let session: URLSession = URLSession(configuration: URLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
        
        session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil{
                self.client?.URLProtocol(self, didFailWithError: error!)
                return
            }
            
            // クライアントに渡すところも実装してあげないとリダイレクトをしくじることがある
            self.client?.URLProtocol(self, didReceiveResponse: response!, cacheStoragePolicy: NSURLCacheStoragePolicy.Allowed)
            self.client?.URLProtocol(self, didLoadData: data!)
            self.client?.URLProtocolDidFinishLoading(self)
        }.resume()
    }
    
    override func stopLoading() {}
    
    
    func urlSession(session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: (URLRequest?) -> Void) {
        
        self.client?.URLProtocol(self, wasRedirectedToRequest: request, redirectResponse: response)
        
    }
    
    
    func URLSession(session: URLSession, dataTask: URLSessionDataTask, didReceiveData data: Data) {
        self.client?.URLProtocol(self, didLoadData: data)
    }
    
    func URLSession(session: URLSession, dataTask: URLSessionDataTask, didReceiveResponse response: URLResponse, completionHandler: (URLSessionResponseDisposition) -> Void) {
        self.client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: NSURLCacheStoragePolicy.Allowed)
    }
    
    func URLSession(session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil{
            self.client?.URLProtocol(self, didFailWithError: error!)
        }else{
            self.client?.URLProtocolDidFinishLoading(self)
        }
    }
}
*/
