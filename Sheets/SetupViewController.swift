//
//  SetupViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 19.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import GTMOAuth2
import QuartzCore

class SetupViewController: UIViewController, FolderSearchDelegate {
    
    var dataManager: DataManager!
    
    var defaultColor: UIColor!
    let filenameInput = UITextField()
    
    var chosenFoldername = ""
    
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataManager = DataManager.sharedInstance
        
        defaultColor = UIColor(red: 32/255.0, green: 50/255.0, blue: 52/255.0, alpha: 1)
        
        showSetupQuestion()
        //showFoldernameInput()
        //showFileImport()
        //showLastSetupScreen()
    }
    
    func showSetupQuestion(){
        
        let questionView = UIView()
        questionView.backgroundColor = UIColor.whiteColor()
        
        let questionLabel = UILabel()
        questionLabel.text = "Setup automatic Google Drive Backup & Syncing?"
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 60)
        questionLabel.textAlignment = .Center
        questionLabel.numberOfLines = 3
        questionLabel.lineBreakMode = .ByWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 250, width, 300)
        
        questionView.addSubview(questionLabel)
        
        
        let yesButton = UIButton(type: .System)
        width = 400
        yesButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 550, width, 300)
        
        yesButton.setTitle("Yes!", forState: .Normal)
        yesButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), forState: .Normal)
        yesButton.titleLabel?.textAlignment = .Center
        yesButton.userInteractionEnabled = true
        yesButton.titleLabel?.font = UIFont(name: "Futura", size: 80)
        yesButton.addTarget(self, action: #selector(setupConfirmButtonClicked(_:)), forControlEvents: .TouchUpInside)
        
        questionView.addSubview(yesButton)
        
        questionView.addSubview(self.createSkipButton())
        
        
        self.view = questionView
    }
    
    func showFoldernameInput(){
        
        let filenameInputView = UIView()
        filenameInputView.backgroundColor = UIColor.whiteColor()
        
        
        let chooseLabel = UILabel()
        var width : CGFloat = 870
        chooseLabel.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 120, width, 300)
        chooseLabel.text = "Choose a foldername"
        chooseLabel.font = UIFont(name: "Futura", size: 70)
        chooseLabel.textColor = defaultColor
        chooseLabel.textAlignment = .Center
        chooseLabel.numberOfLines = 2
        
        filenameInputView.addSubview(chooseLabel)
    
        
        //let filenameInput = UITextField()
        width = 600
        filenameInput.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 450, width, 100)
        
        filenameInput.font = UIFont(name: "Futura", size: 40)
        let spacerView = UIView(frame:CGRect(x:0, y:0, width:10, height:10))
        filenameInput.leftViewMode = .Always
        filenameInput.leftView = spacerView
        filenameInput.layer.cornerRadius = 12.0
        filenameInput.layer.borderWidth = 2.0
        filenameInput.textAlignment = .Center
        filenameInput.text = chosenFoldername
        filenameInput.autocorrectionType = .No
        
        filenameInputView.addSubview(filenameInput)
        
        
        let infoText = UILabel()
        width = 700
        infoText.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 620, width, 450)
        infoText.text = "All of your sheet music will be synced with this Google Drive folder. \nIf you already have a Drive folder with your sheet music, enter its name and your PDF files will automatically be imported."
        infoText.font = UIFont(name: "Futura", size: 40)
        infoText.textColor = defaultColor
        infoText.textAlignment = .Left
        infoText.numberOfLines = 8
        
        filenameInputView.addSubview(infoText)
        
        let confirmButton = UIButton(type: .System)
        width = 400
        confirmButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, CGRectGetHeight(self.view.frame) * 0.76, width, 100)   // old height 850
        
        confirmButton.setTitle("Continue", forState: .Normal)
        confirmButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), forState: .Normal)
        confirmButton.titleLabel?.textAlignment = .Center
        confirmButton.userInteractionEnabled = true
        confirmButton.titleLabel?.font = UIFont(name: "Futura", size: 60)
        confirmButton.addTarget(self, action: #selector(foldernameEntered(_:)), forControlEvents: .TouchUpInside)
        
        filenameInputView.addSubview(confirmButton)
        
        filenameInputView.addSubview(createSkipButton())
        
        self.view = filenameInputView
        
    }
    
    func showFoldernameConfirmation(){
        
        let confirmView = UIView()
        confirmView.backgroundColor = UIColor.whiteColor()
        
        let questionLabel = UILabel()
        questionLabel.text = "Are you sure you want to use this foldername? \n\n\"\(chosenFoldername)\""
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 50)
        questionLabel.textAlignment = .Center
        questionLabel.numberOfLines = 5
        questionLabel.lineBreakMode = .ByWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 250, width, 300)
        
        confirmView.addSubview(questionLabel)
        
        let confirmButton = UIButton(type: .System)
        width = 400
        confirmButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, CGRectGetHeight(self.view.frame) * 0.5, width, 100)   // old height 850
        
        confirmButton.setTitle("Continue", forState: .Normal)
        confirmButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), forState: .Normal)
        confirmButton.titleLabel?.textAlignment = .Center
        confirmButton.userInteractionEnabled = true
        confirmButton.titleLabel?.font = UIFont(name: "Futura", size: 60)
        confirmButton.addTarget(self, action: #selector(foldernameConfirmed(_:)), forControlEvents: .TouchUpInside)
        
        confirmView.addSubview(confirmButton)
        
        let backButton = UIButton(type: .System)
        width = 400
        backButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, CGRectGetHeight(self.view.frame) * 0.6, width, 100)   // old height 850
        
        backButton.setTitle("Back", forState: .Normal)
        backButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), forState: .Normal)
        backButton.titleLabel?.textAlignment = .Center
        backButton.userInteractionEnabled = true
        backButton.titleLabel?.font = UIFont(name: "Futura", size: 50)
        backButton.addTarget(self, action: #selector(backButtonClicked(_:)), forControlEvents: .TouchUpInside)
        
        confirmView.addSubview(backButton)
        
        confirmView.addSubview(createSkipButton())
        
        self.view = confirmView
    }
    
    func showFileImport() {
        print("Folder exists")
        
        let progressView = UIView()
        progressView.backgroundColor = UIColor.whiteColor()
        
        let questionLabel = UILabel()
        questionLabel.text = "Downloading your sheet music"
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 50)
        questionLabel.textAlignment = .Center
        questionLabel.numberOfLines = 5
        questionLabel.lineBreakMode = .ByWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 300, width, 300)
        
        progressView.addSubview(questionLabel)
        
        let progressBar = UIProgressView()
        width = 600
        progressBar.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, CGRectGetHeight(self.view.frame) * 0.5, width, 100)
        progressBar.progressTintColor = defaultColor
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: NSBlockOperation(block: {
        
            //progressBar.progress = Float(self.dataManager.currentDownloadProgress)
            progressBar.progress = Float(self.dataManager.getSyncProgress())
            
            if progressBar.progress >= 0.99 {
                self.timer!.invalidate()
                self.showLastSetupScreen()
            }
            
        }), selector: #selector(NSOperation.main), userInfo: nil, repeats: true)
        
        progressView.addSubview(progressBar)
        
        self.view = progressView
        
    }
    
    func showFolderCreated() {
        
        let createdView = UIView()
        createdView.backgroundColor = UIColor.whiteColor()
        
        let questionLabel = UILabel()
        questionLabel.text = "Folder created! \n\n\"\(chosenFoldername)\""
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 70)
        questionLabel.textAlignment = .Center
        questionLabel.numberOfLines = 5
        questionLabel.lineBreakMode = .ByWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 300, width, 300)
        
        createdView.addSubview(questionLabel)
        
        let confirmButton = UIButton(type: .System)
        width = 400
        confirmButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, CGRectGetHeight(self.view.frame) * 0.5, width, 100)   // old height 850
        
        confirmButton.setTitle("Continue", forState: .Normal)
        confirmButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), forState: .Normal)
        confirmButton.titleLabel?.textAlignment = .Center
        confirmButton.userInteractionEnabled = true
        confirmButton.titleLabel?.font = UIFont(name: "Futura", size: 60)
        confirmButton.addTarget(self, action: #selector(showLastSetupScreen), forControlEvents: .TouchUpInside)
        
        createdView.addSubview(confirmButton)
        
        self.view = createdView
        
    }
    
    func showLastSetupScreen() {
        
        let doneView = UIView()
        doneView.backgroundColor = UIColor.whiteColor()
        
        let questionLabel = UILabel()
        questionLabel.text = "The setup is done!"
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 70)
        questionLabel.textAlignment = .Center
        questionLabel.numberOfLines = 5
        questionLabel.lineBreakMode = .ByWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, 300, width, 300)
        
        doneView.addSubview(questionLabel)
        
        let confirmButton = UIButton(type: .System)
        width = 400
        confirmButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, CGRectGetHeight(self.view.frame) * 0.5, width, 100)   // old height 850
        
        confirmButton.setTitle("Finish", forState: .Normal)
        confirmButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), forState: .Normal)
        confirmButton.titleLabel?.textAlignment = .Center
        confirmButton.userInteractionEnabled = true
        confirmButton.titleLabel?.font = UIFont(name: "Futura", size: 60)
        confirmButton.addTarget(self, action: #selector(endSetup), forControlEvents: .TouchUpInside)
        
        doneView.addSubview(confirmButton)
        
        self.view = doneView
    }
    
    func endSetup(){
        /*
        if presentedViewController != nil {
            dismissViewControllerAnimated(true, completion: nil)
        }*/
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func createSkipButton() -> UIButton {
        
        let skipButton = UIButton(type: .System)
        let width: CGFloat = 400
        skipButton.frame = CGRectMake((CGRectGetWidth(self.view.frame) - width) / 2, CGRectGetHeight(self.view.frame) * 0.85, width, 100)   // old height 850
        
        skipButton.setTitle("setup later", forState: .Normal)
        skipButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 0.5), forState: .Normal)
        skipButton.titleLabel?.textAlignment = .Center
        skipButton.userInteractionEnabled = true
        skipButton.titleLabel?.font = UIFont(name: "Futura", size: 40)
        skipButton.addTarget(self, action: #selector(skipButtonClicked(_:)), forControlEvents: .TouchUpInside)
        
        return skipButton
    }
    
    
    @IBAction func skipButtonClicked(sender: AnyObject){
        
        // Disable Google Drive Sync
        dataManager.disableSync()
        
        self.endSetup()
    }
    
    
    @IBAction func setupConfirmButtonClicked(sender: AnyObject) {
        
        checkConnection({ () in
            self.showGoogleAuthentication()
        })
    }
    
    @IBAction func foldernameEntered(sender: AnyObject) {
        chosenFoldername = filenameInput.text!
        
        if chosenFoldername == "" {
            showAlert("Empty foldername", message: "Please enter a name for your Google Drive folder. (Or skip the setup)")
        } else {
            showFoldernameConfirmation()
        }
    }
    
    @IBAction func foldernameConfirmed(sender: AnyObject) {
        
        checkConnection({() in
            self.dataManager.searchForFolder(self, foldername: self.chosenFoldername)
        })
        
        
    }
    
    /** 
        If a wifi connection exists the function passed as a parameter is executed. 
        If not, an alert is presented to the user saying there is not wifi connection.
    */
    func checkConnection(ifConnected: () -> Void) {
        if Reachability.isConnectedToNetwork() {
            ifConnected()
        } else {
            showAlert("No wifi connection.", message: "Please connect to wifi to continue with the setup. Or set up Google Drive sync later in the settings.")
        }
    }
    
    func folderSearchFinished(found: Bool) {
        // Check if a folder with the specified name exists
        // If yes, import all of the files
        // If not, create the folder and store its information
        
        if found {
            //dataManager.fetchFilesInFolder()
            dataManager.startSync()
            showFileImport()
        } else {
            dataManager.createSheetFolder(chosenFoldername)
            showFolderCreated()
        }
    }
    
    @IBAction func backButtonClicked(sender: AnyObject) {
        showFoldernameInput()
    }
    
    /**  
        Shows the Google Drive authentication ViewController where the user logs in with his Google
        account and authenticates
    */
    func showGoogleAuthentication(){
        presentViewController(
            createAuthController(),
            animated: true,
            completion: nil
        )
    }
    
    
    /** Creates the auth controller for authorizing access to Drive API */
    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = dataManager.scopes.joinWithSeparator(" ")
        let authController = GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: dataManager.kClientID,
            clientSecret: nil,
            keychainItemName: dataManager.kKeychainItemName,
            delegate: self,
            finishedSelector: #selector(self.finishAuthentication(_:finishedWithAuth:error:))
        )
        
        authController.view.addSubview(createSkipButton())
        
        return authController
    }
    
    /**
     Handle completion of the authorization process, and update the Drive API
     with the new credentials.
     */
    @objc func finishAuthentication(vc : UIViewController,
                                    finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
        
        if let error = error {
            dataManager.service.authorizer = nil
            print("Authentication Error: \(error.localizedDescription)")
            showAlert("Authentication Error", message: "Could not authenticate the Google account. Please try again later.")
            //self.skipButtonClicked(self)
        } else {
        
            dataManager.service.authorizer = authResult
            dismissViewControllerAnimated(true, completion: nil)
            self.showFoldernameInput()
        }
    }
    
    /** Helper for showing an alert */
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

}