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
        
        webAdress.frame = CGRect(x: 0, y: 0, width: 600, height: webAdress.frame.height)
        webAdress.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadDefaultPage()
        openInButton.isEnabled = false
    }
    
    /** loads the defaut webpage in the UIWebView */
    func loadDefaultPage(){
        loadPage(defaultAddress)
    }
    
    func loadPage(_ address: String){
        let validString = turnStringToValidURL(address)
        let url = URL(string: validString)
        let request = URLRequest(url: url!)
        webView.loadRequest(request)
    }
    
    func turnStringToValidURL(_ urlString: String) -> String {
        if !urlString.contains("http://www.") &&
            !urlString.contains("https://www.") {
            if urlString.contains("www.") {
                return "http://" + urlString
            } else {
                return "http://www." + urlString
            }
        } else {
            return urlString
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        if let text = textField.text {
            self.loadPage(text)
        }
        return true
    }
    
    @IBAction func download(){
        
        DataManager.sharedInstance.downloadFileFromURL((self.webView.request?.url)!)
        
        VFRController.sharedInstance.showPDFInReader(DataManager.sharedInstance.currentFile!)
    }
    
    /**
     Checks if the UIWebView is currently displaying a pdf file
    */
    func isPDFDisplayedInView() -> Bool {
        return (self.webView.request as NSURLRequest?)?.url?.pathExtension.lowercased() == "pdf"
    }
    
    /** enables the DownloadButton if a pdf file is being displayed */
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if isPDFDisplayedInView() {
            //activate the Open In Button
            openInButton.isEnabled = true
        } else {
            openInButton.isEnabled = false
        }
    }
    
}
