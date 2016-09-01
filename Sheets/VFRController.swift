//
//  VFRController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 21.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import vfrReader

class VFRController : NSObject, ReaderViewControllerDelegate {
    
    static let sharedInstance = VFRController()
    
    func showPDFInReader(filename: String){
        let filePath = DataManager.sharedInstance.createDocumentURLFromFilename(filename).path
        let readerDocument = ReaderDocument(filePath: filePath!, password: "")
        let readerViewController = ReaderViewController(readerDocument: readerDocument)
        
        if readerDocument != nil {
            UIApplication.topViewController()!.presentViewController(readerViewController, animated: true, completion: nil)
            readerViewController.delegate = self
        }else {
            print("Reader document could not be created!")
        }
    }
    
    @objc func dismissReaderViewController(viewController: ReaderViewController!) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc func showRenameView(viewController: ReaderViewController!, nameLabel: UILabel, document: ReaderDocument) {
        
        let presentingVC = UIApplication.topViewController()!.presentingViewController!
        
        let popoverY = nameLabel.frame.origin.y + 40
        let popoverRect = CGRectMake(CGRectGetMidX(viewController.view.bounds), popoverY,0,0)
        
        let renameView = presentingVC.storyboard?.instantiateViewControllerWithIdentifier("RenameVC") as! RenameViewController
        let nav = UINavigationController(rootViewController: renameView)
        
        renameView.file = DataManager.sharedInstance.currentFile
        
        nav.modalPresentationStyle = .Popover
        let popover = nav.popoverPresentationController
        popover?.sourceView = viewController.view
        popover?.sourceRect = popoverRect
        
        viewController.presentViewController(nav, animated: true, completion: nil)
    }
    
}












