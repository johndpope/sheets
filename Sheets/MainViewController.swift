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

class MainViewController: UIViewController, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate, FilterViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    var dataManager = DataManager.sharedInstance
    
    let userDefaults = NSUserDefaults()
    
    var tableView: UITableView!
    
    @IBOutlet var collectionView: UICollectionView!
    private let reuseIdentifier = "SheetCell"
    private let sectionInsets = UIEdgeInsets(top: 40.0, left: 40.0, bottom: 40.0, right: 40.0)
    private var selectedCell: SheetThumbCell?
    
    private var fileSelectionMode = false
    
    //UINavigationItems
    @IBOutlet var sidebarButton: UIBarButtonItem!
    @IBOutlet var searchButton: UIBarButtonItem!
    
    @IBOutlet var syncButton: UIBarButtonItem! {
        didSet {
            let icon = UIImage(named: "sync_icon")?.imageWithRenderingMode(.AlwaysTemplate)
            let iconSize = CGRect(origin: CGPointZero, size: icon!.size)
            //let iconButton = UIButton(frame: iconSize)
            let iconButton = UIButton(type: .System)
            
            iconButton.frame = iconSize
            iconButton.setBackgroundImage(icon, forState: .Normal)
            iconButton.tintColor = dataManager.defaultBlue
            iconButton.addTarget(self, action: #selector(sync), forControlEvents: .TouchUpInside)
            
            syncButton.customView = iconButton
            
            syncButton.customView!.transform = CGAffineTransformIdentity
        }
    }
    
    var searchBar: UISearchBar?
    var navTitle: String!
    var navTitleView: UIView!
    var filterLabel: UILabel!
    
    //segue variable
    var shouldShowFilterOptions = false
    
    // When the view loads, create necessary subviews
    // and initialize the Drive API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add Reveal Menu functionality
        if let revealViewController = self.revealViewController() {
            sidebarButton.target = revealViewController
            sidebarButton.action = #selector(revealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController.panGestureRecognizer())
        }
        
        // Setup Navigation Bar Title Label
        let titleView = UILabel()
        titleView.text = dataManager.currentFilter
        titleView.textAlignment = .Center
        titleView.font = UIFont(name: "Futura-Medium", size: 20)
        let width : CGFloat = 400//titleView.sizeThatFits(CGSizeMake(CGFloat.max, CGFloat.max)).width
        titleView.frame = CGRect(origin:CGPointZero, size:CGSizeMake(width, 500))
        titleView.userInteractionEnabled = true
        self.navigationItem.titleView = titleView
        navTitleView = titleView
        filterLabel = titleView
        
        
        //add filter Gesture recognizer
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(showFilterView))
        recognizer.delegate = self
        titleView.addGestureRecognizer(recognizer)
        
        // setup Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Load Thumbnails
        //let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        //let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        /*dispatch_async(dispatch_get_main_queue(), {
        
            self.dataManager.loadPDFThumbnails(self.collectionView)
                
        })*/
    }
    
    // When the view appears, ensure that the Drive API service is authorized
    // and perform API calls
    override func viewDidAppear(animated: Bool) {
        
        //self.navigationController!.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 80.0)
        
        if shouldShowFilterOptions {
            showFilterView()
        }
        
        generalSetup()
    }
    
    func generalSetup(){
        
        //files = [File]()
        let offset : CGFloat = 50
        let navHeight = (self.navigationController?.navigationBar.frame.height)! + offset
        let height = CGRectGetHeight(self.view.frame) - navHeight
        tableView = UITableView(frame: CGRectMake(0, navHeight, UIScreen.mainScreen().bounds.width, height ),
                                style: .Plain)
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.addSubview(tableView)
        
        //check if first time launch
        if (userDefaults.valueForKey("firstTime") == nil) {
            userDefaults.setBool(false, forKey: "firstTime")
            //setupSheetFolder()
            setupGoogleDriveSync()
        }else{
            
            //listAllLocalFiles()
            //printMetaDataFile()
        }
        dataManager.loadLocalFiles()
        tableView.reloadData()
        
        // DEBUG
        tableView.hidden = true
        
        // Add long press gesture recognizer for the collectionView cells
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(lpgr)
    }
    
    func reload(){
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    func setupGoogleDriveSync(){
        presentViewController(SetupViewController(), animated: true, completion: nil)
    }
    
    @IBAction func searchButtonPressed(sender: AnyObject){
        showSearchBar()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        hideSearchBar()
    }
    
    func showSearchBar(){
        
        navTitle = navigationItem.title
        navTitleView = navigationItem.titleView
        navigationItem.titleView = searchBar
        navigationItem.setLeftBarButtonItem(nil, animated: true)
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(searchBarCancelButtonClicked(_:)))
        navigationItem.setRightBarButtonItems([cancelButton], animated: true)
        
        UIView.animateWithDuration(0.2, animations: {
            self.searchBar = UISearchBar()
            self.searchBar!.delegate = self
            self.searchBar!.alpha = 1
            self.navigationItem.titleView = self.searchBar
            
            }, completion: { finished in
                //self.searchBar.becomeFirstResponder()
                
        })
    }
    
    func hideSearchBar(){
        
        self.searchBar!.alpha = 0
        UIView.animateWithDuration(0.2, animations: {
                //self.searchBar.alpha = 0
            
            }, completion: { finished in
                self.navigationItem.titleView = self.navTitleView
                
        })
        navigationItem.setLeftBarButtonItem(sidebarButton, animated: true)
        navigationItem.setRightBarButtonItems([searchButton,syncButton], animated: true)
    }
    
    func showPDFInReader(filename: String){
        VFRController.sharedInstance.showPDFInReader(filename)
    }
    
    
    func showFilterView(){
        
        let popoverY = self.navTitleView.frame.origin.y + 300
        let popoverRect = CGRectMake(CGRectGetMidX(self.view.bounds), popoverY, 0, 0)
        
        let filterView = self.storyboard?.instantiateViewControllerWithIdentifier("FilterVC") as! FilterViewController
        filterView.delegate = self
        
        let nav = UINavigationController(rootViewController: filterView)
        nav.modalPresentationStyle = .Popover
        let popover = nav.popoverPresentationController
        popover?.sourceView = self.view
        popover?.sourceRect = popoverRect
        
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    func filterPicked(filter: String) {
        filterLabel.text = filter
        DataManager.sharedInstance.filterFiles(filter)
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    // Choose and delete files
    
    func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        
        if (gestureRecognizer.state != .Began){
            return
        }
        
        let p = gestureRecognizer.locationInView(self.collectionView)
        
        if let indexPath : NSIndexPath = (self.collectionView?.indexPathForItemAtPoint(p)){
            selectFile(indexPath)
            
        } else {
            print("Couldn't find index path.")
        }
        
    }
    
    func selectFile(indexPath: NSIndexPath){
        let selectedFile = dataManager.filteredFiles[indexPath.row]
        let newSelectedCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? SheetThumbCell
        
        dataManager.currentFile = selectedFile
        
        fileSelectionMode = true
        
        // mark the cell as chosen
        selectedCell?.borderEnabled = false
        selectedCell = newSelectedCell
        selectedCell?.borderEnabled = true
        
        fileChosen()
    }
    
    func fileChosen() {
        
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(deleteChosenFile))
            
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(cancelFileSelection))
            
        navigationItem.rightBarButtonItems = [deleteButton]
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    func deleteChosenFile() {
        
        let chosenFile = dataManager.currentFile
        
        // Show Safety question
        let alert = UIAlertController(
            title: "Delete \(chosenFile.filename)?",
            message: "Are you sure you want to delete \(chosenFile.filename) from the device?",
            preferredStyle: UIAlertControllerStyle.Alert
        )
        let cancel = UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: nil
        )
        let ok = UIAlertAction(
            title: "Delete",
            style: .Destructive,
            handler: { (action: UIAlertAction) in
                self.dataManager.deleteFile(chosenFile)
                self.dataManager.loadLocalFiles()
                self.reload()
                self.cancelFileSelection()
            }
        )
        
        alert.addAction(ok)
        alert.addAction(cancel)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func cancelFileSelection() {
        
        selectedCell?.borderEnabled = false
        selectedCell = nil
        
        fileSelectionMode = false
        
        navigationItem.rightBarButtonItems = [searchButton, syncButton]
        navigationItem.leftBarButtonItem = sidebarButton
        navigationItem.titleView = filterLabel
    }
    
    
    /** Calls the Sync function of the dataManager */
    @IBAction func sync(){
        //dataManager.fetchFilesInFolder()
        if dataManager.startSync() {
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
                    }
                }
            })
    }
    
    func listAllLocalFiles(){
        let fileNames = dataManager.listAllLocalFiles()
        print("Filenames: " + fileNames)
    }
    
    
    
    //TableView Delegate and DataSource functions
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //number of cells
        return dataManager.filteredFiles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.text = dataManager.filteredFiles[indexPath.row].filename.stringByDeletingPathExtension()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // cell selected code here
        
        if fileSelectionMode {
            selectFile(indexPath)
        } else {
            
            let file = dataManager.filteredFiles[indexPath.row]
            dataManager.currentFile = file
            showPDFInReader(file.filename)
        }
        
    }
    
    // MARK: UICollectionView Delegate & Datasource functions
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataManager.filteredFiles.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    
        if fileSelectionMode {
            selectFile(indexPath)
        } else {
            
            let file = dataManager.filteredFiles[indexPath.row]
            dataManager.currentFile = file
            showPDFInReader(file.filename)
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! SheetThumbCell
        cell.backgroundColor = UIColor.whiteColor()
        
        let file = dataManager.filteredFiles[indexPath.row]
        
        if file.thumbnail == nil {
            file.thumbnail = dataManager.getThumbnailForFile(file)
        }
        
        cell.imageView.image = file.thumbnail
        
        // configure the cell
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // Determines the size of a given cell
        let file = dataManager.filteredFiles[indexPath.row]
        
        if let thumb = file.thumbnail {
            return thumb.size
        } else {
            return dataManager.thumbnailSize
        }
        
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // MARK: - SearchbarDelegate methods
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        let searchText = searchBar.text
        if searchText == "" {
            filterPicked("All")
        } else {
            filterPicked(searchText!)
        }
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
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController{
        return self
    }
    
}

