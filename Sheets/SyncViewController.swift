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
    @IBOutlet var progressView: UIProgressView!
    
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
        
        // Setup progressView 
        /*
        progressView.progress = Float(dataManager.getSyncProgress())
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: NSBlockOperation(block: {
            
            //progressBar.progress = Float(self.dataManager.currentDownloadProgress)
            self.progressView.progress = Float(self.dataManager.getSyncProgress())
            
            if self.progressView.progress >= 0.99 {
                self.timer!.invalidate()
            }
            
        }), selector: #selector(NSOperation.main), userInfo: nil, repeats: true)
        */
    }
    
    
    @IBAction func downloadButtonPressed(button: UIBarButtonItem) {
        
        dataManager.downloadFile(selectedFile!)
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
        cell.textLabel?.font = UIFont(name: "Futura", size: 20)
        
        if let deletedFiles = dataManager.deletedFiles {
            cell.textLabel?.text = deletedFiles[indexPath.row].filename
        }
        
        return cell
    }
}