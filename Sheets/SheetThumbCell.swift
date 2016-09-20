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
    
    let borderWidth: CGFloat = 7
    let borderColor = UIColor(red: 240/255, green: 102/255, blue: 109/255, alpha: 1)
    
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
            imageView.layer.borderColor = borderColor.cgColor
            imageView.layer.borderWidth = borderWidth
        } else {
            imageView.layer.borderColor = UIColor.clear.cgColor
            imageView.layer.borderWidth = 0
        }
        
    }
    
}
