//
//  File.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 04.07.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import UIKit

class File {
    
    //metadata
    var title = " "
    var composer = " "
    var arranger = " "
    var opus: Int?
    var number: Int?
    var musicalForm = " "
    var tempo: Tempo?
    
    var url: NSURL!
    
    init(data: String){
        setupMetaDataFromString(data)
    }
    
    init(url: NSURL, dict: Dictionary<String,AnyObject?>?){
        self.url = url
        
        if dict != nil {
            setupMetaDataFromDict(dict!)
        }
        
    }
    
    init(url: NSURL,title: String, dict: Dictionary<String,AnyObject?>?){
        self.url = url
        if dict != nil {
            setupMetaDataFromDict(dict!)
        }
        self.title = title
    }
    
    func setupMetaDataFromDict(dict: Dictionary<String, AnyObject?>){
        
        if let titre = dict["title"] {
            self.title = titre as! String
        }
        
        if let comp = dict["composer"] {
            self.composer = comp as! String
        }
        
        if let op = dict["opus"] {
            self.opus = op as? Int
        }
        
        if let num = dict["number"] {
            self.number = num as? Int
        }
        
        if let form = dict["musicalForm"] {
            self.musicalForm = form as! String
        }
        
        if let temp = dict["tempo"] {
            self.tempo = temp as? Tempo
        }
    }
    
    func getFileNameAsString() -> String {
        
        let filename = "\(composer) - \(title) Op.\(opus) Nr.\(number)"
        
        return filename
    }
    
    //used to save the Data to a file. Form:
    // title % composer % opus % number % musicalForm % tempo % url
    func getDataAsString() -> String {
        let data = "\(title)%\(composer)%\(opus)%\(number)%\(musicalForm)%\(tempo)%\(url.path)\n"
        return data
    }
    
    //parses a String with the form defined in getDataAsString into the metadata attributes
    func setupMetaDataFromString(data: String){
        let parts = data.componentsSeparatedByString("%")
        
        self.title = parts[0]
        self.composer = parts[1]
        self.opus = Int(parts[2])
        self.number = Int(parts[3])
        self.musicalForm = parts[4]
        self.tempo = Tempo(rawValue: parts[5])
        self.url = NSURL(fileURLWithPath: parts[6])
    }
    
    
}