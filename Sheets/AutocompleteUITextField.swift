//
//  AutocompleteUITextField.swift
//  AutocompleteUITextField
//
//  Created by Keiwan Donyagard on 31.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import UIKit

protocol AutocompleteUITextFieldDelegate {
    func tableViewSelectedRow(entry: String)
}

class AutocompleteUITextField : UITextField, UITableViewDelegate, UITableViewDataSource {
    
    /** The TableView containing the autocomplete suggestions. */
    @IBOutlet weak var suggestionsTableView : UITableView?
    /** The height of each TableView cell */
    var tableViewRowHeight : CGFloat = 50
    
    var autoCompDelegate: AutocompleteUITextFieldDelegate?
    
    /** The strings from which the suggestions are filtered. */
    var autocompleteStrings : [String]? {
        didSet{
            suggestionsTableView?.reloadData()
        }
    }
    
    var suggestions : [String]? {
        didSet{
            suggestionsTableView?.reloadData()
        }
    }
    
    var testStrings = ["adfh","bfdj","fhdjg","gjsfk","gjsfk","gjsfk","gjsfk","gjsfk","gjsfk","gjsfk","gjsfk"]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //initialize()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    
    func initialize() {
        
        suggestions = [String]()
        
        setupTableView()
        
        self.addTarget(self, action: #selector(textDidChange(_:)), forControlEvents: .EditingChanged)
    }
    
    func setupTableView() {
        if let tableView = suggestionsTableView {
            setupTableView(tableView)
        } else {
            fatalError("The autocomplete UITableView is not set.")
        }
    }
    
    func setupTableView(tableView: UITableView){
        
        tableView.rowHeight = tableViewRowHeight
        
        tableView.delegate = self
        tableView.dataSource = self
        
        suggestionsTableView?.hidden = true
    }
    
    func findSuggestions(text: String) {
        
        // trim the string
        let text = text.trim()
        
        suggestions = [String]()
        
        let textLower = text.lowercaseString
        
        if let allStrings = autocompleteStrings {
            
            for string in allStrings{
                if string.lowercaseString.containsString(textLower) {
                    suggestions?.append(string)
                }
            }
        }
    }
    
    @objc func textDidChange(textField: UITextField){
        
        suggestionsTableView?.delegate = self
        suggestionsTableView?.dataSource = self
        
        findSuggestions(textField.text!)
        
        suggestionsTableView?.reloadData()
        
        if textField.text == "" {
            suggestionsTableView?.hidden = true
        } else {
            suggestionsTableView?.hidden = false
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return number of table view cells
        if let count = suggestions?.count {
            return count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Selected a cell
        let cell = suggestionsTableView?.cellForRowAtIndexPath(indexPath)
        self.text = cell?.textLabel?.text
        suggestionsTableView?.hidden = true
        suggestionsTableView?.reloadData()
        
        autoCompDelegate?.tableViewSelectedRow(text!)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        if let strings = suggestions {
            cell.textLabel?.text = strings[indexPath.row]
        } else {
            cell.textLabel?.text = ""
        }
        
        return cell
    }
}