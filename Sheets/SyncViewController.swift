//
//  SyncViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 04.09.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

/** Actually the "DeletedViewController" */
class SyncViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var sidebarButton: UIBarButtonItem!
    @IBOutlet var downloadButton: UIBarButtonItem!
    var downloadAllButton: UIBarButtonItem!
    
    @IBOutlet var syncButton: UIBarButtonItem! {
        didSet {
            let icon = UIImage(named: "sync_icon")?.withRenderingMode(.alwaysTemplate)
            let iconSize = CGRect(origin: CGPoint.zero, size: icon!.size)
            //let iconButton = UIButton(frame: iconSize)
            let iconButton = UIButton(type: .system)
            
            iconButton.frame = iconSize
            iconButton.setBackgroundImage(icon, for: UIControlState())
            iconButton.tintColor = UIColor.clear  //dataManager.defaultBlue
            //iconButton.addTarget(self, action: #selector(sync), forControlEvents: .TouchUpInside)
            
            syncButton.customView = iconButton
            
            syncButton.customView!.transform = CGAffineTransform.identity
        }
    }
    
    var timer: Timer?
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        
        if dataManager.syncing {
            startSyncAnimation(.curveEaseIn)
        }
    }
    
    func generalSetup() {
        
        let offset : CGFloat = 0
        let navHeight = (self.navigationController?.navigationBar.frame.height)! + offset
        let height = self.view.frame.height - navHeight
        tableView = UITableView(frame: CGRect(x: 0, y: navHeight, width: UIScreen.main.bounds.width, height: height ),
                                style: .plain)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.addSubview(tableView)
        
        // Setup download button
        downloadButton.isEnabled = false
        
        // setup the download all button
        downloadAllButton = UIBarButtonItem(title: "Download All",
                                            style: .plain, target: self,
                                            action: #selector(downloadAllButtonPressed(_:)))
        downloadAllButton.tintColor = dataManager.defaultBlue
        downloadAllButton.isEnabled = dataManager.deletedFiles.count > 0
        
        // add a padding item between the two download buttons
        let paddingButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        self.navigationItem.setRightBarButtonItems([downloadButton, syncButton], animated: false)
        self.navigationItem.setLeftBarButtonItems([sidebarButton, downloadAllButton], animated: false)
        
        dataManager.tableView = self.tableView
    }
    
    
    @IBAction func downloadButtonPressed(_ button: UIBarButtonItem) {
        
        // disable the download button to prevent accidental double click
        downloadButton.isEnabled = false
        
        // check if the filename exists locally. If it does, show an alert
        print("Request to download \(selectedFile!.filename)")
        if NamingManager.sharedInstance.filenameAlreadyExists(selectedFile!.filename.stringByDeletingPathExtension()) {
            // show the alert asking the user to change the filename of the local file so 
            // that the remote file can be downloaded
            let alert = UIAlertController(title: "Filename already exists locally.", message: "A file called \(selectedFile!.filename) already exists locally. Change the local filename to be able to download the new file from the Drive.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
        } else {
            dataManager.downloadFile(selectedFile!)
            startSyncAnimation(.curveEaseIn)
        }
    }
    
    @IBAction func downloadAllButtonPressed(_ button: UIBarButtonItem) {
        
        func downloadAllFiles() {
            print("Requested to download all deleted files.")
            
            var count = 0
            
            for file in dataManager.deletedFiles {
                
                // check to see if the filename already exists locally
                // if yes, skip the download
                if !NamingManager.sharedInstance.filenameAlreadyExists(file.filename.stringByDeletingPathExtension()) {
                    dataManager.downloadFile(file)
                    count += 1
                }
            }
            
            if count > 0 {
                startSyncAnimation(.curveEaseIn)
            }
        }
        
        // Make sure the user really wants to download all files
        let alert = UIAlertController(title: "Downloading all files", message: "Are you sure you want to download all of the files?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {
            action in downloadAllFiles()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    func startSyncAnimation(_ options: UIViewAnimationOptions) {
        
        syncButton.customView!.tintColor = UIColor.red
        
        
        UIView.animate(
            withDuration: 1.0,
            delay: 0.0,
            options: options,
            animations: {
                self.syncButton.customView!.transform =  self.syncButton.customView!.transform.rotated(by: CGFloat(M_PI ))
            },
            completion: { (finished: Bool) in
                
                if finished {
                    
                    if self.dataManager.syncing {
                        // continue spinning animation
                        self.startSyncAnimation(.curveLinear)
                    } else if options != .curveEaseOut {
                        // end animation spin
                        //self.startSyncAnimation(.CurveEaseOut)
                        self.syncButton.customView?.tintColor = UIColor.clear
                        // reload the table view
                        self.tableView.reloadData()
                    }
                }
        })
    }
    
    
}

// UITableViewDelegate functions
extension SyncViewController {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        downloadAllButton.isEnabled = dataManager.deletedFiles.count > 0
        return dataManager.deletedFiles.count
    }
    
    @objc(tableView:didSelectRowAtIndexPath:) func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Selected a cell
        selectedFile = dataManager.deletedFiles[(indexPath as NSIndexPath).row]
        print("Selected \(selectedFile!.filename)")
        downloadButton.isEnabled = true
    }
    
    @objc(tableView:didDeselectRowAtIndexPath:) func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedFile = nil
        downloadButton.isEnabled = false
    }
    
    @objc(tableView:cellForRowAtIndexPath:) func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.font = UIFont(name: "Futura", size: 25)
        
        if let deletedFiles = dataManager.deletedFiles {
            let file = deletedFiles[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = file.filename
            cell.isUserInteractionEnabled = !file.isDownloading
        }
        
        return cell
    }
}
