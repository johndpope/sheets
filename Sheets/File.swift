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
    
    var status = STATUS.NEW
    
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
    var filename = "DefaultFile.pdf"
    
    var thumbnail: UIImage?
    
    /** Specifies whether the file is currently being downloaded from the Google Drive. */
    var isDownloading = false
    
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
        let date = Date()
        saveDateAsString(date)
        
        guessMetadataFromFilename()
    }
    
    /**
        Saves the Date as a String.
     
        - Parameter date: the date to be saved
    */
    func saveDateAsString(_ date: Date){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyy(HH:mm:ss)"
        self.dateOfCreation = dateFormatter.string(from: date)
    }
    
    /** 
        Guesses the file metadata from potential information in the filename.
    */
    func guessMetadataFromFilename() {
        let dataManager = DataManager.sharedInstance
        let lowerFilename = filename.lowercased()
        
        if self.composer == "" {
            // Guess the composer
            for comp in dataManager.composerNames! {
                
                if lowerFilename.contains(comp.lowercased()) {
                    self.composer = comp
                    break
                }
            }
        
            // if full composer name not in title try with just last names
            if composer == "" {
                for comp in dataManager.composerNames! {
                
                    if lowerFilename.contains(comp.components(separatedBy: " ").last!.lowercased()) {
                        self.composer = comp
                        break
                    }
                }
            }
        }
        
        if self.musicalForm == "" {
            
            // Guess the musical form
            for mForm in dataManager.musicalFormNames! {
                if lowerFilename.contains(mForm.lowercased()) {
                    self.musicalForm = mForm
                    break
                }
            }
        }
        
        if self.tempo == "" {
            
            // Guess the tempo
            for temp in dataManager.tempoNames! {
                if lowerFilename.contains(temp.lowercased()) {
                    self.tempo = temp
                    break
                }
            }
        }
        
        if self.key == "" {
            // Guess the key
            for currentKey in dataManager.keys! {
                if lowerFilename.contains(currentKey.lowercased()) {
                    self.key = currentKey
                    break
                }
            }
        }
        
        if self.instrument == "" {
            // Guess the instrument
            for instrument in dataManager.instruments! {
                if lowerFilename.contains(instrument.lowercased()) {
                    // make sure it didn't interpret sharp as "harp"
                    if !lowerFilename.contains("sharp") {
                        self.instrument = instrument
                        break
                    }
                }
            }
        }
        
        // if instrument couldn't be guessed, choose default instrument if it exists
        if let defaultInstrument = dataManager.userDefaults.value(forKey: "defaultInstrument") {
            self.instrument = defaultInstrument as! String
        }
        
        if self.opus == -1 {
            // Guess Opus
            // try between 1 and 6 digits
            var results = dataManager.matchesForRegexInText("op.[0-9]{1,6}", text: lowerFilename)
            results.sort { $0.characters.count > $1.characters.count }
            // check if something was found at all
            if var opusResult = results.first {
                
                let index = opusResult.characters.index(opusResult.startIndex, offsetBy: 3)
                opusResult = opusResult.substring(from: index)
                // try to convert it to a number
                if let opNum = Int(opusResult) {
                    self.opus = opNum
                }
            }
        }
        
        if self.number == -1 {
            // Guess Number
            var results = dataManager.matchesForRegexInText("no.[0-9]{1,6}", text: lowerFilename)
            results.sort { $0.characters.count > $1.characters.count }
            // check if something was found at all
            if var numberResult = results.first {
                
                let index = numberResult.characters.index(numberResult.startIndex, offsetBy: 3)
                numberResult = numberResult.substring(from: index)
                // try to convert it to a number
                if let num = Int(numberResult) {
                    self.number = num
                }
            }
        }
        
    }
    
    func getUrl() -> URL {
        return DataManager.sharedInstance.createDocumentURLFromFilename(filename)
    }
    
    func getFilterString() -> String {
        return "\(filename) \(composer) \(musicalForm) \(tempo) \(key) \(instrument)\n".lowercased()
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
    func setupMetaDataFromString(_ data: String){
        let parts = data.components(separatedBy: "%")
        
        self.status = STATUS(rawValue: parts[0])!
        
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












