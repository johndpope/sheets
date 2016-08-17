//
//  DownloadViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 16.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

class DownloadViewController : UIViewController, UIWebViewDelegate, NSURLConnectionDataDelegate {
    
    @IBOutlet var sidebarButton: UIBarButtonItem!
    @IBOutlet var webView: UIWebView!
    @IBOutlet var openInButton: UIBarButtonItem!
    
    let defaultAddress = "http://imslp.org/wiki/Special:ImagefromIndex/388675"       //"https://www.google.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add Reveal Menu functionality
        if let revealViewController = self.revealViewController() {
            sidebarButton.target = revealViewController
            sidebarButton.action = #selector(revealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController.panGestureRecognizer())
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        loadDefaultPage()
        openInButton.enabled = false
    }
    
    /** loads the defaut webpage in the UIWebView */
    func loadDefaultPage(){
        let url = NSURL(string: defaultAddress)
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
    }
    
    @IBAction func download(){
        let mainViewController = MainViewController()
        mainViewController.downloadAndDisplayFile((webView.request?.URL)!)
    }
    
    /**
     Checks if the UIWebView is currently displaying a pdf file
    */
    func isPDFDisplayedInView() -> Bool {
        return self.webView.request?.URL?.pathExtension?.lowercaseString == "pdf"
    }
    
    /** enables the DownloadButton if a pdf file is being displayed */
    func webViewDidFinishLoad(webView: UIWebView) {
        if isPDFDisplayedInView() {
            //activate the Open In Button
            openInButton.enabled = true
        } else {
            openInButton.enabled = false
        }
    }
    
}