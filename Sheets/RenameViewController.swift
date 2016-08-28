//
//  RenameViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 06.07.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import UIKit

class RenameViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var file: File?
    
    @IBOutlet weak var filenameInput: UITextField!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var composerInput: UITextField!
    @IBOutlet weak var arrangerInput: UITextField!
    @IBOutlet weak var opusInput: UITextField!
    @IBOutlet weak var numberInput: UITextField!
    @IBOutlet weak var tempoInput: UITextField!
    @IBOutlet weak var keyInput: UITextField!
    @IBOutlet weak var musicalFormInput: UITextField!
    @IBOutlet weak var instrumentInput: UITextField!
    
    // UIPickerview
    @IBOutlet weak var namingPickerView: UIPickerView!
    var pickerDataSource = ["Value1","Value2","Value3","Value4"]
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.preferredContentSize = CGSizeMake(700, 580)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.preferredContentSize = CGSizeMake(700, 580)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UIBarButtonItems
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(updateInfo))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(dismiss))
        
        // Setup UIPickerView
        self.namingPickerView.delegate = self
        self.namingPickerView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupInputFields()
    }
    
    func setupInputFields(){
        // filename
        //filenameInput.text = ((file?.title)! as NSString).stringByDeletingPathExtension
        filenameInput.text = ((file?.filename)! as NSString).stringByDeletingPathExtension
        //title
        titleInput.text = file?.title
        
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
        dismiss()
    }
    
    func dismiss(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
}
