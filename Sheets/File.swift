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
    var title = " "
    
    var composer = " "
    var arranger = " "
    
    var opus: Int?
    var number: Int?
    
    var musicalForm = " "
    var tempo = " "
    var key = " "
    
    var instrument = " "
    /** Refers to the file, not the piece. (Time when the document was first added). Format: dd-MM-yyy(HH:mm:ss) */
    var dateOfCreation = " "
    /** ID of the naming preset used in order to determine the filename for this file */
    var namingPresetID: Int?
    /** The file identifier for the file on Google Drive */
    var fileID = " "
    
    /** The filename of the file in the local documents directory */
    var filename: String!
    
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
        Generates the filename from the naming preset attached to this file.
     
        - Returns: the generated filename
    */
    func generateFileNameFromPreset() -> String {
        
        let filename = "\(composer) - \(title) Op.\(opus) Nr.\(number)"
        
        return filename
    }
    
    func getUrl() -> NSURL {
        return DataManager.sharedInstance.createDocumentURLFromFilename(filename)
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
        self.opus = Int(parts[4])
        self.number = Int(parts[5])
        self.musicalForm = parts[6]
        self.tempo = parts[7]
        self.key = parts[8]
        self.instrument = parts[9]
        self.dateOfCreation = parts[10]
        self.namingPresetID = Int(parts[11])
        self.fileID = parts[12]
        self.filename = parts[13]
    }
    
    
}













