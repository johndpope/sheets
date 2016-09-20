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
    
    func showPDFInReader(_ file: File){
        
        DataManager.sharedInstance.currentFile = file
        
        let readerDocument = ReaderDocument(filePath: file.getUrl().path, password: "")
        let readerViewController = ReaderViewController(readerDocument: readerDocument)
        
        if let readerViewController = readerViewController, readerDocument != nil {
            UIApplication.topViewController()!.present(readerViewController, animated: true, completion: nil)
            readerViewController.delegate = self
        }else {
            print("Reader document could not be created!")
        }
    }
    
    @objc func dismiss(_ viewController: ReaderViewController!) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    @objc func showRenameView(_ viewController: ReaderViewController!, nameLabel: UILabel, document: ReaderDocument) {
        
        let presentingVC = UIApplication.topViewController()!.presentingViewController!
        
        let popoverY = nameLabel.frame.origin.y + 40
        let popoverRect = CGRect(x: viewController.view.bounds.midX, y: popoverY,width: 0,height: 0)
        
        let renameView = presentingVC.storyboard?.instantiateViewController(withIdentifier: "RenameVC") as! RenameViewController
        let nav = UINavigationController(rootViewController: renameView)
        
        renameView.file = DataManager.sharedInstance.currentFile
        
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.sourceView = viewController.view
        popover?.sourceRect = popoverRect
        
        viewController.present(nav, animated: true, completion: nil)
    }
    
}












