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
    func tableViewSelectedRow(_ entry: String)
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
        
        self.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    
    func setupTableView() {
        if let tableView = suggestionsTableView {
            setupTableView(tableView)
        } else {
            fatalError("The autocomplete UITableView is not set.")
        }
    }
    
    func setupTableView(_ tableView: UITableView){
        
        tableView.rowHeight = tableViewRowHeight
        
        tableView.delegate = self
        tableView.dataSource = self
        
        suggestionsTableView?.isHidden = true
    }
    
    func findSuggestions(_ text: String) {
        
        // trim the string
        let text = text.trim()
        
        suggestions = [String]()
        
        let textLower = text.lowercased()
        
        if let allStrings = autocompleteStrings {
            
            for string in allStrings{
                if string.lowercased().contains(textLower) {
                    suggestions?.append(string)
                }
            }
        }
    }
    
    @objc func textDidChange(_ textField: UITextField){
        
        suggestionsTableView?.delegate = self
        suggestionsTableView?.dataSource = self
        
        findSuggestions(textField.text!)
        
        suggestionsTableView?.reloadData()
        
        if textField.text == "" {
            suggestionsTableView?.isHidden = true
        } else {
            suggestionsTableView?.isHidden = false
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return number of table view cells
        if let count = suggestions?.count {
            return count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Selected a cell
        let cell = suggestionsTableView?.cellForRow(at: indexPath)
        self.text = cell?.textLabel?.text
        suggestionsTableView?.isHidden = true
        suggestionsTableView?.reloadData()
        
        autoCompDelegate?.tableViewSelectedRow(text!)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        if let strings = suggestions {
            cell.textLabel?.text = strings[(indexPath as NSIndexPath).row]
        } else {
            cell.textLabel?.text = ""
        }
        
        return cell
    }
}
