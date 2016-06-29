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

class ViewController: UIViewController,UIAlertViewDelegate {
    
    private let kKeychainItemName = "Drive API"
    private let kClientID = "451075181287-raoeoh0i74mq51vqv9tk6dhgi9qs26q7.apps.googleusercontent.com"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLAuthScopeDrive]
    
    private let service = GTLServiceDrive()
    
    private var mainFolderName: String!
    let userDefaults = NSUserDefaults()
    let output = UITextView()
    
    // When the view loads, create necessary subviews
    // and initialize the Drive API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.frame = view.bounds
        output.editable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
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
            fetchFiles()
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
                    self.searchForFolder(self.mainFolderName!)
                }
            })
        alert.addAction(alertAction)
        
        presentViewController(alert, animated: true, completion: nil)
        
        
    }
    
    func searchForFolder(foldername: String){
        service.shouldFetchNextPages = true
        
        let query = GTLQueryDrive.queryForFilesList()
        query.q = "name = \'\(foldername)\'"
        service.executeQuery(
            query,
            delegate: self,
            didFinishSelector: "checkFolderSearchQuery:finishedWithObject:error:")
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
                output.text = "No files found."
            }
            
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
    func fetchFiles() {
        output.text = "Getting files..."
        let query = GTLQueryDrive.queryForFilesList()
        query.pageSize = 15
        query.fields = "nextPageToken, files(id, name)"
        service.executeQuery(
            query,
            delegate: self,
            didFinishSelector: "displayResultWithTicket:finishedWithObject:error:"
        )
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
                    filesString += "\(file.name)\n" //(\(file.identifier))\n"
                }
            } else {
                filesString = "No files found."
            }
            
            output.text = filesString
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

