//
//  RenameViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 06.07.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import UIKit

class RenameViewController: UIViewController {
    
    var file: File?
    
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.preferredContentSize = CGSizeMake(400, 700)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(updateInfo))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //IBOutlets should not be nil here
        titleLabel.text = "Title"
        titleInput.text = ((file?.title)! as NSString).stringByDeletingPathExtension
    }
    
    func updateTitle(title: String){
        if let input = titleInput {
            input.text = title
        } else {
            print("TitleInput doesn't exist")
        }
    }
    
    func updateInfo(){
        print("UPdate info")
        //close
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
