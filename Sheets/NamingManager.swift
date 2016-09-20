//
//  NamingManager.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 01.09.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

/** 
    The NamingManager provides naming functionality such as generating a filename from
    a File object and a naming preset string.
    It also makes sure that filenames don't occur multiple times locally and creates a new filename
*/
class NamingManager {
    
    static let sharedInstance = NamingManager()
    
    var namingPresetsFilename = "NamingPresets"
    var presets : [String]?
    var presetsToDisplay : [String]?
    
    init(){
        loadPresets()
    }
    
    func loadPresets() {
        presets = DataManager.sharedInstance.arrayFromContentsOfFileWithName(namingPresetsFilename)
        presetsToDisplay = [String]()
        // prepare the presets to make them readable
        if let presets = presets {
            for preset in presets {
                presetsToDisplay?.append(presetForDisplay(preset))
            }
        }
    }
    
    /** Generates a filename based on the preset string and the metadata of the file. */
    func generateFilenameFromPreset(_ file: File, preset: String) -> String {
        // split the preset string
        let parts = preset.components(separatedBy: "%")
        let namingDict = generateNamingDictionary(file)
        var filename = ""
        
        for (index,part) in parts.enumerated() {
            if index != 0 {
                if namingDict[part] != "" {
                    filename += " "
                }
            }
            filename += namingDict[part]!
        }
        
        return filename
    }
    
    /** Returns true if the filename already exists in the local documents directory. */
    func filenameAlreadyExists(_ filename: String) -> Bool {
        
        return filenameAlreadyExistsInArray(DataManager.sharedInstance.allFiles, filename: filename)
    }
    
    /** Returns true if the filename already exists in the array of file objects. */
    func filenameAlreadyExistsInArray(_ files: [File]?, filename: String) -> Bool {
        let filename = filename + ".pdf"
        
        if let files = files {
            
            for file in files {
                if file.status != File.STATUS.DELETED && file.filename == filename {
                    return true
                }
            }
        }
        
        return false
    }
    
    func generateNamingDictionary(_ file: File) -> Dictionary<String,String> {
        
        var dict = Dictionary<String,String>()
        dict["Composer"] = file.composer.components(separatedBy: " ").last
        dict["Composer (full name)"] = file.composer
        dict["Title"] = file.title
        dict["Arranger"] = file.arranger
        dict["Musical Form"] = file.musicalForm
        dict["Op."] = file.opus == -1 ? "" : "Op.\(file.opus)"
        dict["No."] = file.number == -1 ? "" : "No.\(file.number)"
        dict["Key"] = file.key
        
        dict["/"] = "/"
        dict["-"] = "-"
        
        return dict
    }
    
    /** 
        Takes a preset string from the file and returns it in a presentable form.
        The % signs are replaced by whitespaces.
    */
    func presetForDisplay(_ preset: String) -> String {
        return preset.replacingOccurrences(of: "%", with: " ")
    }
    
    
    
}
