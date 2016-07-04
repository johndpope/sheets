//
//  PDFPageViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 03.07.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class PDFPageViewController: UIViewController {
    
    var page: CGPDFPage!
    
    init(page: CGPDFPage){
        super.init(nibName: nil, bundle: nil)
        self.page = page
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        drawPDFPage(page)
    }
    
    func drawPDFPage(page: CGPDFPage) {
        let context = UIGraphicsGetCurrentContext()
        
        CGContextDrawPDFPage(context, page)
    }
    
}