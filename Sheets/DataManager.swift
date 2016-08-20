//
//  DataManager.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 17.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import GoogleAPIClient
import GTMOAuth2
import Foundation

/**
 This class is responsible for keeping all of the data available to the ViewControllers.
 It has access to all of the .txt files that contain the metadata information,
 the filename changes that need to be synced, deleted files that need to be synced,
 the Constants that will be needed for autocomplete like Tempo, Composers, MusicalForms...
 
 Through the NamingPresetManager the DataManager has access to all of the NamingPresets as well.
 
 It is also responsible for synchronizing the files between Google Drive and the app.
 
 */

protocol FolderSearchDelegate {
    func folderSearchFinished(found: Bool)
}


class DataManager : FolderSearchDelegate {
    
    static let sharedInstance = DataManager()
    
    private let metadataFilename = "Metadata.txt"
    private let filenameChangesFilename = "FilenameChanges.txt"
    private let fileDeletionsFilename = "Deletions.txt"
    
    private let tempoFilename = "Tempo.txt"
    private let composersFilename = "Composers.txt"
    private let musicalFormsFilename = "MusicalForms.txt"
    
    // Google Drive variables
    let kKeychainItemName = "Drive API"
    let kClientID = "451075181287-raoeoh0i74mq51vqv9tk6dhgi9qs26q7.apps.googleusercontent.com"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    let scopes = [kGTLAuthScopeDrive]
    
    let service = GTLServiceDrive()
    
    var mainFolderName: String!
    var mainFolderID: String?
    
    private var downloadedDriveFiles = [GTLDriveFile]()
    var completeDownloadSize : CGFloat = 0    // in bytes
    var currentDownloadProgress : CGFloat = 1
    
    let userDefaults = NSUserDefaults()
    
    var semaphor: dispatch_semaphore_t
    
    
    /** Contains the File objects of all of the local files */
    var files: [File]!
    var currentFile: File!
    
    var composerNames: [String]!
    var tempoNames: [String]!
    var musicalFormNames: [String]!
    
    init(){
        semaphor = dispatch_semaphore_create(0)
        
        generalSetup()
    }
    
    func generalSetup() {
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(
            kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
            service.authorizer = auth
        }
        
        mainFolderID = userDefaults.valueForKey("mainFolderID") as? String
        mainFolderName = userDefaults.valueForKey("mainFolderName") as? String
        
        files = [File]()
        
        loadData()
    }
    
    /**
        Loads all of the data form the text files and sets up the data arrays and variables.
        Loads files, composerNames, musicalFormNames
    */
    func loadData(){
        loadLocalFiles()
    }
    
    /**
        Loads / creates all of the File objects from the entries of the metadata.txt file and 
        stores them in the files array.
    */
    func loadLocalFiles(){
        //create File objects from Metadata file
        let metadataFilePath = createDocumentURLFromFilename(metadataFilename)
        
        if NSFileManager.defaultManager().fileExistsAtPath(metadataFilePath.path!) {   // metadata file exists
            do {
                let fileContent = try String(contentsOfFile: metadataFilePath.path!, encoding: NSUTF8StringEncoding)
                
                let lines = fileContent.componentsSeparatedByString("\n")
                for line in lines {
                    if line != "" {
                        let file = File(data: line)
                        files.append(file)
                    }
                }
                
            } catch {
                print("Error! Could not read from metadata file")
                fatalError()
            }
        }
    }
    
    
    
    /*  Google Drive Sync  */
    
    
    /**
        Syncs alls of the sheet (pdf) files and metadata files with the specified folder in Google Drive
    */
    func sync(){
    
    }
    
