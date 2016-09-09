//
//  DownloadViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 16.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

class DownloadViewController : UIViewController, UIWebViewDelegate, NSURLConnectionDataDelegate, UITextFieldDelegate {
    
    @IBOutlet var sidebarButton: UIBarButtonItem!
    @IBOutlet var webView: UIWebView!
    @IBOutlet var openInButton: UIBarButtonItem!
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    @IBOutlet var webAdress: UITextField!
    @IBOutlet var reloadPage: UIBarButtonItem!
    
    let defaultAddress = "https://www.google.com" //"http://imslp.org/wiki/Special:ImagefromIndex/388675"       //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add Reveal Menu functionality
        if let revealViewController = self.revealViewController() {
            sidebarButton.target = revealViewController
            sidebarButton.action = #selector(revealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController.panGestureRecognizer())
        }
        
        webAdress.frame = CGRectMake(0, 0, 600, webAdress.frame.height)
        webAdress.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        loadDefaultPage()
        openInButton.enabled = false
    }
    
    /** loads the defaut webpage in the UIWebView */
    func loadDefaultPage(){
        loadPage(defaultAddress)
    }
    
    func loadPage(address: String){
        let validString = turnStringToValidURL(address)
        let url = NSURL(string: validString)
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
    }
    
    func turnStringToValidURL(urlString: String) -> String {
        if !urlString.containsString("http://www.") &&
            !urlString.containsString("https://www.") {
            if urlString.containsString("www.") {
                return "http://" + urlString
            } else {
                return "http://www." + urlString
            }
        } else {
            return urlString
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        if let text = textField.text {
            self.loadPage(text)
        }
        return true
    }
    
    @IBAction func download(){
        
        DataManager.sharedInstance.downloadFileFromURL((self.webView.request?.URL)!)
        
        VFRController.sharedInstance.showPDFInReader(DataManager.sharedInstance.currentFile!.filename)
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