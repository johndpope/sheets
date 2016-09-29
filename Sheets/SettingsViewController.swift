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
    @IBOutlet var prioSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add Reveal Menu functionality
        if let revealViewController = self.revealViewController() {
            sidebarButton.target = revealViewController
            sidebarButton.action = #selector(revealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController.panGestureRecognizer())
        }
        
        // setup default Instrument
        if let defaultInstrument = UserDefaults().value(forKey: "defaultInstrument") {
            defaultInstrumentTextField.text = defaultInstrument as? String
        }
        
        // setup prio switch
        prioSwitch.setOn(UserDefaults().bool(forKey: "localOrderPriority"), animated: false)
        
        // add copyright notice
        let copyright = UILabel(frame: CGRect(x: 20, y: view.frame.height - 30, width: 250, height: 25))
        copyright.text = "© 2016 Keiwan Donyagard"
        copyright.font = UIFont(name: "Futura", size: 13)
        self.view.addSubview(copyright)
        
    }
    
    /** Starts the setup process. */
    @IBAction func setupGDSync(){
        present(SetupViewController(), animated: true, completion: nil)
    }
    
    @IBAction func reset() {
        // Show safety question
        let confirmAlert = UIAlertController(title: "Confirm Reset", message: "Are you sure you want to reset the app? All of your local files will be lost. (The files in the Google Drive will not be deleted)", preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { (action: UIAlertAction!) in
            DataManager.sharedInstance.reset()
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            // Cancelled
        }))
        
        present(confirmAlert, animated: true, completion: nil)
    }
    
    @IBAction func deleteAllFiles() {
        // Show safety question
        let confirmAlert = UIAlertController(title: "Confirm to delete files", message: "Are you sure you want to delete the local files? All of the files will be lost.  If they were synced with the Drive you can download them at any time in the \"sync\" section.", preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { (action: UIAlertAction!) in
            DataManager.sharedInstance.deleteAllFiles()
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            // Cancelled
        }))
        
        present(confirmAlert, animated: true, completion: nil)
    }
    
    @IBAction func switchChanged(_ prioSwitch: UISwitch) {
        UserDefaults().set(prioSwitch.isOn, forKey: "localOrderPriority")
    }
    
    @IBAction func defaultInstrumentChanged(_ textField: UITextField) {
        UserDefaults().setValue(textField.text, forKey: "defaultInstrument")
    }
    
    @IBAction func setInstrumentForAll(){
        if let defaultInstrument = UserDefaults().value(forKey: "defaultInstrument") , defaultInstrument as! String != "" {
            
            for file in DataManager.sharedInstance.allFiles {
                if file.instrument == "" {
                    file.instrument = defaultInstrument as! String
                }
            }
            
            DataManager.sharedInstance.writeMetadataFile()
        }
    }
}











