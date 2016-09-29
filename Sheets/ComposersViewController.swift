//
//  ComposersViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 10.09.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

class ComposersViewController : UIViewController {
    
    @IBOutlet var sidebarButton: UIBarButtonItem!
    @IBOutlet var collectionView: UICollectionView!
    var tableView: UITableView!
    
    var displayTypeButton: UIBarButtonItem!
    
    var dataManager = DataManager.sharedInstance
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 40.0, left: 20.0, bottom: 40.0, right: 20.0)
    fileprivate let retinaSectionInsets = UIEdgeInsets(top: 40.0, left: 40.0, bottom: 40.0, right: 40.0)
    
    let reuseIdentifier = "SheetCell"
    let reuseIdentifierHeader = "composerHeader"
    
    var filesByComposer: [(String,[File])]!
    
    override func viewDidLoad() {
        
        //add Reveal Menu functionality
        if let revealViewController = self.revealViewController() {
            sidebarButton.target = revealViewController
            sidebarButton.action = #selector(revealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController.panGestureRecognizer())
        }
        
        // setup table view
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
        
        // get files ordered by composer
        filesByComposer = dataManager.getFilesByComposer().sorted { $0.0.components(separatedBy: " ").last! < $1.0.components(separatedBy: " ").last! }
        
        // setup displaytype button
        displayTypeButton = UIBarButtonItem(image: UIImage(named: "table_icon") , style: .plain, target: self, action: #selector(changeDisplayType))
        navigationItem.leftBarButtonItems = [sidebarButton, displayTypeButton]
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
    
}

extension ComposersViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return filesByComposer.count
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filesByComposer[section].1.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // VFRController show document
        let file = filesByComposer[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
        VFRController.sharedInstance.showPDFInReader(file)
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! SheetThumbCell
        cell.backgroundColor = UIColor.white
        
        let file = filesByComposer[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
        
        if file.thumbnail == nil {
            file.thumbnail = dataManager.getThumbnailForFile(file)
        }
        
        cell.imageView.image = file.thumbnail
        
        // configure the cell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseIdentifierHeader, for: indexPath) as! SheetSectionHeader
        
        header.text = filesByComposer[(indexPath as NSIndexPath).section].0
        
        return header
        
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Determines the size of a given cell
        let file = filesByComposer[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
        
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
}

extension ComposersViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // VFRController show document
        let file = filesByComposer[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
        VFRController.sharedInstance.showPDFInReader(file)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesByComposer[section].1.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filesByComposer[section].0
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Futura", size: 38)!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.font = UIFont(name: "Futura", size: 20)
        cell.textLabel?.text = filesByComposer[(indexPath as NSIndexPath).section].1[indexPath.row].filename.stringByDeletingPathExtension()
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filesByComposer.count
    }
    
}
