//
//  SheetSectionHeader.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 10.09.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

class SheetSectionHeader : UICollectionReusableView {
    
    @IBOutlet var label: UILabel!
    
    var text: String? {
        didSet {
            label.text = text
        }
    }

}