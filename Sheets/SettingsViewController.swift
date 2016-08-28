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
        DataManager.sharedInstance.deleteAllFiles()
    }
    
}