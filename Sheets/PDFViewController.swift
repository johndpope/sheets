//
//  PDFViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 03.07.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics


class PDFViewController : NSObject, UIPageViewControllerDataSource {
    
    var pageViewController: UIPageViewController!
    var pdfDocRef: CGPDFDocumentRef!
    var filePath: NSURL!
    var cgPDFPages: [CGPDFPage]!
    var viewControllers: [UIViewController]!
    var numberOfPages: Int!
    var currentPage: Int!
    
    //Instantiates a PDFViewController with the path to the PDF document
    init(filePath: NSURL){
        super.init()
        setup(filePath)
    }
    
    func setup(filepath: NSURL){
        cgPDFPages = [CGPDFPage]()
        viewControllers = [UIViewController]()
        
        pageViewController = UIPageViewController(
            transitionStyle: UIPageViewControllerTransitionStyle.Scroll,
            navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal,
            options: nil)
        
        pageViewController.dataSource = self
        
        self.filePath = filepath
        
        //setup PDF Pages as list of UIViewControllers
        pdfDocRef = CGPDFDocumentCreateWithURL(filepath)
        numberOfPages = CGPDFDocumentGetNumberOfPages(pdfDocRef)
        
        for i in 1...numberOfPages {
            cgPDFPages.append(CGPDFDocumentGetPage(pdfDocRef, i)!)
        }
        
        //setup ViewControllers
        for i in 1...numberOfPages {
            viewControllers.append(PDFPageViewController(page: cgPDFPages[i-1]))
        }
        
        currentPage = 0
    }
    
    //Returns the view controller before the given view controller.
    @objc func pageViewController(pageViewController: UIPageViewController,
                              viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.indexOf(viewController) {
            return viewControllers[index - 1]
        }else{
            return viewControllers[0]
        }
    }
    
    //Returns the view controller after the given view controller.
    @objc func pageViewController(pageViewController: UIPageViewController,
                              viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.indexOf(viewController) {
            return viewControllers[index + 1]
        }else{
            return viewControllers[0]
        }
    }
}