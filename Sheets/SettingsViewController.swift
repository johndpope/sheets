//
//  SettingsViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 13.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

class SettingsViewController : UIViewController {
    
    @IBOutlet var sidebarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add Reveal Menu functionality
        if let revealViewController = self.revealViewController() {
            sidebarButton.target = revealViewController
            sidebarButton.action = #selector(revealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController.panGestureRecognizer())
        }
    }
    
    /** Starts the setup process. */
    @IBAction func setupGDSync(){
        presentViewController(SetupViewController(), animated: true, completion: nil)
    }
    
    @IBAction func deleteAllLocalFiles() {
        // Show safety question
        let confirmAlert = UIAlertController(title: "Confirm Reset", message: "Are you sure you want to reset the app? All of your local files will be lost. (The files in the Google Drive will not be deleted)", preferredStyle: .Alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Ok", style: .Destructive, handler: { (action: UIAlertAction!) in
            DataManager.sharedInstance.deleteAllFiles()
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            // Cancelled
        }))
        
        presentViewController(confirmAlert, animated: true, completion: nil)
    }
    
}