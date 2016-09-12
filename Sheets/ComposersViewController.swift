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
    
    var dataManager = DataManager.sharedInstance
    
    private let sectionInsets = UIEdgeInsets(top: 40.0, left: 20.0, bottom: 40.0, right: 20.0)
    private let retinaSectionInsets = UIEdgeInsets(top: 40.0, left: 40.0, bottom: 40.0, right: 40.0)
    
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
        
        // setup Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // get files ordered by composer
        filesByComposer = dataManager.getFilesByComposer().sort { $0.0.componentsSeparatedByString(" ").last! < $1.0.componentsSeparatedByString(" ").last! }
    }
    
}

extension ComposersViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return filesByComposer.count
    }
    
    @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filesByComposer[section].1.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // VFRController show document
        let filename = filesByComposer[indexPath.section].1[indexPath.row].filename
        VFRController.sharedInstance.showPDFInReader(filename)
    }
    
    @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! SheetThumbCell
        cell.backgroundColor = UIColor.whiteColor()
        
        let file = filesByComposer[indexPath.section].1[indexPath.row]
        
        if file.thumbnail == nil {
            file.thumbnail = dataManager.getThumbnailForFile(file)
        }
        
        cell.imageView.image = file.thumbnail
        
        // configure the cell
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: reuseIdentifierHeader, forIndexPath: indexPath) as! SheetSectionHeader
        
        header.text = filesByComposer[indexPath.section].0
        
        return header
        
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // Determines the size of a given cell
        let file = filesByComposer[indexPath.section].1[indexPath.row]
        
        if let thumb = file.thumbnail {
            return thumb.size
        } else {
            return dataManager.thumbnailSize
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let screenScale = UIScreen.mainScreen().scale
        if screenScale > 1.0 {
            // retina screen
            return retinaSectionInsets
        } else {
            // non retina
            return sectionInsets
        }
        
    }
    
    
}