//
//  WebViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 3/25/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    lazy var webView: WKWebView = {
        $0.navigationDelegate = self
        $0.center = view.center
        view.addSubview($0)
        return $0
    }(WKWebView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height), configuration: WKWebViewConfiguration()))
    
    lazy var spinner: UIActivityIndicatorView = {
        $0.center = view.center
        $0.hidesWhenStopped = true
        $0.color = UIColor.ReachMeColor()
        view.addSubview($0)
        return $0
    }(UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge))
    
    var urlString: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webURL = URL(string: urlString)
        let webRequest = URLRequest(url: webURL!)
        webView.load(webRequest)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        spinner.startAnimating()
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        spinner.stopAnimating()
    }
}
