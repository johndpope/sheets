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
    
    enum STATUS : String {
        case NEW = "NEW"
        case SYNCED = "SYNCED"
        case CHANGED = "CHANGED"
        case DELETED = "DELETED"
    }
    
    var status: STATUS!
    
    /** The name of the piece (not the filename) */
    var title = ""
    
    var composer = ""
    var arranger = ""
    
    var opus = -1
    var number = -1
    
    var musicalForm = ""
    var tempo = ""
    var key = ""
    
    var instrument = ""
    /** Refers to the file, not the piece. (Time when the document was first added). Format: dd-MM-yyy(HH:mm:ss) */
    var dateOfCreation = ""
    /** ID of the naming preset used in order to determine the filename for this file */
    var namingPresetID = 0
    /** The file identifier for the file on Google Drive */
    var fileID = " "
    
    /** The filename of the file in the local documents directory */
    var filename: String!
    
    var thumbnail: UIImage?
    
    /**
        Creates a file object from a metadata String `data`.
        
        - Parameter data: The string containing the metadata for the file
    */
    init(data: String){
        setupMetaDataFromString(data)
    }
    
    /**
        Creates a file object from its local URL. Status is set to NEW by default.
        
        - Parameter url: The url pointing to the file in the local Documents directory
    */
    init(filename: String){
        self.filename = filename
        self.status = STATUS.NEW
        let date = NSDate()
        saveDateAsString(date)
        
        guessMetadataFromFilename()
    }
    
    /**
        Saves the Date as a String.
     
        - Parameter date: the date to be saved
    */
    func saveDateAsString(date: NSDate){
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyy(HH:mm:ss)"
        self.dateOfCreation = dateFormatter.stringFromDate(date)
    }
    
    /** 
        Guesses the file metadata from potential information in the filename.
    */
    func guessMetadataFromFilename() {
        let dataManager = DataManager.sharedInstance
        let lowerFilename = filename.lowercaseString
        // Guess the composer
        for comp in dataManager.composerNames! {
            
            if lowerFilename.containsString(comp.lowercaseString) {
                self.composer = comp
                break
            }
        }
        
        // if full composer name not in title try with just last names
        if composer == "" {
            for comp in dataManager.composerNames! {
                
                if lowerFilename.containsString(comp.componentsSeparatedByString(" ").last!.lowercaseString) {
                    self.composer = comp
                    break
                }
            }
        }
        
        // Guess the musical form
        for mForm in dataManager.musicalFormNames! {
            if lowerFilename.containsString(mForm.lowercaseString) {
                self.musicalForm = mForm
                break
            }
        }
        
        // Guess the tempo
        for temp in dataManager.tempoNames! {
            if lowerFilename.containsString(temp.lowercaseString) {
                self.tempo = temp
                break
            }
        }
        
        // Guess the key
        for currentKey in dataManager.keys! {
            if lowerFilename.containsString(currentKey.lowercaseString) {
                self.key = currentKey
                break
            }
        }
        
        // Guess the instrument
        for instrument in dataManager.instruments! {
            if lowerFilename.containsString(instrument.lowercaseString) {
                // make sure it didn't interpret sharp as "harp"
                if !lowerFilename.containsString("sharp") {
                    self.instrument = instrument
                    break
                }
            }
        }
        
        // if instrument couldn't be guessed, choose default instrument if it exists
        if let defaultInstrument = dataManager.userDefaults.valueForKey("defaultInstrument") {
            self.instrument = defaultInstrument as! String
        }
        
        // Guess Opus
        // try between 1 and 6 digits
        var results = dataManager.matchesForRegexInText("op.[0-9]{1,6}", text: lowerFilename)
        results.sortInPlace { $0.characters.count > $1.characters.count }
        // check if something was found at all
        if var opusResult = results.first {
            
            let index = opusResult.startIndex.advancedBy(3)
            opusResult = opusResult.substringFromIndex(index)
            // try to convert it to a number
            if let opNum = Int(opusResult) {
                self.opus = opNum
            }
        }
        
        // Guess Number
        results = dataManager.matchesForRegexInText("no.[0-9]{1,6}", text: lowerFilename)
        results.sortInPlace { $0.characters.count > $1.characters.count }
        // check if something was found at all
        if var numberResult = results.first {
            
            let index = numberResult.startIndex.advancedBy(3)
            numberResult = numberResult.substringFromIndex(index)
            // try to convert it to a number
            if let num = Int(numberResult) {
                self.number = num
            }
        }
    }
    
    func getUrl() -> NSURL {
        return DataManager.sharedInstance.createDocumentURLFromFilename(filename)
    }
    
    func getFilterString() -> String {
        return "\(filename) \(composer) \(musicalForm) \(tempo) \(key) \(instrument)\n".lowercaseString
    }
    
    /** 
        Returns the metadata as a string.
        Used to save the metadata to a file.
        
        Form:
        status % title % composer % arranger % opus % number % musicalForm % tempo % key % instrument % dateOfCreation
        % namingPresetID % fileID % url
     
        - Returns: Metadata as a string
    */
    func getDataAsString() -> String {
        let data = "\(status)%\(title)%\(composer)%\(arranger)%\(opus)%\(number)%\(musicalForm)%\(tempo)%\(key)%\(instrument)%\(dateOfCreation)%\(namingPresetID)%\(fileID)%\(filename)\n"
        return data
    }
    
    
    /**
        Parses a String with the form defined in getDataAsString into the metadata attributes.
     
        - Parameter data: The metadata string in the following form: 
            title % composer % arranger % opus % number % musicalForm % tempo % key % instrument % dateOfCreation % namingPresetID % fileID % url
    */
    func setupMetaDataFromString(data: String){
        let parts = data.componentsSeparatedByString("%")
        
        self.status = STATUS(rawValue: parts[0])
        
        self.title = parts[1]
        self.composer = parts[2]
        self.arranger = parts[3]
        self.opus = Int(parts[4])!
        self.number = Int(parts[5])!
        self.musicalForm = parts[6]
        self.tempo = parts[7]
        self.key = parts[8]
        self.instrument = parts[9]
        self.dateOfCreation = parts[10]
        self.namingPresetID = Int(parts[11])!
        self.fileID = parts[12]
        self.filename = parts[13]
    }
}

extension File : Equatable {}

func ==(lhs: File, rhs: File) -> Bool {
    return lhs.getDataAsString() == rhs.getDataAsString()
}












