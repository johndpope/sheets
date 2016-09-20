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
    
    let userDefaults = UserDefaults()
    
    var refreshControl: UIRefreshControl?
    
    var longPressGR: UILongPressGestureRecognizer?
    
    var tableView: UITableView!
    
    @IBOutlet var collectionView: UICollectionView!
    fileprivate let reuseIdentifier = "SheetCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 40.0, left: 20.0, bottom: 40.0, right: 20.0)
    fileprivate let retinaSectionInsets = UIEdgeInsets(top: 40.0, left: 40.0, bottom: 40.0, right: 40.0)
    fileprivate var selectedCell: SheetThumbCell?
    
    fileprivate var fileSelectionMode = false
    
    //UINavigationItems
    @IBOutlet var sidebarButton: UIBarButtonItem!
    @IBOutlet var searchButton: UIBarButtonItem!
    
    @IBOutlet var syncButton: UIBarButtonItem! {
        didSet {
            let icon = UIImage(named: "sync_icon")?.withRenderingMode(.alwaysTemplate)
            let iconSize = CGRect(origin: CGPoint.zero, size: icon!.size)
            //let iconButton = UIButton(frame: iconSize)
            let iconButton = UIButton(type: .system)
            
            iconButton.frame = iconSize
            iconButton.setBackgroundImage(icon, for: UIControlState())
            iconButton.tintColor = dataManager.defaultBlue
            iconButton.addTarget(self, action: #selector(sync), for: .touchUpInside)
            
            syncButton.customView = iconButton
            
            syncButton.customView!.transform = CGAffineTransform.identity
        }
    }
    
    @IBOutlet var displayTypeButton: UIBarButtonItem!
    
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
        titleView.textAlignment = .center
        titleView.font = UIFont(name: "Futura-Medium", size: 20)
        let width : CGFloat = 400//titleView.sizeThatFits(CGSizeMake(CGFloat.max, CGFloat.max)).width
        titleView.frame = CGRect(origin:CGPoint.zero, size:CGSize(width: width, height: 500))
        titleView.isUserInteractionEnabled = true
        self.navigationItem.titleView = titleView
        navTitleView = titleView
        filterLabel = titleView
        
        
        //add filter Gesture recognizer
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(showFilterView))
        recognizer.delegate = self
        titleView.addGestureRecognizer(recognizer)
        
        // Setup table view
        let offset : CGFloat = 50
        let navHeight = (self.navigationController?.navigationBar.frame.height)! + offset
        let height = self.view.frame.height - navHeight
        tableView = UITableView(frame: CGRect(x: 0, y: navHeight, width: UIScreen.main.bounds.width, height: height ),
                                style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        
        self.view.addSubview(tableView)
        
        tableView.isHidden = true
        
        // setup Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        
        dataManager.collectionView = self.collectionView
        dataManager.tableView = self.tableView
        
        // Load Thumbnails
        //let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        //let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        /*dispatch_async(dispatch_get_main_queue(), {
        
            self.dataManager.loadPDFThumbnails(self.collectionView)
                
        })*/
    }
    
    // When the view appears, ensure that the Drive API service is authorized
    // and perform API calls
    override func viewDidAppear(_ animated: Bool) {
        
        //self.navigationController!.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 80.0)
        
        if shouldShowFilterOptions {
            showFilterView()
        }
        
        generalSetup()
    }
    
    func generalSetup(){
        
        //files = [File]()
        
        // check if can authenticate
        if let authorizer = dataManager.service.authorizer , let canAuthorize = authorizer.canAuthorize, canAuthorize {
            print("Can authenticate, syncing enabled")
            dataManager.syncEnabled = true
        } else {
            print("Cannot authenticate, syncing disabled")
            dataManager.syncEnabled = false
        }
        
        //Test
        //dataManager.searchForAllFilesAndParents()
        
        dataManager.searchForMetadataFileInFolder(folderID: dataManager.mainFolderID!, onCompletion: {
            (found: Bool, file: GTLDriveFile?, error: Error?) in
            
            if found {
                print("Found")
            } else {
                print("Not found")
            }
        })
        
        //check if first time launch
        if (userDefaults.value(forKey: "firstTime") == nil) {
            userDefaults.set(false, forKey: "firstTime")
            userDefaults.set(true, forKey: "localOrderPriority")
            //setupSheetFolder()
            setupGoogleDriveSync()
        }else{
            
            //listAllLocalFiles()
            //printMetaDataFile()
        }
        dataManager.loadLocalFiles()
        reload()
        
        
        
        
        // Add long press gesture recognizer for the collectionView cells
        longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGR!.minimumPressDuration = 0.5
        longPressGR!.delegate = self
        longPressGR!.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(longPressGR!)
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)
        self.collectionView.addSubview(refreshControl!)
        
        if dataManager.syncing {
            startSyncAnimation(.curveEaseIn)
        }
        
        dataManager.collectionView = self.collectionView
        dataManager.tableView = self.tableView
    }
    
    func reload(){
        dataManager.loadLocalFiles()
        dataManager.filterFiles(dataManager.currentFilter)
        tableView.reloadData()
        collectionView.reloadData()
        refreshControl?.endRefreshing()
    }
    
    func setupGoogleDriveSync(){
        present(SetupViewController(), animated: true, completion: nil)
    }
    
    @IBAction func searchButtonPressed(_ sender: AnyObject){
        showSearchBar()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearchBar()
    }
    
    func showSearchBar(){
        
        navTitle = navigationItem.title
        navTitleView = navigationItem.titleView
        navigationItem.titleView = searchBar
        navigationItem.setLeftBarButton(nil, animated: true)
        
        let cancelButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(searchBarCancelButtonClicked(_:)))
        navigationItem.setRightBarButtonItems([cancelButton], animated: true)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.searchBar = UISearchBar()
            self.searchBar!.delegate = self
            self.searchBar!.alpha = 1
            self.navigationItem.titleView = self.searchBar
            
            }, completion: { finished in
                self.searchBar?.becomeFirstResponder()
                
        })
    }
    
    func hideSearchBar(){
        
        self.searchBar!.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
                //self.searchBar.alpha = 0
            
            }, completion: { finished in
                self.navigationItem.titleView = self.navTitleView
                
        })
        navigationItem.setLeftBarButton(sidebarButton, animated: true)
        navigationItem.setRightBarButtonItems([searchButton,syncButton], animated: true)
    }
    
    func showPDFInReader(_ file: File){
        VFRController.sharedInstance.showPDFInReader(file)
    }
    
    @IBAction func changeDisplayType() {
        
        // check which display type is active currently
        if collectionView.isHidden {
            // show the collectionView
            tableView.isHidden = true
            collectionView.isHidden = false
            // change the barbutton image
            displayTypeButton.image = UIImage(named: "table_icon")
        } else {
            // show the table view
            collectionView.isHidden = true
            tableView.isHidden = false
            // change the barbutton image
            displayTypeButton.image = UIImage(named: "collection_icon")
        }
    }
    
    
    func showFilterView(){
        
        let popoverY = self.navTitleView.frame.origin.y + 300
        let popoverRect = CGRect(x: self.view.bounds.midX, y: popoverY, width: 0, height: 0)
        
        let filterView = self.storyboard?.instantiateViewController(withIdentifier: "FilterVC") as! FilterViewController
        filterView.delegate = self
        
        let nav = UINavigationController(rootViewController: filterView)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.sourceView = self.view
        popover?.sourceRect = popoverRect
        
        self.present(nav, animated: true, completion: nil)
    }
    
    func filterPicked(_ filter: String) {
        filterLabel.text = filter
        dataManager.filterFiles(filter)
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    // Choose and delete files
    
    func handleLongPress(_ gestureRecognizer : UILongPressGestureRecognizer){
        
        switch(gestureRecognizer.state) {
            
        case UIGestureRecognizerState.began:
            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gestureRecognizer.location(in: self.collectionView)) else {
                break
            }
            
            selectFile(selectedIndexPath)
            
            // in file selection mode you should be able to change the order without needing a long press
            gestureRecognizer.minimumPressDuration = 0
            
            
            
            if #available(iOS 9.0, *) {
                collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            } else {
                // Fallback on earlier versions
            }
            
        case UIGestureRecognizerState.changed:
            if #available(iOS 9.0, *) {
                collectionView.updateInteractiveMovementTargetPosition(gestureRecognizer.location(in: gestureRecognizer.view!))
            } else {
                // Fallback on earlier versions
            }
            
        case UIGestureRecognizerState.ended:
            if #available(iOS 9.0, *) {
                collectionView.endInteractiveMovement()
            } else {
                // Fallback on earlier versions
            }
        default:
            if #available(iOS 9.0, *) {
                collectionView.cancelInteractiveMovement()
            } else {
                // Fallback on earlier versions
            }
        }
        
    }
    
    func selectFile(_ indexPath: IndexPath){
        let selectedFile = dataManager.filteredFiles[(indexPath as NSIndexPath).row]
        let newSelectedCell = self.collectionView.cellForItem(at: indexPath) as? SheetThumbCell
        
        dataManager.currentFile = selectedFile
        
        fileSelectionMode = true
        
        // mark the cell as chosen
        selectedCell?.borderEnabled = false
        selectedCell = newSelectedCell
        selectedCell?.borderEnabled = true
        
        fileChosen()
    }
    
    func selectFile(_ file: File) {
        let index = dataManager.filteredFiles.index(of: file)
        let indexPath = IndexPath(item: index!, section: 0)
        
        selectFile(indexPath)
    }
    
    func fileChosen() {
        
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteChosenFile))
            
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelFileSelection))
            
        navigationItem.rightBarButtonItems = [deleteButton]
        navigationItem.leftBarButtonItem = cancelButton
    }
    
    func deleteChosenFile() {
        
        let chosenFile = dataManager.currentFile
        
        if chosenFile == nil {
            return
        }
        
        // Show Safety question
        let alert = UIAlertController(
            title: "Delete \(chosenFile!.filename)?",
            message: "Are you sure you want to delete \(chosenFile!.filename) from the device?",
            preferredStyle: UIAlertControllerStyle.alert
        )
        let cancel = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        )
        let ok = UIAlertAction(
            title: "Delete",
            style: .destructive,
            handler: { (action: UIAlertAction) in
                self.dataManager.deleteFile(chosenFile!)
                self.dataManager.loadLocalFiles()
                self.reload()
                self.cancelFileSelection()
            }
        )
        
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func cancelFileSelection() {
        
        selectedCell?.borderEnabled = false
        selectedCell = nil
        
        fileSelectionMode = false
        longPressGR?.minimumPressDuration = 0.5
        
        navigationItem.rightBarButtonItems = [searchButton, syncButton]
        navigationItem.leftBarButtonItem = sidebarButton
        navigationItem.titleView = filterLabel
    }
    
    
    /** Calls the Sync function of the dataManager */
    @IBAction func sync(){
        //dataManager.fetchFilesInFolder()
        if dataManager.startSync() {
            startSyncAnimation(.curveEaseIn)
        } else {
            // check to see if the sync was enabled or not
            // If not ask the user if they would like to setup Google Drive sync
            if !dataManager.syncEnabled! {
                let alert = UIAlertController(title: "Google Drive Sync not enabled.", message: "Google drive sync isn't enabled yet. Would you like to set it up now?", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction) in
                    
                    self.present(SetupViewController(), animated: true, completion: nil)
                }))
            }
        }
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //number of cells
        return dataManager.filteredFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.font = UIFont(name: "Futura", size: 20)
        cell.textLabel?.text = dataManager.filteredFiles[(indexPath as NSIndexPath).row].filename.stringByDeletingPathExtension()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // cell selected code here
        
        if fileSelectionMode {
            selectFile(indexPath)
        } else {
            
            let file = dataManager.filteredFiles[(indexPath as NSIndexPath).row]
            dataManager.currentFile = file
            showPDFInReader(file)
        }
        
    }
    
    // MARK: UICollectionView Delegate & Datasource functions
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataManager.filteredFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
        if fileSelectionMode {
            selectFile(indexPath)
        } else {
            
            let file = dataManager.filteredFiles[(indexPath as NSIndexPath).row]
            dataManager.currentFile = file
            showPDFInReader(file)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! SheetThumbCell
        cell.backgroundColor = UIColor.white
        
        let file = dataManager.filteredFiles[(indexPath as NSIndexPath).row]
        
        if file.thumbnail == nil {
            file.thumbnail = dataManager.getThumbnailForFile(file)
        }
        
        cell.imageView.image = file.thumbnail
        
        // configure the cell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // reordering code here
        print("movedFrom: \((sourceIndexPath as NSIndexPath).row) to \((destinationIndexPath as NSIndexPath).row)")
        
        // find the index of the moved cell in the allFiles array
        let file = dataManager.filteredFiles[(sourceIndexPath as NSIndexPath).row]
        let oldIndex = dataManager.allFiles.index(of: file)
        dataManager.allFiles.remove(at: oldIndex!)
        dataManager.filteredFiles.remove(at: (sourceIndexPath as NSIndexPath).row)
        
        // if the file was moved to the beginning insert it at the beginning
        if (destinationIndexPath as NSIndexPath).row == 0 {
            // find the file after the destination
            let fileAfter = dataManager.filteredFiles[(destinationIndexPath as NSIndexPath).row]
            var newIndex = dataManager.allFiles.index(of: fileAfter)!
            newIndex = newIndex == 0 ? 0 : newIndex - 1
            dataManager.allFiles.insert(file, at: newIndex)
            
        } else {
            // find the file before the destination of the moved file
            let fileBefore = dataManager.filteredFiles[(destinationIndexPath as NSIndexPath).row - 1]
            let newIndex = dataManager.allFiles.index(of: fileBefore)! + 1
            dataManager.allFiles.insert(file, at: newIndex)
        }
        
        cancelFileSelection()
        
        dataManager.writeMetadataFile()
        
        reload()
        dataManager.currentFile = nil
        //selectedCell?.borderEnabled = false
        
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Determines the size of a given cell
        let file = dataManager.filteredFiles[(indexPath as NSIndexPath).row]
        
        if let thumb = file.thumbnail {
            return thumb.size
        } else {
            return dataManager.thumbnailSize
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let screenScale = UIScreen.main.scale
        if screenScale > 1.0 {
            // retina screen
            return retinaSectionInsets
        } else {
            // non retina
            return sectionInsets
        }
        
    }
    
    // MARK: - SearchbarDelegate methods
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        let searchText = searchBar.text
        if searchText == "" {
            filterPicked("All")
        } else {
            filterPicked(searchText!)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchText = searchBar.text
        if searchText == "" {
            filterPicked("All")
        } else {
            filterPicked(searchText!)
        }
        hideSearchBar()
    }
    
    // Helper for showing an alert
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController{
        return self
    }
    
}

