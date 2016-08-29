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
    private let remoteMetadataFilename = "RemoteMetadata.txt"
    
    private let tempoFilename = "Tempo"
    private let composersFilename = "Composers"
    private let musicalFormsFilename = "MusicalForms"
    
    // Google Drive variables
    let kKeychainItemName = "Drive API"
    let kClientID = "451075181287-dvcikapqk1qkontp8gfs6kohanp44h2t.apps.googleusercontent.com"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    let scopes = [kGTLAuthScopeDrive]
    
    let service = GTLServiceDrive()
    
    var syncEnabled: Bool!
    
    var mainFolderName: String!
    var mainFolderID: String?
    
    let metadataFolderName = "AppData - DO NOT EDIT"
    var metadataFolderID: String?
    
    private var downloadedDriveFiles = [GTLDriveFile]()
    var completeDownloadSize : CGFloat = 0    // in bytes
    var currentDownloadProgress : CGFloat = 1
    
    private var syncProgress = Dictionary<GTMSessionFetcher,(CGFloat,CGFloat)>()
    
    let userDefaults = NSUserDefaults()
    
    var semaphor: dispatch_semaphore_t
    
    /** Contains the File objects of all of the files ( incl. locally deleted) */
    var allFiles: [File]!
    /** Contains the File objects of all of the local files */
    var files: [File]!
    /** The currently opened file */
    var currentFile: File!
    
    var composerNames: [String]?
    var tempoNames: [String]?
    var musicalFormNames: [String]?
    
    init(){
        semaphor = dispatch_semaphore_create(0)
        
        //printMetaDataFile()
        //print()
        
        generalSetup()
    }
    
    func generalSetup() {
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(
            kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
            service.authorizer = auth
        }
        
        setupUserDefaults()
        
        files = [File]()
        allFiles = [File]()
        
        loadData()
    }
    
    func setupUserDefaults() {
        syncEnabled = userDefaults.valueForKey("syncEnabled") as? Bool
        
        mainFolderID = userDefaults.valueForKey("mainFolderID") as? String
        mainFolderName = userDefaults.valueForKey("mainFolderName") as? String
        
        metadataFolderID = userDefaults.valueForKey("metadataFolderID") as? String
    }
    
    /**
        Loads all of the data form the text files and sets up the data arrays and variables.
        Loads files, composerNames, musicalFormNames
    */
    func loadData(){
        loadLocalFiles()
        loadConstantFiles()
    }
    
    /**
        Loads / creates all of the File objects from the entries of the metadata.txt file and 
        stores them in the files array.
    */
    func loadLocalFiles() {
        files = [File]()
        allFiles = [File]()
        //create File objects from Metadata file
        let metadataFilePath = createDocumentURLFromFilename(metadataFilename)
        
        if NSFileManager.defaultManager().fileExistsAtPath(metadataFilePath.path!) {   // metadata file exists
            do {
                let fileContent = try String(contentsOfFile: metadataFilePath.path!, encoding: NSUTF8StringEncoding)
                
                let lines = fileContent.componentsSeparatedByString("\n")
                for line in lines {
                    if line != "" {
                        
                        let file = File(data: line)
                        allFiles.append(file)
                        
                        if (file.status != File.STATUS.DELETED) {
                            files.append(file)
                        }
                    }
                }
                
            } catch {
                print("Error! Could not read from metadata file")
                fatalError()
            }
        }
    }
    
    /**
        Returns a File array from the entries of the Metadata textfile located in the local Documents Directory.
     
        - Parameter filename: The filename of the metadata file.
        - Returns: An array of Files. Empty if file not found or another error occurs. (Or if file is empty)
    */
    func loadMetadataFileIntoArray(filename: String) -> [File] {
        //create File objects from Metadata file
        let metadataFilePath = createDocumentURLFromFilename(filename)
        
        var entries = [File]()
        
        if NSFileManager.defaultManager().fileExistsAtPath(metadataFilePath.path!) {   // metadata file exists
            do {
                let fileContent = try String(contentsOfFile: metadataFilePath.path!, encoding: NSUTF8StringEncoding)
                
                let lines = fileContent.componentsSeparatedByString("\n")
                for line in lines {
                    if line != "" {
                        
                        let file = File(data: line)
                        entries.append(file)
                    }
                }
                
            } catch {
                print("Error! Could not read from metadata file")
            }
        }
        
        return entries
    }
    
    
    /** 
        Loads the local constant files into their respective String arrays.
    */
    func loadConstantFiles() {
        composerNames = arrayFromContentsOfFileWithName(composersFilename)
        tempoNames = arrayFromContentsOfFileWithName(tempoFilename)
        musicalFormNames = arrayFromContentsOfFileWithName(musicalFormsFilename)
    }
    
    
    /** 
        Loads the lines of a txt file located in the main bundle into a String array.
     
        - Parameter fileName: Filename of the file to be loaded
    */
    func arrayFromContentsOfFileWithName(fileName: String) -> [String]? {
        guard let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "txt") else {
            print("\(fileName).txt could not be found.")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile:path, encoding: NSUTF8StringEncoding)
            return content.componentsSeparatedByString("\n")
        } catch _ as NSError {
            print("Could not read from \(fileName).txt")
            return nil
        }
    }
    
    
    
    /*  Google Drive Sync  */
    
    /** 
        Runs the sync function on the background thread
        
        - Returns: True if the sync was successfully started. False if syncing is disabled.
    */
    func startSync() -> Bool{
        // Only sync if syncing is enabled
        if let syncEnabled = syncEnabled where !syncEnabled {
            //return false      // TODO Implement syncEnabled = true
        }
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            // This is run on the background thread
            self.sync()
            //self.searchForMetadataFolder()
            //self.uploadMetadataFile()
            /**dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print("This is run on the main queue, after the previous code in outer block")
            })*/
        })
        return true
    }
    
    
    /**
        Syncs alls of the sheet (pdf) files and metadata files with the specified folder in Google Drive.
        Has to be run on background thread. Don't run on the main thread!
    */
    func sync(){
        
        print("Syncing")
        
        var result = [File]()
        var localFiles = allFiles
        var driveFiles = [GTLDriveFile]()
        var filenameChanges = [File]()
        var toDownload = [File]()
        var toUpload = [File]()
        
        var success = true
        var metadataFileExists = true
        
        // Create a dispatch group for downloading the driveFiles and the remoteMetadataFile
        let group = dispatch_group_create()
        
        // save the remote metadata folder id if it's not known locally
        
        dispatch_group_enter(group)
        // This function call will save the metadata folder id, or create it
        self.createMetadataFolderIfNotPresent({
            dispatch_group_leave(group)
        })
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        // Download the remote Metadata File to the local documents directory
        dispatch_group_enter(group)
        
        var query = GTLQueryDrive.queryForFilesList()                              // Query for all files in the App Data Folder
        query.q = "name = \'\(remoteMetadataFilename)\'"
        
        service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, response: AnyObject!, error: NSError?) in
            
            if let error = error {
                print("Error while fetching metadataFile: \(error.localizedDescription)")
                success = false
                dispatch_group_leave(group)
                return
            }
            
            // Find the metadata file and download it
            if let foundFiles = response.files where (foundFiles != nil && !foundFiles.isEmpty) {
                var url: String!
                
                // Find the GTLDriveFile for the RemoteMetadata.txt
                for file in (response.files as! [GTLDriveFile]) {
                    print(file.name)
                    if file.name == self.remoteMetadataFilename {
                        url = "https://www.googleapis.com/drive/v3/files/\(file.identifier)?alt=media"
                    }
                }
                
                let fetcher = self.service.fetcherService.fetcherWithURLString(url)
                
                // Download the RemoteMetadata file to the documents directory
                fetcher.beginFetchWithCompletionHandler({ (data: NSData?, error: NSError?) in
                    
                    if let error = error {
                        print("Error while downloading Metadata File: \(error.localizedDescription)")
                        success = false
                        return
                    }
                    
                    data?.writeToFile(self.createDocumentURLFromFilename(self.remoteMetadataFilename).path!, atomically: true)
                    
                    dispatch_group_leave(group)
                })
            } else {
                print("Metadata file not found")
                metadataFileExists = false
                self.createMetadataFolderIfNotPresent({
                    dispatch_group_leave(group)
                })
                
                return
            }
            
        })
        
        
        // Download the GTLDriveFiles into the drive files array
        dispatch_group_enter(group)
        
        query = GTLQueryDrive.queryForFilesList()
        
        if let folderID = mainFolderID {
            query.q = "\'\(folderID)\' in parents and (mimeType = \'application/pdf\')"
            
            service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, response: AnyObject!, error: NSError?) in
                
                if let error = error {
                    print("Error while fetching files in folder: \(error.localizedDescription)")
                    success = false
                    dispatch_group_leave(group)
                    return
                }
                
                // Store the downloaded Google Drive Files from the response in the driveFiles array
                if let files = response.files where (files != nil && !files.isEmpty) {
                    driveFiles = (response.files as! [GTLDriveFile])
                }
                
                dispatch_group_leave(group)
            })
        }
        
        // Wait until both the remoteMetadata file and the Drive files are saved
        print("Waiting on group")
        /*dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () in
            print("Group finished")
        })*/
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)       // DON'T RUN ON MAIN THREAD
        
        // If one of the downloads has failed, the files can't be synced
        if !success {
            print("NO Success")
            return
        }
        
        print("SUCCESS")
        
        // Turn the entries of the RemoteMetadataFile into File objects and load them into the results array
        // If the file doesn't exist in the Drive, there are no entries to import.
        if metadataFileExists {
            result = loadMetadataFileIntoArray(remoteMetadataFilename)
        }
        
        //return      // DEBUG
        
        // Compare metadata entry <-> actual driveFiles <-> local file
        // result currently contains the remote metadata file state
        for (remoteIndex, remoteFile) in result.enumerate() {
            
            var fileExistsInDrive = false
            var driveFile : GTLDriveFile?
            
            // Search for the file in the actual Google Drive files
            for (driveIndex,currentDriveFile) in driveFiles.enumerate() {
                
                if remoteFile.fileID == currentDriveFile.identifier {
                    print("File \(remoteFile.filename) exists in Google Drive")
                    fileExistsInDrive = true
                    driveFile = currentDriveFile
                    
                    // Remove the file from the driveFiles array to leave the unfound files in the array for a later download
                    driveFiles.removeAtIndex(driveIndex)
                    break
                }
            }
            
            var fileExistsLocally = false
            var localFile : File?
            
            // Search for the file in the local files array
            for (localIndex,currentLocalFile) in localFiles.enumerate() {
                
                if currentLocalFile.fileID == remoteFile.fileID {
                    print("File \(remoteFile.filename) known locally")
                    fileExistsLocally = true
                    localFile = currentLocalFile
                    // Remove the localFile from the array leaving the only locally known files in this array
                    localFiles.removeAtIndex(localIndex)
                    break
                }
            }
            
            // check where the file exists and where not and decide if an upload or download is needed.
            if fileExistsInDrive {
                
                // Update the metadata entry filename with the actual drive filename
                remoteFile.filename = driveFile?.name
                
                if fileExistsLocally {
                    // The file exists in all three places -> sync the metadata
                    if localFile!.status == File.STATUS.CHANGED {
                        
                        var filenameChanged = false
                        
                        // check if the filename needs to be updated in the Google Drive
                        if localFile?.filename != remoteFile.filename {
                            // filename was changed
                            filenameChanged = true
                            filenameChanges.append(localFile!)
                        }
                        
                        // replace the remote file data with the local file data
                        result[remoteIndex] = localFile!
                        
                        if !filenameChanged {
                            // If the filename wasn't changed, the sync for this file is already over, so we can 
                            // set its status to SYNCED
                            localFile?.status = File.STATUS.SYNCED
                        }
                        // Otherwise, the state will be updated to synced on completion of the filename change in Google Drive.
                        
                    } else if localFile?.status == File.STATUS.DELETED {
                        // If the file was deleted locally use the remote data and set the status back to deleted
                        remoteFile.status = File.STATUS.DELETED
                        
                    } else if localFile?.status == File.STATUS.SYNCED {
                        remoteFile.status = File.STATUS.SYNCED
                        // If the remote entry has a different filename than the local file, change the filename of 
                        // the local file. 
                        // The rest of the changes are already applied through the metadata entry / file object
                        if remoteFile.filename != localFile?.filename {
                            if !changeFilenameInDocumentsDirectory(localFile!.filename, newFilename: remoteFile.filename) {
                                // The file couldn't be renamed because of an error.
                                print("Error: \(localFile?.filename) couldn't be renamed to \(remoteFile.filename)")
                                // change the filename of the remote entry to the local filename and add the file to the list of filename changes
                                remoteFile.filename = localFile!.filename
                                filenameChanges.append(localFile!)
                                remoteFile.status = File.STATUS.CHANGED
                            } else {
                                print("\(localFile!.filename) renamed to \(remoteFile.filename) locally")
                            }
                        }
                        
                        
                    }
                    
                } else {
                    // File exists in the Drive but not locally and needs to be downloaded
                    toDownload.append(remoteFile)
                    remoteFile.status = File.STATUS.DELETED
                }
                
            } else {
                // The file doesn't exist in the Drive, but was known at some point. -> It was deleted from the drive and 
                // needs to be reuploaded.
                // If it doesn't exist locally on this device, it can't be uploaded.
                if fileExistsLocally {
                    toUpload.append(localFile!)
                    // replace the remote file data with the local file data
                    result[remoteIndex] = localFile!
                    
                    if localFile!.status == File.STATUS.CHANGED {
                        
                        // set its status to SYNCED
                        localFile?.status = File.STATUS.SYNCED
                        
                    } else if localFile?.status == File.STATUS.DELETED {
                        // If the file was deleted locally use the remote data and set the status back to deleted
                        remoteFile.status = File.STATUS.DELETED
                    }
                    
                } else {
                    // File neither exists in the Drive, nor locally -> delete the entry    ( if the file exists on another device, it will be uploaded again from there )
                    result.removeAtIndex(remoteIndex)
                }
            }
            
            // We have now dealt with all of the entries / files of the remote metadata file
        }
        // Now: Deal with the files that have no entries in the remote metadata file
        // These are the files that have been added locally or directly in the Google Drive
        
        // Sync the files that are only locally known
        for localFile in localFiles {
            
            result.append(localFile)
            //print("To upload: \(localFile.filename)")
            toUpload.append(localFile)
        }
        
        // Sync the files that were added in the drive folder
        for driveFile in driveFiles {
            
            let fileEntry = File(filename: driveFile.name)
            fileEntry.fileID = driveFile.identifier
            toDownload.append(fileEntry)
            fileEntry.status = File.STATUS.DELETED  // Set the status to deleted until the download has finished
            result.append(fileEntry)
        }
        
        // store the file information locally
        allFiles = result
        writeMetadataFile()
        
        // Perform all of the uploads, downloads, filename changes and metadata uploads
        // TODO: Upload the constants file
        uploadMetadataFile({})
        
        for file in toUpload {
            
            uploadFile(file)
        }
        
        for file in toDownload {
            
            let driveFile = GTLDriveFile()
            driveFile.originalFilename = file.filename
            driveFile.name = file.filename
            driveFile.identifier = file.fileID
            
            downloadFile(driveFile)
        }
        
        for file in filenameChanges {
            
            updateRemoteFilename(file)
        }
        
        //printMetaDataFile()
        
    }
    
    
    func getSyncProgress() -> CGFloat {
        
        var totalProgress : CGFloat = 0
        var totalSize : CGFloat = 0
        
        for progress in syncProgress.values {
            totalProgress += progress.0
            totalSize += progress.1
        }
        
        return totalProgress/totalSize
    }
    
    /** 
        Uploads the file to the main Google Drive folder.
    */
    func uploadFile(file: File){
        
        let driveFile = GTLDriveFile()
        driveFile.originalFilename = file.filename
        driveFile.name = file.filename
        driveFile.parents = [mainFolderID!]
        
        let fileURL = file.getUrl()
        
        let uploadParameters = GTLUploadParameters(fileURL: fileURL, MIMEType: "application/pdf")
        let query = GTLQueryDrive.queryForFilesCreateWithObject(driveFile, uploadParameters: uploadParameters)
        
        let ticket = service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, updatedFile: AnyObject!, error: NSError?) in
            
            if let error = error {
                print("Error while uploading file \(file.filename): \(error.localizedDescription)")
            } else {
                print("\(file.filename) uploaded to Google Drive")
                // Set the local file status to synced
                file.status = File.STATUS.SYNCED
                file.fileID = (updatedFile as! GTLDriveFile).identifier
                
                self.writeMetadataFile()
                self.uploadMetadataFile({})
            }
        })
        
        ticket.uploadProgressBlock = { (ticket: GTLServiceTicket!, bytes_Written: UInt64, totalBytesWritten: UInt64) in
            self.currentDownloadProgress = (CGFloat(totalBytesWritten) * 100)/self.completeDownloadSize
            
            self.syncProgress[ticket.objectFetcher] = ((CGFloat(totalBytesWritten) * 100),CGFloat(ticket.objectFetcher.bodyLength))
        }
        
    }
    
    /** 
        Changes the filename of the Google drive file.
    */
    func updateRemoteFilename(localFile: File){
        
        
        let file = GTLDriveFile()
        file.name = localFile.filename
        file.originalFilename = localFile.filename
        file.identifier = localFile.fileID
        //let uploadParameters =
        
        let query = GTLQueryDrive.queryForFilesUpdateWithObject(file, fileId: file.identifier, uploadParameters: nil)
        
        service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, updatedFile: AnyObject!, error: NSError?) in
            
            if let error = error {
                print("Error while updating the filename of \(file.name): \(error.localizedDescription)")
            } else {
                print("\(file.name): Updated the filename. ")
                // Set the local file status to synced
                localFile.status = File.STATUS.SYNCED
                self.writeMetadataFile()
            }
        })
    }
    
    /** 
        Uploads the local Metadata file to the Main sheet folder if it doesn't already exist there, 
        otherwise, it updates the data of the remoteMetadata file.
    */
    func uploadMetadataFile(completionHandler: () -> Void) {
        
        let searchQuery = GTLQueryDrive.queryForFilesList()
        searchQuery.q = "name = \'\(remoteMetadataFilename)\'"
    
        service.executeQuery(searchQuery, completionHandler: { (ticket: GTLServiceTicket!, response: AnyObject?, error: NSError?) in
            
            if let files = response?.files where (files != nil && !files.isEmpty) {
                print("The metadata file already exists")
                
                // Find the file
                var mfile: GTLDriveFile?
                for file in response!.files as! [GTLDriveFile] {
                    if file.name == self.remoteMetadataFilename {
                        mfile = file
                        print("Remote Metadata file found in response")
                        break
                    }
                }
                
                self.forceUploadMetadataFile({
                    // Delete the current file
                    let query = GTLQueryDrive.queryForFilesDeleteWithFileId(mfile?.identifier)
                    
                    self.service.executeQuery(query, completionHandler: {
                        (ticket: GTLServiceTicket!, deletedFile: AnyObject!, error: NSError?) in
                        
                        if let error = error {
                            print("Error while deleting the remote Metadata file: \(error.localizedDescription)")
                        } else {
                            print("Deleted the remote metadata.")
                        }
                        
                        completionHandler()
                    })
                })
                
            } else {
                // The file doesn't exist anyway
                // Upload it
                self.forceUploadMetadataFile(completionHandler)
            }
        })
        
        

    }
    
    /** 
        Uploads the metadata file to the metadata folder in the Google Drive.
    */
    private func forceUploadMetadataFile(completionHandler: () -> Void){
        // Upload the metadata file to the Google drive
        let driveFile = GTLDriveFile()
        driveFile.originalFilename = self.remoteMetadataFilename
        driveFile.name = self.remoteMetadataFilename
        //driveFile.parents = ["appDataFolder"]
        driveFile.parents = [self.metadataFolderID!]
        
        let fileURL = self.createDocumentURLFromFilename(self.metadataFilename)
        
        let uploadParameters = GTLUploadParameters(fileURL: fileURL, MIMEType: "*/*")
        let query = GTLQueryDrive.queryForFilesCreateWithObject(driveFile, uploadParameters: uploadParameters)
        
        self.service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, updatedFile: AnyObject!, error: NSError?) in
            
            if let error = error {
                print("Error while uploading Metadata file: \(error.localizedDescription)")
            } else {
                print("Metadata file uploaded to Google Drive")
                print("uploaded file: \((updatedFile as! GTLDriveFile).name)")
            }
            
            completionHandler()
        })
    }
    
    /** Disables the Google Drive sync functionality. */
    func disableSync(){
        syncEnabled = false
        userDefaults.setBool(false, forKey: "syncEnabled")
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
        print("Downloading \(file.name)")
        let url = "https://www.googleapis.com/drive/v3/files/\(file.identifier)?alt=media"
        
        let fetcher = service.fetcherService.fetcherWithURLString(url)
        
        fetcher.beginFetchWithCompletionHandler({ (data: NSData?, error: NSError?) in
            
            if let error = error {
                print("Error \(error.localizedDescription)")
                fatalError()
            }
            
            if let data = data {
                let localFile = self.saveFileToDocumentsDirectory(data,file: file)
                localFile.status = File.STATUS.SYNCED
                self.writeMetadataFile()
                
                print("Finished Download of \(localFile.filename)")
            }
        })
        
        fetcher.receivedProgressBlock = { (bytes_Written: __int64_t, totalBytesWritten: __int64_t) in
            self.currentDownloadProgress = (CGFloat(totalBytesWritten) * 100)/self.completeDownloadSize
            
            self.syncProgress[fetcher] = ((CGFloat(totalBytesWritten) * 100),CGFloat(fetcher.bodyLength))
        }
        
    }
    
    /** Downloads the file data from the url to the Documents directory and creates a new file object for it and stores it in the currentFile. */
    func downloadFileFromURL(url: NSURL) {
        let fileData = NSData(contentsOfURL: url)!
        let filename = url.lastPathComponent!
        
        self.currentFile = self.saveFileToDocumentsDirectory(fileData, filename: filename)
    }
    
    /** 
        Saves the data of the downloaded file in the Documents directory.
     
        - Returns: The file object associated with the GTLDriveFile.
    */
    func saveFileToDocumentsDirectory(data: NSData,file: GTLDriveFile) -> File {
        
        let localFile = createAndAddFileObject(file.name, fileID: file.identifier)
        data.writeToFile(localFile.getUrl().path!, atomically: true)
        
        return localFile
    }
    
    func saveFileToDocumentsDirectory(data: NSData, filename: String) -> File {
        
        let localFile = createAndAddFileObject(filename, fileID: "")
        data.writeToFile(localFile.getUrl().path!, atomically: true)
        
        return localFile
    }
    
    /** 
        Creates and returns a File object with the specified url and fileID. The file is added to the files 
        list and the metadata file, if it didn't exist before.
     
        - Returns: The created File object.
    */
    func createAndAddFileObject(filename: String, fileID: String) -> File {
        let file = File(filename: filename)
        file.fileID = fileID
        
        //append file data to metadata file and file list
        //first check to see if it already exists or not
        let dataString = file.filename
        
        for document in allFiles {
            if document.filename == dataString {
                print("File already exists in metadata and/or loaded files")
                return document
            }
        }
        
        updateMetadataFile(file)
        allFiles.append(file)
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
        Writes the metadata of all locally known files to the local metadata file.
    */
    func writeMetadataFile() {
        resetMetaDataFile()
        
        for file in allFiles {
            updateMetadataFile(file)
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
    
    /** 
        Checks, if the metadata folder already exists in the main sheet folder and if not, creates it.
    */
    func createMetadataFolderIfNotPresent(completionHandler: () -> Void){
        
        let searchQuery = GTLQueryDrive.queryForFilesList()
        searchQuery.q = "name = \'\(metadataFolderName)\' and mimeType = \'application/vnd.google-apps.folder\'"
        
        service.executeQuery(searchQuery, completionHandler: { (ticket: GTLServiceTicket!, response: AnyObject?, error: NSError?) in
            
            if let error = error {
                print("Error \(error.localizedDescription)")
                return
            }
            
            if let files = response?.files where (files != nil && !files.isEmpty) {
                print("The metadata folder already exists")
                // Metadata folder found
                for file in response!.files as! [GTLDriveFile] {
                    
                    if file.name == self.metadataFolderName {
                        self.metadataFolderID = file.identifier
                        print("Metadata folder ID saved")
                        break
                    }
                }
                completionHandler()
            } else {
                // Metadata folder doesn't exist
                print("Metadata folder not found")
                // Create the metadata folder
                let folder = GTLDriveFile()
                folder.name = self.metadataFolderName
                folder.mimeType = "application/vnd.google-apps.folder"
                folder.parents = [self.mainFolderID!]
                
                let createQuery = GTLQueryDrive.queryForFilesCreateWithObject(folder, uploadParameters: nil)
                
                self.service.executeQuery(createQuery, completionHandler: { (ticket: GTLServiceTicket!, file: AnyObject!, error: NSError?) in
                    if let error = error {
                        print("Error \(error.localizedDescription)")
                        return
                    }
                    
                    print("Finished creating Metadata folder")
                    self.metadataFolderID = (file as! GTLDriveFile).identifier
                    self.userDefaults.setObject(self.metadataFolderID, forKey: "metadataFolderID")
                    self.uploadMetadataFile(completionHandler)
                    
                })
            }
        })
    }
    
    /** 
        Searches for the metadata folder and prints the search result.
    */
    func searchForMetadataFolder(){
        
        let searchQuery = GTLQueryDrive.queryForFilesList()
        searchQuery.q = "name = \'\(metadataFolderName)\' and mimeType = \'application/vnd.google-apps.folder\'"
        
        service.executeQuery(searchQuery, completionHandler: { (ticket: GTLServiceTicket!, response: AnyObject?, error: NSError?) in
            
            if let error = error {
                print("Error \(error.localizedDescription)")
                return
            }
            
            if let files = response?.files where (files != nil && !files.isEmpty) {
                print("Metadata folder found")
                for file in (files as! [GTLDriveFile]) {
                    print(file.name)
                }
            } else {
                print("Metadata folder not found")
            }
        })
    }
    
    /**
        Changes the filename of a file in the local documents directory to 'newFilename'.
     
        - Returns: If the filname change was successful or not.
    */
    func changeFilenameInDocumentsDirectory(oldFilename: String, newFilename: String) -> Bool {
        
        do {
            let oldPath = createDocumentURLFromFilename(oldFilename)
            let newPath = createDocumentURLFromFilename(newFilename)
            
            try NSFileManager.defaultManager().moveItemAtURL(oldPath, toURL: newPath)
            
        } catch let error as NSError {
            print(error)
            return false
        }
        
        return true
        
    }
    
    /** 
        Deletes all of the files in the documents directory, and empties the metadata file
    */
    func deleteAllFiles(){
        for file in allFiles {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(createDocumentURLFromFilename(file.filename))
            } catch {
                print("Could not remove \(file.filename)")
            }
        }
        
        allFiles = [File]()
        files = [File]()
        
        resetMetaDataFile()
    }
    
    /*
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
        
        
    }*/
    
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











