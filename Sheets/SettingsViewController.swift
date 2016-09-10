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
    @IBOutlet var defaultInstrumentTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add Reveal Menu functionality
        if let revealViewController = self.revealViewController() {
            sidebarButton.target = revealViewController
            sidebarButton.action = #selector(revealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController.panGestureRecognizer())
        }
        
        // setup default Instrument
        if let defaultInstrument = NSUserDefaults().valueForKey("defaultInstrument") {
            defaultInstrumentTextField.text = defaultInstrument as! String
        }
    }
    
    /** Starts the setup process. */
    @IBAction func setupGDSync(){
        presentViewController(SetupViewController(), animated: true, completion: nil)
    }
    
    @IBAction func reset() {
        // Show safety question
        let confirmAlert = UIAlertController(title: "Confirm Reset", message: "Are you sure you want to reset the app? All of your local files will be lost. (The files in the Google Drive will not be deleted)", preferredStyle: .Alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Ok", style: .Destructive, handler: { (action: UIAlertAction!) in
            DataManager.sharedInstance.reset()
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            // Cancelled
        }))
        
        presentViewController(confirmAlert, animated: true, completion: nil)
    }
    
    @IBAction func deleteAllFiles() {
        // Show safety question
        let confirmAlert = UIAlertController(title: "Confirm to delete files", message: "Are you sure you want to delete the local files? All of the files will be lost.  If they were synced with the Drive you can download them at any time in the \"sync\" section.", preferredStyle: .Alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Ok", style: .Destructive, handler: { (action: UIAlertAction!) in
            DataManager.sharedInstance.deleteAllFiles()
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
            // Cancelled
        }))
        
        presentViewController(confirmAlert, animated: true, completion: nil)
    }
    
    @IBAction func switchChanged(prioSwitch: UISwitch) {
        NSUserDefaults().setBool(prioSwitch.on, forKey: "localOrderPriority")
    }
    
    @IBAction func defaultInstrumentChanged(textField: UITextField) {
        NSUserDefaults().setValue(textField.text, forKey: "defaultInstrument")
    }
    
    @IBAction func setInstrumentForAll(){
        if let defaultInstrument = NSUserDefaults().valueForKey("defaultInstrument") where defaultInstrument as! String != "" {
            
            for file in DataManager.sharedInstance.allFiles {
                if file.instrument == "" {
                    file.instrument = defaultInstrument as! String
                }
            }
            
            DataManager.sharedInstance.writeMetadataFile()
        }
    }
}











