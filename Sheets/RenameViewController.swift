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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.preferredContentSize = CGSize(width: 700, height: 580)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.preferredContentSize = CGSize(width: 700, height: 580)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UIBarButtonItems
        saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(updateMetadata))
        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissSelf))
        
        // Setup UIPickerView
        self.namingPickerView.delegate = self
        self.namingPickerView.dataSource = self
        
        filenameInput.addTarget(self, action: #selector(filenameInputChanged), for: .editingChanged)
        
        NamingManager.sharedInstance.loadPresets()
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        
        alreadyExistsLabel.isHidden = true
        
        titleInput.text = file?.title
        
        composerInput.text = file?.composer
        composerInput.autocompleteStrings = DataManager.sharedInstance.composerNames
        
        arrangerInput.text = file?.arranger
        arrangerInput.autocompleteStrings = DataManager.sharedInstance.composerNames
        
        if let opus = file?.opus , opus != -1 {
            opusInput.text = String(opus)
        } else {
            opusInput.text = ""
            
        }
        
        if let number = file?.number , number != -1{
            numberInput.text = String(number)
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
            // if filename couldn't be changed keep the old filename
            if !DataManager.sharedInstance.changeFilenameInDocumentsDirectory(oldFilename, newFilename: newFilename) {
                print("Filename changed back.")
                self.file?.filename = oldFilename
            }
        })
        
        // TODO: Add unknown values to constants files
        
        // Update metadata file
        DataManager.sharedInstance.writeMetadataFile()
        DataManager.sharedInstance.printMetaDataFile()
        //close
        dismissSelf()
    }
    
    /** Writes the entries of the inputfields into the file. */
    func writeInputsToFile(_ file: File?, onFilenameChange: ((_ oldFilename: String, _ newFilename: String) -> Void)?){
        
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
                onFilenameChange(oldFilename!,(file?.filename)!)
            }
        }
    }
    
    @IBAction func filenameInputChanged(){

        let filename = filenameInput.text
        
        if filename?.trim() == "" {
            saveButton.isEnabled = false
            alreadyExistsLabel.isHidden = false
            alreadyExistsLabel.text = "Filename required"
            return
        }
        // check if the filename already exists
        if NamingManager.sharedInstance.filenameAlreadyExists(filename!)
            && filename != file?.filename.stringByDeletingPathExtension() {
            
            saveButton.isEnabled = false
            alreadyExistsLabel.isHidden = false
            alreadyExistsLabel.text = "Alredy exists!"
        } else {
            saveButton.isEnabled = true
            alreadyExistsLabel.isHidden = true
        }
    }
    
    
    func dismissSelf(){
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: PickerView Delegate & DataSource methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return NamingManager.sharedInstance.presetsToDisplay!.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return NamingManager.sharedInstance.presetsToDisplay![row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
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
