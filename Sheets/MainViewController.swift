//
//  ViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 27.06.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import GoogleAPIClient
import GTMOAuth2
import UIKit
import Foundation
import vfrReader

class MainViewController: UIViewController, UIAlertViewDelegate, UIWebViewDelegate, ReaderViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate ,
    UIGestureRecognizerDelegate {
    
    private let metadataFileName = "Metadata.txt"
    
    private let kKeychainItemName = "Drive API"
    private let kClientID = "451075181287-raoeoh0i74mq51vqv9tk6dhgi9qs26q7.apps.googleusercontent.com"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLAuthScopeDrive]
    
    private let service = GTLServiceDrive()
    
    private var mainFolderName: String!
    private var mainFolderID: String?
    let userDefaults = NSUserDefaults()
    
    var tableView: UITableView!
    
    //UINavigationItems
    @IBOutlet var sidebarButton: UIBarButtonItem!
    @IBOutlet var syncButton: UIBarButtonItem!
    @IBOutlet var searchButton: UIBarButtonItem!
    
    var searchBar: UISearchBar?
    var navTitle: String!
    var navTitleView: UIView!
    
    //segue variable
    var shouldShowFilterOptions = false
    
    var files: [File]!
    var currentFile: File!
    
    var dataManager = DataManager.sharedInstance
    
    // When the view loads, create necessary subviews
    // and initialize the Drive API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add Reveal Menu functionality
        if let revealViewController = self.revealViewController() {
            sidebarButton.target = revealViewController
            sidebarButton.action = #selector(revealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController.panGestureRecognizer())
        }
        
        // Setup Navigation Bar Title Label
        let titleView = UILabel()
        titleView.text = "All"
        titleView.font = UIFont(name: "Futura-Medium", size: 20)
        let width = titleView.sizeThatFits(CGSizeMake(CGFloat.max, CGFloat.max)).width
        titleView.frame = CGRect(origin:CGPointZero, size:CGSizeMake(width, 500))
        titleView.userInteractionEnabled = true
        self.navigationItem.titleView = titleView
        navTitleView = titleView
        
        
        //add filter Gesture recognizer
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(showFilterView))
        recognizer.delegate = self
        titleView.addGestureRecognizer(recognizer)
        
    }
    
    // When the view appears, ensure that the Drive API service is authorized
    // and perform API calls
    override func viewDidAppear(animated: Bool) {
        
        //self.navigationController!.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 80.0)
        
        if shouldShowFilterOptions {
            showFilterView()
        }
        
        if let authorizer = dataManager.service.authorizer,
            canAuth = authorizer.canAuthorize where canAuth {
            
            //dataManager.sync()
        }
        
        generalSetup()
    }
    
    func generalSetup(){
        
        //files = [File]()
        let offset : CGFloat = 50
        let navHeight = (self.navigationController?.navigationBar.frame.height)! + offset
        let height = CGRectGetHeight(self.view.frame) - navHeight
        tableView = UITableView(frame: CGRectMake(0, navHeight, UIScreen.mainScreen().bounds.width, height ),
                                style: .Plain)
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.addSubview(tableView)
        
        //check if first time launch
        if (userDefaults.valueForKey("firstTime") == nil) {
            userDefaults.setBool(false, forKey: "firstTime")
            //setupSheetFolder()
            setupGoogleDriveSync()
        }else{
            
            //listAllLocalFiles()
            //printMetaDataFile()
        }
        dataManager.loadLocalFiles()
        tableView.reloadData()
        
    }
    
    func setupGoogleDriveSync(){
        presentViewController(SetupViewController(), animated: true, completion: nil)
    }
    
    @IBAction func searchButtonPressed(sender: AnyObject){
        showSearchBar()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        hideSearchBar()
    }
    
    func showSearchBar(){
        
        navTitle = navigationItem.title
        navTitleView = navigationItem.titleView
        navigationItem.titleView = searchBar
        navigationItem.setLeftBarButtonItem(nil, animated: true)
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(searchBarCancelButtonClicked(_:)))
        navigationItem.setRightBarButtonItems([cancelButton], animated: true)
        
        UIView.animateWithDuration(0.2, animations: {
            self.searchBar = UISearchBar()
            self.searchBar!.delegate = self
            self.searchBar!.alpha = 1
            self.navigationItem.titleView = self.searchBar
            
            }, completion: { finished in
                //self.searchBar.becomeFirstResponder()
                
        })
    }
    
    func hideSearchBar(){
        
        self.searchBar!.alpha = 0
        UIView.animateWithDuration(0.2, animations: {
                //self.searchBar.alpha = 0
            
            }, completion: { finished in
                self.navigationItem.titleView = self.navTitleView
                
        })
        navigationItem.setLeftBarButtonItem(sidebarButton, animated: true)
        navigationItem.setRightBarButtonItems([searchButton,syncButton], animated: true)
    }
    
    func showPDFInReader(filename: String){
        VFRController.sharedInstance.showPDFInReader(filename)
        
    }
    
    // ReaderViewControllerDelegate methods
    
    func dismissReaderViewController(viewController: ReaderViewController!) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showRenameView(viewController: ReaderViewController!, nameLabel: UILabel, document: ReaderDocument) {
        print("show Rename View")
        
        let popoverY = nameLabel.frame.origin.y + 40
        let popoverRect = CGRectMake(CGRectGetMidX(viewController.view.bounds), popoverY,0,0)
        
        let renameView = self.storyboard?.instantiateViewControllerWithIdentifier("RenameVC") as! RenameViewController
        let nav = UINavigationController(rootViewController: renameView)
        
        renameView.file = dataManager.currentFile
        
        nav.modalPresentationStyle = .Popover
        let popover = nav.popoverPresentationController
        popover?.sourceView = viewController.view
        popover?.sourceRect = popoverRect
        
        viewController.presentViewController(nav, animated: true, completion: nil)
    }
    
    func showFilterView(){
        print("show Filter")
        
        let popoverY = self.navTitleView.frame.origin.y + 300
        let popoverRect = CGRectMake(CGRectGetMidX(self.view.bounds), popoverY, 0, 0)
        
        let filterView = self.storyboard?.instantiateViewControllerWithIdentifier("FilterVC") as! FilterViewController
        
        let nav = UINavigationController(rootViewController: filterView)
        nav.modalPresentationStyle = .Popover
        let popover = nav.popoverPresentationController
        popover?.sourceView = self.view
        popover?.sourceRect = popoverRect
        
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    
    /** Calls the Sync function of the dataManager */
    @IBAction func sync(){
        //dataManager.fetchFilesInFolder()
        dataManager.startSync()
    }
    
    func downloadAndDisplayFile(url: NSURL){
        let fileData = NSData(contentsOfURL: url)!
        let filename = url.lastPathComponent!
    
        dataManager.currentFile = dataManager.saveFileToDocumentsDirectory(fileData, filename: filename)
        //tableView.reloadData()
        showPDFInReader(filename)
        
    }
    
    func listAllLocalFiles(){
        let fileNames = dataManager.listAllLocalFiles()
        print("Filenames: " + fileNames)
    }
    
    //TableView Delegate and DataSource functions
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //number of cells
        return dataManager.files.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.text = dataManager.files[indexPath.row].filename
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // cell selected code here
        let file = dataManager.files[indexPath.row]
        dataManager.currentFile = file
        showPDFInReader(file.filename)
    }
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.Default,
            handler: nil
        )
        alert.addAction(ok)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController{
        return self
    }
    
}

