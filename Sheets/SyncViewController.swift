//
//  SyncViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 04.09.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

class SyncViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var sidebarButton: UIBarButtonItem!
    @IBOutlet var downloadButton: UIBarButtonItem!
    
    @IBOutlet var syncButton: UIBarButtonItem! {
        didSet {
            let icon = UIImage(named: "sync_icon")?.imageWithRenderingMode(.AlwaysTemplate)
            let iconSize = CGRect(origin: CGPointZero, size: icon!.size)
            //let iconButton = UIButton(frame: iconSize)
            let iconButton = UIButton(type: .System)
            
            iconButton.frame = iconSize
            iconButton.setBackgroundImage(icon, forState: .Normal)
            iconButton.tintColor = dataManager.defaultBlue
            //iconButton.addTarget(self, action: #selector(sync), forControlEvents: .TouchUpInside)
            
            syncButton.customView = iconButton
            
            syncButton.customView!.transform = CGAffineTransformIdentity
        }
    }
    
    var timer: NSTimer?
    
    var tableView: UITableView!
    
    var dataManager = DataManager.sharedInstance
    
    var selectedFile: File?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add Reveal Menu functionality
        if let revealViewController = self.revealViewController() {
            sidebarButton.target = revealViewController
            sidebarButton.action = #selector(revealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController.panGestureRecognizer())
        }
        
        generalSetup()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if dataManager.syncing {
            startSyncAnimation(.CurveEaseIn)
        }
    }
    
    func generalSetup() {
        
        let offset : CGFloat = 50
        let navHeight = (self.navigationController?.navigationBar.frame.height)! + offset
        let height = CGRectGetHeight(self.view.frame) - navHeight
        tableView = UITableView(frame: CGRectMake(0, navHeight, UIScreen.mainScreen().bounds.width, height ),
                                style: .Plain)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.addSubview(tableView)
        
        // Setup download button
        downloadButton.enabled = false
        
    }
    
    
    @IBAction func downloadButtonPressed(button: UIBarButtonItem) {
        
        // check if the filename exists locally. If it does, show an alert
        print("Request to download \(selectedFile?.filename)")
        if NamingManager.sharedInstance.filenameAlreadyExists(selectedFile!.filename.stringByDeletingPathExtension()) {
            // show the alert asking the user to change the filename of the local file so 
            // that the remote file can be downloaded
            let alert = UIAlertController(title: "Filename already exists locally.", message: "A file called \(selectedFile!.filename) already exists locally. Change the local filename to be able to donwload the new file from the Drive.", preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
        } else {
            dataManager.downloadFile(selectedFile!)
            startSyncAnimation(.CurveEaseIn)
        }
    }
    
    func startSyncAnimation(options: UIViewAnimationOptions) {
        
        syncButton.customView!.tintColor = UIColor.redColor()
        
        
        UIView.animateWithDuration(
            1.0,
            delay: 0.0,
            options: options,
            animations: {
                self.syncButton.customView!.transform =  CGAffineTransformRotate(self.syncButton.customView!.transform,
                    CGFloat(M_PI ))
            },
            completion: { (finished: Bool) in
                
                if finished {
                    
                    if self.dataManager.syncing {
                        // continue spinning animation
                        self.startSyncAnimation(.CurveLinear)
                    } else if options != .CurveEaseOut {
                        // end animation spin
                        //self.startSyncAnimation(.CurveEaseOut)
                        self.syncButton.customView?.tintColor = self.dataManager.defaultBlue
                        // reload the table view
                        self.tableView.reloadData()
                    }
                }
        })
    }
    
    
}

// UITableViewDelegate functions
extension SyncViewController {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager.deletedFiles.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Selected a cell
        selectedFile = dataManager.deletedFiles[indexPath.row]
        print("Selected \(selectedFile?.filename)")
        downloadButton.enabled = true
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        selectedFile = nil
        downloadButton.enabled = false
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.font = UIFont(name: "Futura", size: 25)
        
        if let deletedFiles = dataManager.deletedFiles {
            cell.textLabel?.text = deletedFiles[indexPath.row].filename
        }
        
        return cell
    }
}