//
//  SetupViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 19.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import GTMOAuth2
import GTMAppAuth
import AppAuth
import QuartzCore

class SetupViewController: UIViewController, FolderSearchDelegate {
    
    var dataManager: DataManager!
    
    var defaultColor: UIColor!
    let filenameInput = UITextField()
    
    var chosenFoldername = ""
    
    var timer: Timer?
    
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
        questionView.backgroundColor = UIColor.white
        
        let questionLabel = UILabel()
        questionLabel.text = "Setup automatic Google Drive Backup & Syncing?"
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 60)
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 3
        questionLabel.lineBreakMode = .byWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRect(x: (self.view.frame.width - width) / 2, y: 250, width: width, height: 300)
        
        questionView.addSubview(questionLabel)
        
        
        let yesButton = UIButton(type: .system)
        width = 400
        yesButton.frame = CGRect(x: (self.view.frame.width - width) / 2, y: 550, width: width, height: 300)
        
        yesButton.setTitle("Yes!", for: UIControlState())
        yesButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), for: UIControlState())
        yesButton.titleLabel?.textAlignment = .center
        yesButton.isUserInteractionEnabled = true
        yesButton.titleLabel?.font = UIFont(name: "Futura", size: 80)
        yesButton.addTarget(self, action: #selector(setupConfirmButtonClicked(_:)), for: .touchUpInside)
        
        questionView.addSubview(yesButton)
        
        questionView.addSubview(self.createSkipButton())
        
        
        self.view = questionView
    }
    
    func showFoldernameInput(){
        
        let filenameInputView = UIView()
        filenameInputView.backgroundColor = UIColor.white
        
        
        let chooseLabel = UILabel()
        var width : CGFloat = 870
        chooseLabel.frame = CGRect(x: (self.view.frame.width - width) / 2, y: 120, width: width, height: 300)
        chooseLabel.text = "Choose a foldername"
        chooseLabel.font = UIFont(name: "Futura", size: 70)
        chooseLabel.textColor = defaultColor
        chooseLabel.textAlignment = .center
        chooseLabel.numberOfLines = 2
        
        filenameInputView.addSubview(chooseLabel)
    
        
        //let filenameInput = UITextField()
        width = 600
        filenameInput.frame = CGRect(x: (self.view.frame.width - width) / 2, y: 450, width: width, height: 100)
        
        filenameInput.font = UIFont(name: "Futura", size: 40)
        let spacerView = UIView(frame:CGRect(x:0, y:0, width:10, height:10))
        filenameInput.leftViewMode = .always
        filenameInput.leftView = spacerView
        filenameInput.layer.cornerRadius = 12.0
        filenameInput.layer.borderWidth = 2.0
        filenameInput.textAlignment = .center
        filenameInput.text = chosenFoldername
        filenameInput.autocorrectionType = .no
        
        filenameInputView.addSubview(filenameInput)
        
        
        let infoText = UILabel()
        width = 700
        infoText.frame = CGRect(x: (self.view.frame.width - width) / 2, y: self.view.frame.height * 0.6, width: width, height: 150)
        infoText.text = "All of your sheet music will be synced with this Google Drive folder. \nIf you already have a Drive folder with your sheet music, enter its name and your PDF files will automatically be imported."
        infoText.font = UIFont(name: "Futura", size: 20)
        infoText.textColor = defaultColor
        infoText.textAlignment = .left
        infoText.numberOfLines = 8
        
        filenameInputView.addSubview(infoText)
        
        let confirmButton = UIButton(type: .system)
        width = 400
        confirmButton.frame = CGRect(x: (self.view.frame.width - width) / 2, y: self.view.frame.height * 0.76, width: width, height: 100)   // old height 850
        
        confirmButton.setTitle("Continue", for: UIControlState())
        confirmButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), for: UIControlState())
        confirmButton.titleLabel?.textAlignment = .center
        confirmButton.isUserInteractionEnabled = true
        confirmButton.titleLabel?.font = UIFont(name: "Futura", size: 60)
        confirmButton.addTarget(self, action: #selector(foldernameEntered(_:)), for: .touchUpInside)
        
        filenameInputView.addSubview(confirmButton)
        
        filenameInputView.addSubview(createSkipButton())
        
        self.view = filenameInputView
        
    }
    
    func showFoldernameConfirmation(){
        
        let confirmView = UIView()
        confirmView.backgroundColor = UIColor.white
        
        let questionLabel = UILabel()
        questionLabel.text = "Are you sure you want to use this foldername? \n\n\"\(chosenFoldername)\""
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 50)
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 5
        questionLabel.lineBreakMode = .byWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRect(x: (self.view.frame.width - width) / 2, y: 250, width: width, height: 300)
        
        confirmView.addSubview(questionLabel)
        
        let confirmButton = UIButton(type: .system)
        width = 400
        confirmButton.frame = CGRect(x: (self.view.frame.width - width) / 2, y: self.view.frame.height * 0.6, width: width, height: 100)   // old height 850
        
        confirmButton.setTitle("Continue", for: UIControlState())
        confirmButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), for: UIControlState())
        confirmButton.titleLabel?.textAlignment = .center
        confirmButton.isUserInteractionEnabled = true
        confirmButton.titleLabel?.font = UIFont(name: "Futura", size: 60)
        confirmButton.addTarget(self, action: #selector(foldernameConfirmed(_:)), for: .touchUpInside)
        
        confirmView.addSubview(confirmButton)
        
        let backButton = UIButton(type: .system)
        width = 400
        backButton.frame = CGRect(x: (self.view.frame.width - width) / 2, y: self.view.frame.height * 0.7, width: width, height: 100)   // old height 850
        
        backButton.setTitle("Back", for: UIControlState())
        backButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), for: UIControlState())
        backButton.titleLabel?.textAlignment = .center
        backButton.isUserInteractionEnabled = true
        backButton.titleLabel?.font = UIFont(name: "Futura", size: 50)
        backButton.addTarget(self, action: #selector(backButtonClicked(_:)), for: .touchUpInside)
        
        confirmView.addSubview(backButton)
        
        confirmView.addSubview(createSkipButton())
        
        self.view = confirmView
    }
    
    func showFileImport() {
        print("Folder exists")
        
        let progressView = UIView()
        progressView.backgroundColor = UIColor.white
        
        let questionLabel = UILabel()
        questionLabel.text = "Downloading your sheet music"
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 50)
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 5
        questionLabel.lineBreakMode = .byWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRect(x: (self.view.frame.width - width) / 2, y: 300, width: width, height: 300)
        
        progressView.addSubview(questionLabel)
        
        let progressBar = UIProgressView()
        width = 600
        progressBar.frame = CGRect(x: (self.view.frame.width - width) / 2, y: self.view.frame.height * 0.5, width: width, height: 100)
        progressBar.progressTintColor = defaultColor
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.05, target: BlockOperation(block: {
        
            //progressBar.progress = Float(self.dataManager.currentDownloadProgress)
            progressBar.progress = Float(self.dataManager.getSyncProgress())
            
            if progressBar.progress >= 0.99 {
                self.timer!.invalidate()
                self.showLastSetupScreen()
            }
            
        }), selector: #selector(Operation.main), userInfo: nil, repeats: true)
        
        progressView.addSubview(progressBar)
        
        self.view = progressView
        
    }
    
    func showFolderCreated() {
        
        let createdView = UIView()
        createdView.backgroundColor = UIColor.white
        
        let questionLabel = UILabel()
        questionLabel.text = "Folder created! \n\n\"\(chosenFoldername)\""
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 70)
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 5
        questionLabel.lineBreakMode = .byWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRect(x: (self.view.frame.width - width) / 2, y: 300, width: width, height: 300)
        
        createdView.addSubview(questionLabel)
        
        let confirmButton = UIButton(type: .system)
        width = 400
        confirmButton.frame = CGRect(x: (self.view.frame.width - width) / 2, y: self.view.frame.height * 0.5, width: width, height: 100)   // old height 850
        
        confirmButton.setTitle("Continue", for: UIControlState())
        confirmButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), for: UIControlState())
        confirmButton.titleLabel?.textAlignment = .center
        confirmButton.isUserInteractionEnabled = true
        confirmButton.titleLabel?.font = UIFont(name: "Futura", size: 60)
        confirmButton.addTarget(self, action: #selector(showLastSetupScreen), for: .touchUpInside)
        
        createdView.addSubview(confirmButton)
        
        self.view = createdView
        
    }
    
    func showLastSetupScreen() {
        
        let doneView = UIView()
        doneView.backgroundColor = UIColor.white
        
        let questionLabel = UILabel()
        questionLabel.text = "The setup is done!"
        questionLabel.textColor = defaultColor
        questionLabel.font = UIFont(name: "Futura", size: 70)
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 5
        questionLabel.lineBreakMode = .byWordWrapping
        var width : CGFloat = 580
        questionLabel.frame = CGRect(x: (self.view.frame.width - width) / 2, y: 300, width: width, height: 300)
        
        doneView.addSubview(questionLabel)
        
        let confirmButton = UIButton(type: .system)
        width = 400
        confirmButton.frame = CGRect(x: (self.view.frame.width - width) / 2, y: self.view.frame.height * 0.5, width: width, height: 100)   // old height 850
        
        confirmButton.setTitle("Finish", for: UIControlState())
        confirmButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1), for: UIControlState())
        confirmButton.titleLabel?.textAlignment = .center
        confirmButton.isUserInteractionEnabled = true
        confirmButton.titleLabel?.font = UIFont(name: "Futura", size: 60)
        confirmButton.addTarget(self, action: #selector(endSetup), for: .touchUpInside)
        
        doneView.addSubview(confirmButton)
        
        self.view = doneView
        
    }
    
    func endSetup(){
        /*
        if presentedViewController != nil {
            dismissViewControllerAnimated(true, completion: nil)
        }*/
        self.presentingViewController!.dismiss(animated: true, completion: nil)
        
    }
    
    func createSkipButton() -> UIButton {
        
        let skipButton = UIButton(type: .system)
        let width: CGFloat = 400
        skipButton.frame = CGRect(x: (self.view.frame.width - width) / 2, y: self.view.frame.height * 0.85, width: width, height: 100)   // old height 850
        
        skipButton.setTitle("setup later", for: UIControlState())
        skipButton.setTitleColor(UIColor(red: 49/255.0, green: 117/255.0, blue: 131/255.0, alpha: 0.5), for: UIControlState())
        skipButton.titleLabel?.textAlignment = .center
        skipButton.isUserInteractionEnabled = true
        skipButton.titleLabel?.font = UIFont(name: "Futura", size: 40)
        skipButton.addTarget(self, action: #selector(skipButtonClicked(_:)), for: .touchUpInside)
        
        return skipButton
    }
    
    
    @IBAction func skipButtonClicked(_ sender: AnyObject){
        
        // Disable Google Drive Sync
        dataManager.disableSync()
        
        self.endSetup()
    }
    
    
    @IBAction func setupConfirmButtonClicked(_ sender: AnyObject) {
        
        checkConnection({ () in
            self.showGoogleAuthentication()
        })
    }
    
    @IBAction func foldernameEntered(_ sender: AnyObject) {
        chosenFoldername = filenameInput.text!
        
        if chosenFoldername == "" {
            showAlert("Empty foldername", message: "Please enter a name for your Google Drive folder. (Or skip the setup)")
        } else {
            showFoldernameConfirmation()
        }
    }
    
    @IBAction func foldernameConfirmed(_ sender: AnyObject) {
        
        checkConnection({() in
            self.dataManager.searchForFolder(self, foldername: self.chosenFoldername)
        })
        
        
    }
    
    /** 
        If a wifi connection exists the function passed as a parameter is executed. 
        If not, an alert is presented to the user saying there is not wifi connection.
    */
    func checkConnection(_ ifConnected: () -> Void) {
        if Reachability.isConnectedToNetwork() {
            ifConnected()
        } else {
            showAlert("No wifi connection.", message: "Please connect to wifi to continue with the setup. Or set up Google Drive sync later in the settings.")
        }
    }
    
    func folderSearchFinished(_ found: Bool) {
        // Check if a folder with the specified name exists
        // If yes, import all of the files
        // If not, create the folder and store its information
        
        if found {
            //dataManager.fetchFilesInFolder()
            dataManager.syncEnabled = true
            dataManager.startSync()
            //showFileImport()
            showLastSetupScreen()
        } else {
            dataManager.createSheetFolder(chosenFoldername)
            showFolderCreated()
        }
    }
    
    @IBAction func backButtonClicked(_ sender: AnyObject) {
        showFoldernameInput()
    }
    
    /**  
        Shows the Google Drive authentication ViewController where the user logs in with his Google
        account and authenticates
    */
    func showGoogleAuthentication(){
        
        authenticateWithGoogle()
        print("Authentication finished")
        
        /*
        present(
            createAuthController(),
            animated: true,
            completion: nil
        )*/
    }
    
    
    /** Creates the auth controller for authorizing access to Drive API */
    fileprivate func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = dataManager.scopes.joined(separator: " ")
        let authController = GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: dataManager.kClientID,
            clientSecret: nil,
            keychainItemName: dataManager.kKeychainItemName,
            delegate: self,
            finishedSelector: #selector(self.finishAuthentication(_:finishedWithAuth:error:))
        )
        
        authController?.view.addSubview(createSkipButton())
        
        return authController!
    }
    
    fileprivate func authenticateWithGoogle() {
        
        let request = OIDAuthorizationRequest(
            configuration: dataManager.configuration,
            clientId: dataManager.kClientID,
            clientSecret: nil,
            scopes: dataManager.scopes,
            redirectURL: dataManager.redirectURI,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentAuthorizationFlow =
            OIDAuthState.authState(byPresenting: request, presenting: self,
            callback: {(authState: OIDAuthState?,error: Error?) in
                
                if let authState = authState, authState.isAuthorized {
                    
                    let authorization = GTMAppAuthFetcherAuthorization(authState: authState)
                    self.dataManager.authorization = authorization
                    self.dataManager.service.fetcherService.authorizer = authorization
                    self.dataManager.service.authorizer = authorization
                    
                    // save the authorization
                    GTMAppAuthFetcherAuthorization.save(authorization, toKeychainForName: self.dataManager.kNewKeychainItemName)
                    
                    print("Got authorization tokens. Access token: \(authState.lastTokenResponse?.accessToken ?? "nil")")
                    
                    // continue with the setup
                    self.showFoldernameInput()
                } else {
                    print("Authorization error: \(error?.localizedDescription ?? "")")
                    self.dataManager.authorization = nil
                    
                    // skip the setup
                    self.dataManager.disableSync()
                    self.endSetup()
                }
        })
        
    }
    
    /**
     Handle completion of the authorization process, and update the Drive API
     with the new credentials.
     */
    @objc func finishAuthentication(_ vc : UIViewController,
                                    finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
        
        if let error = error {
            dataManager.service.authorizer = nil
            print("Authentication Error: \(error.localizedDescription)")
            showAlert("Authentication Error", message: "Could not authenticate the Google account. Please try again later.")
            //self.skipButtonClicked(self)
        } else {
            print("Authentication succeeded: \(authResult.canAuthorize)")
            dataManager.service.authorizer = authResult
            dismiss(animated: true, completion: nil)
            self.showFoldernameInput()
        }
    }
    
    /** Helper for showing an alert */
    func showAlert(_ title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

}
