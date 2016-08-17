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
    
    @IBOutlet var output: UITextView!
    @IBOutlet var webView: UIWebView?
    @IBOutlet var tableView: UITableView!
    
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
        titleView.text = "Hello World"
        titleView.font = UIFont(name: "Futura-Medium", size: 20)
        let width = titleView.sizeThatFits(CGSizeMake(CGFloat.max, CGFloat.max)).width
        titleView.frame = CGRect(origin:CGPointZero, size:CGSizeMake(width, 500))
        titleView.userInteractionEnabled = true
        self.navigationItem.titleView = titleView
        navTitleView = titleView
        
        // Setup Output view
        output.frame = view.bounds
        output.editable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 400, right: 0)
        output.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        
        view.addSubview(output);
        
        
        //add filter Gesture recognizer
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(showFilterView))
        recognizer.delegate = self
        titleView.addGestureRecognizer(recognizer)
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(
            kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
                service.authorizer = auth
        }
        
    }
    
    // When the view appears, ensure that the Drive API service is authorized
    // and perform API calls
    override func viewDidAppear(animated: Bool) {
        
        //self.navigationController!.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 80.0)
        
        if shouldShowFilterOptions {
            showFilterView()
        }
        
        if let authorizer = service.authorizer,
            canAuth = authorizer.canAuthorize where canAuth {
                generalSetup()
        } else {
            presentViewController(
                createAuthController(),
                animated: true,
                completion: nil
            )
        }
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
        let filePath = NSURL(fileURLWithPath: applicationDocumentDirectory()).URLByAppendingPathComponent(filename).path
        let readerDocument = ReaderDocument(filePath: filePath!, password: "")
        let readerViewController = ReaderViewController(readerDocument: readerDocument)
        
        if let readerDoc = readerDocument {
            presentViewController(readerViewController, animated: true, completion: nil)
            readerViewController.delegate = self
        }else {
            print("Reader document could not be created!")
        }
        
        
        
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
        
        renameView.file = currentFile
        
        /*
        renameView.modalPresentationStyle = .Popover
        renameView.modalTransitionStyle = .CoverVertical
        renameView.popoverPresentationController?.sourceView = viewController.view
        renameView.popoverPresentationController?.sourceRect = popoverRect
        */
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
    /*
    func dismissReaderViewController(readerVC: SheetReaderViewController){
        readerVC.dismissViewControllerAnimated(true, completion: nil)
    }*/
    
    func generalSetup(){
        files = [File]()
        tableView.delegate = self
        tableView.dataSource = self
        
        //check if first time launch
        if (userDefaults.valueForKey("firstTime") == nil) {
            userDefaults.setBool(false, forKey: "firstTime")
            setupSheetFolder()
        }else{
            self.mainFolderName = userDefaults.valueForKey("mainFolderName") as? String
            self.searchForFolder(self.mainFolderName)
            
            //deleteDocumentsDirectory()
            //resetMetaDataFile()
            setupFiles()
            //fetchAllFiles()
            //fetchFilesInFolder()
            listAllLocalFiles()
            printMetaDataFile()
        }
        tableView.reloadData()
    }
    
    /** (dummy sync) loads all files in the google drive folder */
    @IBAction func sync(){
        fetchFilesInFolder()
    }
    
    //sets up all of the files
    //includes loading from Documents directory and 
    //syncing with Google drive (not implemented yet)
    func setupFiles(){
        loadLocalFiles()
        
        //print("Number of Files: \(files.count)")
    }
    
    func loadLocalFiles(){
        /*// Get the document directory url
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
         */
        
        //create File objects from Metadata file
        let mFilePath = NSURL(fileURLWithPath: applicationDocumentDirectory()).URLByAppendingPathComponent(metadataFileName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(mFilePath.path!) {
            do {
                let fileContent = try String(contentsOfFile: mFilePath.path!, encoding: NSUTF8StringEncoding)
                
                let lines = fileContent.componentsSeparatedByString("\n")
                for line in lines {
                    if line != "" {
                        let file = File(data: line)
                        files.append(file)
                    }
                }
                
            } catch {
                print("Error! Could not read from metadata file")
            }
        }
    }
    
    //Setup SheetFolder (Create if not existing)
    func setupSheetFolder(wrongInput: Bool = false){
        //prompt user to input folder name
        var message = "Please choose a folder name for your sheet music\n (Sheets will only operate in this folder)"
        if wrongInput {
            message = "Invalid Input!\n" + message
        }
        
        let alert = UIAlertController(
            title: "Folder name",
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        
        let alertAction = UIAlertAction(
            title: "Choose",
            style: UIAlertActionStyle.Default,
            handler: {(action: UIAlertAction) in
                
                self.mainFolderName = alert.textFields![0].text!
                
                if self.mainFolderName == "" {
                    self.setupSheetFolder(true)
                }else{
                    //save folder name in user Preferences
                    self.userDefaults.setValue(self.mainFolderName, forKey: "mainFolderName")
                    
                    //search for the folder and if it doesn't exist create it
                    self.searchForFolder(self.mainFolderName)
                }
            })
        alert.addAction(alertAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func searchForFolder(foldername: String, toGetID: Bool = false){
        
        service.shouldFetchNextPages = true
        
        var sel = #selector(MainViewController.checkFolderSearchQuery(_:finishedWithObject:error:))
        if toGetID {
           sel = #selector(MainViewController.checkFolderSearchQueryForID(_:finishedWithObject:error:))
        }
        
        let query = GTLQueryDrive.queryForFilesList()
        query.q = "name = \'\(foldername)\'"
        
        service.executeQuery(
            query,
            delegate: self,
            didFinishSelector: sel)
    }
    
    func checkFolderSearchQuery(ticket : GTLServiceTicket,
        finishedWithObject response : GTLDriveFileList,
        error : NSError?){
            
            if let error = error {
                showAlert("Error", message: error.localizedDescription)
                return
            }
            
            if let files = response.files where !files.isEmpty {
                //folder was found
            } else {
                createSheetFolder(mainFolderName!)
                //searchForFolder(mainFolderName)
                output.text = "No files found."
            }
            
    }
    
    func checkFolderSearchQueryForID(ticket : GTLServiceTicket,
        finishedWithObject response : GTLDriveFileList,
        error : NSError?){
            
            if let error = error {
                showAlert("Error", message: error.localizedDescription)
                return
            }
            
            if let files = response.files where !files.isEmpty {
                //folder was found -> save folder iD
                let file = files[0] as! GTLDriveFile
                self.mainFolderID = file.identifier
                self.userDefaults.setValue(mainFolderID!, forKey: "mainFolderID")
            }
            fetchFilesInFolder()
            
    }
    
    func getFolderID(){
        searchForFolder(mainFolderName,toGetID: true)
    }
    
    
    //Create an empty folder
    func createSheetFolder(filename: String) {
        
        let folder = GTLDriveFile()
        folder.name = filename
        folder.mimeType = "application/vnd.google-apps.folder"
        
        let query = GTLQueryDrive.queryForFilesCreateWithObject(folder, uploadParameters: nil)
        service.executeQuery(
            query,
            delegate: self,
            didFinishSelector: #selector(MainViewController.displayFinishedCreatingFolder(_:updatedFile:error:))
        )
    }
    
    func displayFinishedCreatingFolder(ticket: GTLServiceTicket,
        updatedFile file:GTLDriveFile,
        error: NSError?){
            
            if let error = error {
                showAlert("Error", message: error.localizedDescription)
                return
            }
            output.text = "Finished creating Folder!"
    }
    
    // Construct a query to get names and IDs of 10 files using the Google Drive API
    func fetchAllFiles() {
        output.text = "Getting files..."
        let query = GTLQueryDrive.queryForFilesList()
        query.pageSize = 15
        query.fields = "nextPageToken, files(id, name)"
        service.executeQuery(
            query,
            delegate: self,
            didFinishSelector: #selector(MainViewController.finishedFetchingAllFiles(_:finishedWithObject:error:))
        )
    }
    
    func finishedFetchingAllFiles(ticket: GTLServiceTicket,
        finishedWithObject response: GTLDriveFileList,
        error: NSError?){
            
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
            
        displayFiles(response.files)
    }
    
    //Fetches all PDF files in the main Folder
    func fetchFilesInFolder(){
        output.text = "Getting sheets"
        let query = GTLQueryDrive.queryForFilesList()
        if let folderID = mainFolderID {
            query.q = "\'\(folderID)\' in parents and (mimeType = \'application/pdf\')"
            service.executeQuery(
                query,
                delegate: self,
                didFinishSelector: #selector(MainViewController.finishedFetchingFilesInFolder(_:finishedWithObject:error:))
            )
        }else{
            getFolderID()
        }
    }
    
    func finishedFetchingFilesInFolder(ticket: GTLServiceTicket,
        finishedWithObject response: GTLDriveFileList,
        error: NSError?){
            
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        
        displayFiles(response.files)
        for file in response.files {
            downloadFile(file as! GTLDriveFile)
        }
    }
    
    // Parse results and display
    func displayResultWithTicket(ticket : GTLServiceTicket,
        finishedWithObject response : GTLDriveFileList,
        error : NSError?) {
            
            if let error = error {
                showAlert("Error", message: error.localizedDescription)
                return
            }
            
            var filesString = ""
            
            if let files = response.files where !files.isEmpty {
                filesString += "Files:\n"
                for file in files as! [GTLDriveFile] {
                    filesString += "\(file.name)\n" // (\(file.identifier))\n"
                }
            } else {
                filesString = "No files found."
            }
            
            output.text = filesString
    }
    
    func displayFiles(files: [AnyObject]?){
        var filesString = ""
        
        if let files = files where !files.isEmpty {
            filesString += "Files:\n"
            for file in files as! [GTLDriveFile] {
                filesString += "\(file.name)\n" // (\(file.identifier))\n"
            }
        } else {
            filesString = "No files found."
        }
        
        output.text = filesString
    }
    
    func downloadAndDisplayFile(url: NSURL){
        let fileData = NSData(contentsOfURL: url)
        let filename = url.lastPathComponent!
        currentFile = saveFileToDocumentsDirectory(fileData!, filename: filename)
        showPDFInReader(filename)
    }
    
    func downloadFile(file: GTLDriveFile){
        output.text = "Downloading"
        let url = "https://www.googleapis.com/drive/v3/files/\(file.identifier)?alt=media"
        
        let fetcher = service.fetcherService.fetcherWithURLString(url)
        
        fetcher.beginFetchWithDelegate(
            self,
            didFinishSelector: #selector(MainViewController.finishedFileDownload(_:finishedWithData:error:)))
        
    }
    
    func finishedFileDownload(fetcher: GTMSessionFetcher, finishedWithData data: NSData, error: NSError?){
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        
        let filename = "Rach.pdf"
        
        saveFileToDocumentsDirectory(data,filename: filename)
        
        showPDFInReader(filename)
        
        output.text = "Finished Download"
    }
    
    func saveFileToDocumentsDirectory(data: NSData,filename: String) -> File{
        let writePath = NSURL(fileURLWithPath: applicationDocumentDirectory()).URLByAppendingPathComponent(filename)
        
        let file = createFileObject(writePath, title: filename)
        data.writeToFile(file.url.path!, atomically: true)
        tableView.reloadData()
        
        return file
    }
    
    func createFileObject(url: NSURL, title: String) -> File {
        // let file = File(url: url, title: title, dict: nil)
        let file = File(url: url)
        
        //append file data to metadata file and file list
        //first check to see if it already exists or not
        let dataString = file.getFileName()
        
        for document in files {
            if document.getFileName() == dataString {
                print("File already exists in metadata")
                return document
            }
        }
        
        updateMetadataFile(file)
        files.append(file)
        return file
    }
    
    //appends the data of file to Metadata file
    func updateMetadataFile(file: File){
        let metadataFileUrl = NSURL(fileURLWithPath: applicationDocumentDirectory()).URLByAppendingPathComponent(metadataFileName)
        
        let dataAsString = file.getDataAsString()
        let data = dataAsString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        if NSFileManager.defaultManager().fileExistsAtPath(metadataFileUrl.path!) {
            do {
                let fileHandle = try NSFileHandle(forWritingToURL: metadataFileUrl)
                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }catch{
                print("Can't open fileHandler")
            }
        }else{
            //File doesn't exist
            do{
                try data.writeToURL(metadataFileUrl, options: .DataWritingAtomic)
            }catch{
                print("Couldn't create and write to file")
            }
            
        }
    }
    
    func resetMetaDataFile(){
        let metadataFileUrl = NSURL(fileURLWithPath: applicationDocumentDirectory()).URLByAppendingPathComponent(metadataFileName)
        
        do {
            try "".writeToURL(metadataFileUrl, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            print("Couldn't reset metadata file")
        }
        
    }
    
    func printMetaDataFile(){
        let mFilePath = NSURL(fileURLWithPath: applicationDocumentDirectory()).URLByAppendingPathComponent(metadataFileName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(mFilePath.path!) {
            do {
                let fileContent = try String(contentsOfFile: mFilePath.path!, encoding: NSUTF8StringEncoding)
                
                let lines = fileContent.componentsSeparatedByString("\n")
                for line in lines {
                    print(line)
                }
                
            } catch {
                print("Error! Could not read from metadata file")
            }
        } else {
            print("Metadata file does not exist.")
        }
    }
    
    func listAllLocalFiles(){
        var fileString = ""
        // Get the document directory url
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL( documentsUrl, includingPropertiesForKeys: nil, options: [])
            
            // filter out pdf files
            let files = directoryContents.filter{ $0.pathExtension == "pdf" }
            let fileNames = files.flatMap({$0.URLByDeletingPathExtension?.lastPathComponent})
            
            for filename in fileNames {
                fileString += filename + "\n"
            }
            
            output.text = fileString
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func displayPDFInWebView(filePath: String){
        //let webView = UIWebView(frame: CGRectMake(10,10,200,200))
        let url = NSURL(fileURLWithPath: filePath)
        let requestObj = NSURLRequest(URL: url)
        
        self.webView!.userInteractionEnabled = true
        self.webView!.delegate = self
        webView!.loadRequest(requestObj)
        
        self.view.addSubview(webView!)
    }
    
    //TableView Delegate and DataSource functions
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //number of cells
        return files.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.text = files[indexPath.row].getFileName()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // cell selected code here
        let file = files[indexPath.row]
        currentFile = file
        showPDFInReader(file.getFileName())
    }
    
    
    // Creates the auth controller for authorizing access to Drive API
    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joinWithSeparator(" ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: #selector(MainViewController.viewController(_:finishedWithAuth:error:))
        )
    }
    
    // Handle completion of the authorization process, and update the Drive API
    // with the new credentials.
    func viewController(vc : UIViewController,
        finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
            
            if let error = error {
                service.authorizer = nil
                showAlert("Authentication Error", message: error.localizedDescription)
                return
            }
            
            service.authorizer = authResult
            dismissViewControllerAnimated(true, completion: nil)
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
    
    func applicationDocumentDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    }
    
    //deletes all of the content of the Document Directory
    func deleteDocumentsDirectory(){
        let fileManager = NSFileManager.defaultManager()
        let directoryURL = NSURL(fileURLWithPath: applicationDocumentDirectory())
        let enumerator = fileManager.enumeratorAtPath(applicationDocumentDirectory())
        while let file = enumerator?.nextObject() as? String {
            do {
                try fileManager.removeItemAtURL(directoryURL.URLByAppendingPathComponent(file))
            } catch {
                print("Could not remove \(file)")
            }
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController{
        return self
    }
    
}

