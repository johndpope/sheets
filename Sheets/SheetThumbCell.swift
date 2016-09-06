//
//  SheetThumbCell.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 02.09.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import QuartzCore

class SheetThumbCell: UICollectionViewCell {
    
    var borderEnabled = false {
        didSet {
            drawBorder()
        }
    }
    
    let borderWidth: CGFloat = 5
    let borderColor = UIColor.redColor()//UIColor(red: 148, green: 202, blue: 209, alpha: 1)
    
    @IBOutlet var imageView: UIImageView! {
        didSet {
            drawBorder()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //setup()
    }
    
    func drawBorder(){
        
        if borderEnabled {
            imageView.layer.borderColor = borderColor.CGColor
            imageView.layer.borderWidth = borderWidth
        } else {
            imageView.layer.borderColor = UIColor.clearColor().CGColor
            imageView.layer.borderWidth = 0
        }
        
    }
    
}