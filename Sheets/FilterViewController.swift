//
//  FilterViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 14.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

protocol FilterViewDelegate {
    func filterPicked(_ filter: String)
}

class FilterViewController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate,
                             AutocompleteUITextFieldDelegate {
    
    @IBOutlet var pickerView: UIPickerView!
    var filterOptions = ["All","Composer","Musical Form","Tempo","Key","Instrument"]
    var filterDict = Dictionary<String,[String]>()
    
    @IBOutlet var textField: AutocompleteUITextField!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var currentFilterLabel: UILabel!
    
    var delegate: FilterViewDelegate?
    
    var preferredSize = CGSize(width: 400,height: 450)

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        tableView.delegate = self
        
        textField.autoCompDelegate = self
        currentFilterLabel.text = DataManager.sharedInstance.currentFilter
        
        textField.autocompleteStrings = filterDict[filterOptions[0]]
    }
    
    func setup() {
        
        let dataManager = DataManager.sharedInstance
        self.preferredContentSize = preferredSize
    
        let composerNames = dataManager.composerNames
        let musicalForms = dataManager.musicalFormNames
        let tempos = dataManager.tempoNames
        let keys = dataManager.keys
        let instruments = dataManager.instruments
        
        filterDict["Composer"] = composerNames
        filterDict["Musical Form"] = musicalForms
        filterDict["Tempo"] = tempos
        filterDict["Key"] = keys
        filterDict["Instrument"] = instruments
        
        var allCompletions = composerNames
        allCompletions?.append(contentsOf: musicalForms!)
        allCompletions?.append(contentsOf: tempos!)
        allCompletions?.append(contentsOf: keys!)
        allCompletions?.append(contentsOf: instruments!)
        
        filterDict["All"] = allCompletions
    }
    
    // MARK: UIPickerView Delegate and Datasource methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filterOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filterOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Set the correct autocomplete strings array for the textField
        if row == 0 {
            tableViewSelectedRow(filterOptions[0])
        }
        
        textField.autocompleteStrings = filterDict[filterOptions[row]]
        tableView.delegate = self
    }
    
    // Mark: UITableView action target
    func tableViewSelectedRow(_ entry: String) {
        // Only insert if not "all"
        if entry != "All" {
            textField.text = entry
        }
        
        currentFilterLabel.text = entry
        DataManager.sharedInstance.currentFilter = entry
        delegate?.filterPicked(entry)
    }
}




