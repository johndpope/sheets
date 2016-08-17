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
    
    /** The name of the piece (not the filename) */
    var title = " "
    
    var composer = " "
    var arranger = " "
    
    var opus: Int?
    var number: Int?
    
    var musicalForm = " "
    var tempo: Tempo?
    var key = " "
    
    var instrument = " "
    /** Refers to the file, not the piece. (Time when the document was first added). Format: dd-MM-yyy(HH:mm:ss) */
    var dateOfCreation = " "
    /** ID of the naming preset used in order to determine the filename for this file */
    var namingPresetID: Int?
    /** The file identifier for the file on Google Drive */
    var fileID = " "
    
    /** The url of the file in the local documents directory */
    var url: NSURL!
    
    /**
        Creates a file object from a metadata String `data`.
        
        - Parameter data: The string containing the metadata for the file
    */
    init(data: String){
        setupMetaDataFromString(data)
    }
    
    /**
        Creates a file object from its local URL.
        
        - Parameter url: The url pointing to the file in the local Documents directory
    */
    init(url: NSURL){
        self.url = url
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
    
    /**
        Returns the filename of the PDF document.
     
        - Returns: the filename
    */
    func getFileName() -> String {
        let filename = url.lastPathComponent!
        
        return filename
    }
    
    /** 
        Returns the metadata as a string.
        Used to save the metadata to a file.
        
        Form:
        title % composer % arranger % opus % number % musicalForm % tempo % key % instrument % dateOfCreation
        % namingPresetID % fileID % url
     
        - Returns: Metadata as a string
    */
    func getDataAsString() -> String {
        let data = "\(title)%\(composer)%\(arranger)%\(opus)%\(number)%\(musicalForm)%\(tempo)%\(key)%\(instrument)%\(dateOfCreation)%\(namingPresetID)%\(fileID)%\(url.path!)\n"
        return data
    }
    
    
    /**
        Parses a String with the form defined in getDataAsString into the metadata attributes.
     
        - Parameter data: The metadata string in the following form: 
            title % composer % arranger % opus % number % musicalForm % tempo % key % instrument % dateOfCreation % namingPresetID % fileID % url
    */
    func setupMetaDataFromString(data: String){
        let parts = data.componentsSeparatedByString("%")
        
        self.title = parts[0]
        self.composer = parts[1]
        self.arranger = parts[2]
        self.opus = Int(parts[3])
        self.number = Int(parts[4])
        self.musicalForm = parts[5]
        self.tempo = Tempo(rawValue: parts[6])
        self.key = parts[7]
        self.instrument = parts[8]
        self.dateOfCreation = parts[9]
        self.namingPresetID = Int(parts[10])
        self.fileID = parts[11]
        self.url = NSURL(fileURLWithPath: parts[12])
    }
    
    
}













