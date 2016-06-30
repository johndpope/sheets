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

class ViewController: UIViewController,UIAlertViewDelegate,UIWebViewDelegate {
    
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
    
    // When the view loads, create necessary subviews
    // and initialize the Drive API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.frame = view.bounds
        output.editable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 400, right: 0)
        output.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        
        view.addSubview(output);
        
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
        if let authorizer = service.authorizer,
            canAuth = authorizer.canAuthorize where canAuth {
                generalSetup()
                //fetchFiles()
        } else {
            presentViewController(
                createAuthController(),
                animated: true,
                completion: nil
            )
        }
    }
    
    //Check if specific folder exists
    func folderWithNameExists(foldername: String) -> Bool {
        return true
    }
    
    func generalSetup(){
        //check if first time launch
        if (userDefaults.valueForKey("firstTime") == nil) {
            userDefaults.setBool(false, forKey: "firstTime")
            setupSheetFolder()
        }else{
            self.mainFolderName = userDefaults.valueForKey("mainFolderName") as? String
            self.searchForFolder(self.mainFolderName)
            //fetchAllFiles()
            fetchFilesInFolder()
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
        
        var sel = Selector("checkFolderSearchQuery:finishedWithObject:error:")
        if toGetID {
           sel = Selector("checkFolderSearchQueryForID:finishedWithObject:error:")
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
            didFinishSelector: "displayFinishedCreatingFolder:updatedFile:error:"
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
            didFinishSelector: "finishedFetchingAllFiles:finishedWithObject:error:"
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
                didFinishSelector: "finishedFetchingFilesInFolder:finishedWithObject:error:"
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
    
    func downloadFile(file: GTLDriveFile){
        output.text = "Downloading"
        let url = "https://www.googleapis.com/drive/v3/files/\(file.identifier)?alt=media"
        
        let fetcher = service.fetcherService.fetcherWithURLString(url)
        
        fetcher.beginFetchWithDelegate(
            self,
            didFinishSelector: "finishedFileDownload:finishedWithData:error:")
        
    }
    
    func finishedFileDownload(fetcher: GTMSessionFetcher, finishedWithData data: NSData, error: NSError?){
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        
        saveFileToDocumentsDirectory(data)
        
        output.text = "Finished Download"
    }
    
    func saveFileToDocumentsDirectory(data: NSData){
        let writePath = NSURL(fileURLWithPath: applicationDocumentDirectory()).URLByAppendingPathComponent("Rach.pdf")
        data.writeToFile(writePath.path!, atomically: true)
        
        displayPDFInWebView(writePath.path!)
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
    
    
    // Creates the auth controller for authorizing access to Drive API
    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joinWithSeparator(" ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: "viewController:finishedWithAuth:error:"
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