    /** Disables the Google Drive sync functionality. */
    func disableSync(){
    
    }
    
    
    /** 
        Fetches all PDF files in the main Google Drive folder
    */
    func fetchFilesInFolder(){
        print("Downloading sheets from \(mainFolderName)")
        let query = GTLQueryDrive.queryForFilesList()
        
        if let folderID = mainFolderID {
            query.q = "\'\(folderID)\' in parents and (mimeType = \'application/pdf\')"
            
            service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, response: AnyObject!, error: NSError?) in
                
                if let error = error {
                    print("Error while fetching files in folder: \(error.localizedDescription)")
                    fatalError()
                }
                
                // Store the downloaded Google Drive Files from the response to the device
                if let files = response.files where (files != nil && !files.isEmpty) {
                    for file in response.files {
                        self.downloadedDriveFiles.append(file as! GTLDriveFile)
                    }
                
                    // Download the drive files to the local documents directory
                    for file in self.downloadedDriveFiles {
                        self.downloadFile(file)
                    }
                }
                
            })
            
        }else{
            print("folderID not known")
            saveFolderID()
        }
    }
    
    /**
        Donwloads the data of a GTLDriveFile from Google Drive and stores them to the documents directory.
    */
    func downloadFile(file: GTLDriveFile){
        print("Downloading")
        let url = "https://www.googleapis.com/drive/v3/files/\(file.identifier)?alt=media"
        
        let fetcher = service.fetcherService.fetcherWithURLString(url)
        
        fetcher.beginFetchWithCompletionHandler({ (data: NSData?, error: NSError?) in
            
            if let error = error {
                print("Error \(error.localizedDescription)")
                fatalError()
            }
            
            if let data = data {
                self.saveFileToDocumentsDirectory(data,file: file)
        
                print("Finished Download")
            }
        })
        
        fetcher.receivedProgressBlock = { (bytes_Written: __int64_t, totalBytesWritten: __int64_t) in
            self.currentDownloadProgress = (CGFloat(totalBytesWritten) * 100)/self.completeDownloadSize
        }
        
    }
    
    /** 
        Saves the data of the downloaded file in the Documents directory.
     
        - Returns: The file object associated with the GTLDriveFile.
    */
    func saveFileToDocumentsDirectory(data: NSData,file: GTLDriveFile) -> File {
        let writePath = createDocumentURLFromFilename(file.name)
        
        let file = createAndAddFileObject(writePath, fileID: file.identifier)
        data.writeToFile(file.url.path!, atomically: true)
        
        return file
    }
    
    func saveFileToDocumentsDirectory(data: NSData, filename: String) -> File {
        let writePath = createDocumentURLFromFilename(filename)
        
        let file = createAndAddFileObject(writePath)
        data.writeToFile(file.url.path!, atomically: true)
        
        return file
    }
    
    /** 
        Creates and returns a File object with the specified url and fileID. The file is added to the files 
        list and the metadata file, if it didn't exist before.
     
        - Returns: The created File object.
    */
    func createAndAddFileObject(url: NSURL, fileID: String = "") -> File {
        // let file = File(url: url, title: title, dict: nil)
        let file = File(url: url)
        file.fileID = fileID
        
        //append file data to metadata file and file list
        //first check to see if it already exists or not
        let dataString = file.getFileName()
        
        for document in files {
            if document.getFileName() == dataString {
                print("File already exists in metadata and/or loaded files")
                return document
            }
        }
        
        updateMetadataFile(file)
        files.append(file)
        return file
    }
    
    /**
        Appends the data of file to the end of the Metadata.txt file.
    */
    func updateMetadataFile(file: File){
        let metadataFileUrl = createDocumentURLFromFilename(metadataFilename)
        
        let dataAsString = file.getDataAsString()
        let data = dataAsString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        if NSFileManager.defaultManager().fileExistsAtPath(metadataFileUrl.path!) {
            do {
                let fileHandle = try NSFileHandle(forWritingToURL: metadataFileUrl)
                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }catch{
                print("Can't open fileHandler")
                fatalError()
            }
        }else{
            //File doesn't exist
            do{
                try data.writeToURL(metadataFileUrl, options: .DataWritingAtomic)
            }catch{
                print("Couldn't create and write to file")
                fatalError()
            }
            
        }
    }
    
    /** 
        Resets the Metadata.txt file to an empty file without metadata entries.
    */
    func resetMetaDataFile(){
        let metadataFileUrl = createDocumentURLFromFilename(metadataFilename)
        
        do {
            try "".writeToURL(metadataFileUrl, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            print("Couldn't reset metadata file")
        }
        
    }
    
    /** 
        Prints the contents of the Metadata.txt file to the console.
    */
    func printMetaDataFile(){
        let mFilePath = createDocumentURLFromFilename(metadataFilename)
        
        if NSFileManager.defaultManager().fileExistsAtPath(mFilePath.path!) {
            do {
                let fileContent = try String(contentsOfFile: mFilePath.path!, encoding: NSUTF8StringEncoding)
                
                let lines = fileContent.componentsSeparatedByString("\n")
                for line in lines {
                    print(line)
                }
                
            } catch {
                print("Error! Could not read from metadata file")
            }
        } else {
            print("Metadata file does not exist.")
        }
    }
    
    /**
     Searches for the main Sheet Folder in Google Drive.
     */
    func searchForFolder(delegate: FolderSearchDelegate, foldername: String) {
        
        service.shouldFetchNextPages = true
        
        let query = GTLQueryDrive.queryForFilesList()
        query.q = "name = \'\(foldername)\'"
        
        service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, response: AnyObject!, error: NSError?) in
            
            if let error = error {
                print("Error \(error.localizedDescription)")
                fatalError()
            }
            
            if let files = response.files where (files != nil && !files.isEmpty) {
                //folder was found -> save folder iD
                let file = files[0] as! GTLDriveFile
                self.mainFolderName = foldername
                self.mainFolderID = file.identifier
                self.userDefaults.setValue(self.mainFolderName!, forKey: "mainFolderName")
                self.userDefaults.setValue(self.mainFolderID!, forKey: "mainFolderID")
                
                delegate.folderSearchFinished(true)
                
            } else {
                delegate.folderSearchFinished(false)
            }
            
        })
    }
    
    func saveFolderID(){
        searchForFolder(self, foldername: mainFolderName!)
    }
    
    func folderSearchFinished(found: Bool) {
        // Do something with the result of the folder search
    }
    
    /** 
        Create an empty folder in Google Drive
    */
    func createSheetFolder(foldername: String) {
        
        let folder = GTLDriveFile()
        folder.name = foldername
        folder.mimeType = "application/vnd.google-apps.folder"
        
        let query = GTLQueryDrive.queryForFilesCreateWithObject(folder, uploadParameters: nil)
        
        service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, file: AnyObject!, error: NSError?) in
            if let error = error {
                print("Error \(error.localizedDescription)")
                fatalError()
            }
            
            print("Finished creating folder")
            self.mainFolderID = file.identifier
            self.mainFolderName = file.name
            self.userDefaults.setValue(self.mainFolderID!, forKey: "mainFolderID")
            self.userDefaults.setValue(self.mainFolderName, forKey: "mainFolderName")
        })
    }
    
    /** deletes all of the content of the Document Directory */
    func deleteDocumentsDirectory(){
        let fileManager = NSFileManager.defaultManager()
        let directoryURL = NSURL(fileURLWithPath: applicationDocumentDirectory())
        let enumerator = fileManager.enumeratorAtPath(applicationDocumentDirectory())
        while let file = enumerator?.nextObject() as? String {
            do {
                try fileManager.removeItemAtURL(directoryURL.URLByAppendingPathComponent(file))
            } catch {
                print("Could not remove \(file)")
            }
            
        }
    }
    
    func createDocumentURLFromFilename(filename: String) -> NSURL {
        return NSURL(fileURLWithPath: applicationDocumentDirectory()).URLByAppendingPathComponent(filename)
    }
    
    func listAllLocalFiles() -> String {
        var fileString = ""
        // Get the document directory url
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL( documentsUrl, includingPropertiesForKeys: nil, options: [])
            
            // filter out pdf files
            let files = directoryContents.filter{ $0.pathExtension == "pdf" }
            let fileNames = files.flatMap({$0.URLByDeletingPathExtension?.lastPathComponent})
            
            for filename in fileNames {
                fileString += filename + "\n"
            }
            
            return fileString
            
        } catch let error as NSError {
            print(error.localizedDescription)
            return ""
        }
    }
    
    
    
    
    /**
        Returns the path to the Documents Directory.
     
        - Returns: path to Documents Directory
    */
    func applicationDocumentDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    }
    
}











