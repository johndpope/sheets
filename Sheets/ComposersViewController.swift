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
        
        // setup Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // get files ordered by composer
        filesByComposer = dataManager.getFilesByComposer().sorted { $0.0.components(separatedBy: " ").last! < $1.0.components(separatedBy: " ").last! }
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
