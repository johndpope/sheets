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
    @IBOutlet weak var composerInput: AutocompleteUITextField!
    @IBOutlet weak var arrangerInput: AutocompleteUITextField!
    @IBOutlet weak var opusInput: UITextField!
    @IBOutlet weak var numberInput: UITextField!
    @IBOutlet weak var tempoInput: AutocompleteUITextField!
    @IBOutlet weak var keyInput: AutocompleteUITextField!
    @IBOutlet weak var musicalFormInput: AutocompleteUITextField!
    @IBOutlet weak var instrumentInput: AutocompleteUITextField!
    
    @IBOutlet weak var alreadyExistsLabel: UILabel!
    var saveButton: UIBarButtonItem!
    
    var selectedPreset = 0
    
    // UIPickerview
    @IBOutlet weak var namingPickerView: UIPickerView!
    
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
        saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(updateMetadata))
        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(dismiss))
        
        // Setup UIPickerView
        self.namingPickerView.delegate = self
        self.namingPickerView.dataSource = self
        
        filenameInput.addTarget(self, action: #selector(filenameInputChanged), forControlEvents: .EditingChanged)
        
        NamingManager.sharedInstance.loadPresets()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupInputFields()
    }
    
    /** 
        Sets up the inputFields from the file metadata.
    */
    func setupInputFields(){
        // filename
        // filenameInput.text = ((file?.title)! as NSString).stringByDeletingPathExtension
        filenameInput.text = (file?.filename)!.stringByDeletingPathExtension()
        
        alreadyExistsLabel.hidden = true
        
        titleInput.text = file?.title
        
        composerInput.text = file?.composer
        composerInput.autocompleteStrings = DataManager.sharedInstance.composerNames
        
        arrangerInput.text = file?.arranger
        arrangerInput.autocompleteStrings = DataManager.sharedInstance.composerNames
        
        if let opus = file?.opus where opus != -1 {
            opusInput.text = "\(opus)"
        } else {
            opusInput.text = ""
            
        }
        
        if let number = file?.number where number != -1{
            numberInput.text = "\(number)"
        } else {
            numberInput.text = ""
        }

        tempoInput.text = file?.tempo
        tempoInput.autocompleteStrings = DataManager.sharedInstance.tempoNames
        
        keyInput.text = file?.key
        keyInput.autocompleteStrings = DataManager.sharedInstance.keys
        
        musicalFormInput.text = file?.musicalForm
        musicalFormInput.autocompleteStrings = DataManager.sharedInstance.musicalFormNames
        
        instrumentInput.text = file?.instrument
        instrumentInput.autocompleteStrings = DataManager.sharedInstance.instruments
        
        // naming preset
        selectedPreset = (file?.namingPresetID)!
        namingPickerView.selectRow(selectedPreset, inComponent: 0, animated: false)
        namingPickerView.reloadAllComponents()
    }
    
    /** 
        Updates the file's metadata from the entries of the inputfields
    */
    func updateMetadata(){
        
        writeInputsToFile(file,onFilenameChange: { (oldFilename: String, newFilename: String) in
            // TODO check for duplicate filename
            DataManager.sharedInstance.changeFilenameInDocumentsDirectory(oldFilename, newFilename: newFilename)
        })
        
        // TODO: Add unknown values to constants files evt.
        
        // Update metadata file
        DataManager.sharedInstance.writeMetadataFile()
        DataManager.sharedInstance.printMetaDataFile()
        //close
        dismiss()
    }
    
    /** Writes the entries of the inputfields into the file. */
    func writeInputsToFile(file: File?, onFilenameChange: ((oldFilename: String, newFilename: String) -> Void)?){
        
        let oldFilename = file?.filename
        file?.filename = filenameInput.text! + ".pdf"
        
        file?.title = titleInput.text!.trim()
        file?.composer = composerInput.text!.trim()
        file?.arranger = arrangerInput.text!.trim()
        // Try to parse opus and number to int, otherwise set nil
        if let opus = Int(opusInput.text!.trim()) {
            file?.opus = opus
        } else {
            file?.opus = -1
        }
        
        if let number = Int(numberInput.text!.trim()) {
            file?.number = number
        } else {
            file?.number = -1
        }
        
        file?.tempo = tempoInput.text!.trim()
        file?.key = keyInput.text!.trim()
        file?.musicalForm = musicalFormInput.text!.trim()
        file?.instrument = instrumentInput.text!.trim()
        
        file?.namingPresetID = selectedPreset
        
        // TODO: Check if there was really a change
        file?.status = File.STATUS.CHANGED
        
        if let onFilenameChange = onFilenameChange {
            if oldFilename != file?.filename {
                print("filename changed")
                onFilenameChange(oldFilename: oldFilename!,newFilename: (file?.filename)!)
            }
        }
    }
    
    @IBAction func filenameInputChanged(){

        let filename = filenameInput.text
        
        if filename?.trim() == "" {
            saveButton.enabled = false
            alreadyExistsLabel.hidden = false
            alreadyExistsLabel.text = "Filename required"
            return
        }
        // check if the filename already exists
        if NamingManager.sharedInstance.filenameAlreadyExists(filename!)
            && filename != file?.filename.stringByDeletingPathExtension() {
            
            saveButton.enabled = false
            alreadyExistsLabel.hidden = false
            alreadyExistsLabel.text = "Alredy exists!"
        } else {
            saveButton.enabled = true
            alreadyExistsLabel.hidden = true
        }
    }
    
    func dismiss(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: PickerView Delegate & DataSource methods
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return NamingManager.sharedInstance.presetsToDisplay!.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return NamingManager.sharedInstance.presetsToDisplay![row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        selectedPreset = row
        
        if row == 0 {
            filenameInput.text = file?.filename.stringByDeletingPathExtension()
        } else {
            let filenamePickerFile = File(filename: file!.filename)
            writeInputsToFile(filenamePickerFile,onFilenameChange: nil)
            let filename = NamingManager.sharedInstance.generateFilenameFromPreset(filenamePickerFile,
                                                                                   preset: NamingManager.sharedInstance.presets![row])
            filenameInput.text = filename
            
            filenameInputChanged()
        }
    }
    
}
