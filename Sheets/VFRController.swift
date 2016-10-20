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
    
    var readerViewController: ReaderViewController?
    var presentingVC: UIViewController?
    
    var fileToReopen: File?
    var shouldReopen = false
    
    func showPDFInReader(_ file: File){
        
        showPDFInReader(file, presentedBy: UIApplication.topViewController()!)
    }
    
    func showPDFInReader(_ file: File, presentedBy viewController: UIViewController) {
        
        DataManager.sharedInstance.currentFile = file
        
        let readerDocument = ReaderDocument(filePath: file.getUrl().path, password: "")
        readerViewController = ReaderViewController(readerDocument: readerDocument)
        
        if let readerViewController = readerViewController, readerDocument != nil {
            presentingVC = viewController
            presentingVC!.present(readerViewController, animated: true, completion: nil)
            readerViewController.delegate = self
        }else {
            print("Reader document for \(file.filename) could not be created!")
        }
    }
    
    @objc func dismiss(_ viewController: ReaderViewController!) {
        viewController.dismiss(animated: true, completion: {
            
           /*if let fileToReopen = self.fileToReopen {
                
                self.showPDFInReader(fileToReopen)
                self.fileToReopen = nil
            }*/
            
            if self.shouldReopen {
                
                self.showPDFInReader(DataManager.sharedInstance.currentFile!)
                self.shouldReopen = false
            }
        })
    }
    
    func reopenFileInReader(_ file: File) {
        
        if let readerViewController = readerViewController, let presentingVC = presentingVC {
            
            fileToReopen = file
            shouldReopen = true
            
            readerViewController.closeDocument()
            
        } else {
            print("Current reader viewController nil")
        }
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












