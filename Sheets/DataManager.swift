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
import QuartzCore

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
    private let instrumentsFilename = "Instruments"
    private let keysFilename = "Keys"
    
    // Google Drive variables
    let kKeychainItemName = "Drive API"
    let kClientID = "451075181287-dvcikapqk1qkontp8gfs6kohanp44h2t.apps.googleusercontent.com"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    let scopes = [kGTLAuthScopeDrive]
    
    let service = GTLServiceDrive()
    
    let userDefaults = NSUserDefaults()
    
    var syncEnabled: Bool? {
        didSet {
            if let enabled = syncEnabled {
                userDefaults.setBool(enabled, forKey: "syncEnabled")
            } else {
                userDefaults.setBool(false, forKey: "syncEnabled")
            }
            
        }
    }
    
    /** The collection view to update after a download finishes. */
    var collectionView: UICollectionView?
    /** The table view to update after a download finishes. */
    var tableView: UITableView?
    
    var mainFolderName: String!
    var mainFolderID: String?
    
    let metadataFolderName = "AppData - DO NOT EDIT"
    var metadataFolderID: String?
    
    private var downloadedDriveFiles = [GTLDriveFile]()
    var completeDownloadSize : CGFloat = 0    // in bytes
    var currentDownloadProgress : CGFloat = 1
    
    //private var syncProgress = Dictionary<GTMSessionFetcher,(CGFloat,CGFloat)>()
    /** String = filename that is being synced. Bool = sync for this file finished or not. */
    private var syncProgress = Dictionary<String,Bool>()
    
    /** Is true if the app is currently syncing the files with Google Drive. */
    var syncing = false
    
    var semaphor: dispatch_semaphore_t
    
    var thumbnailSize = CGSize(width: 150, height: 200)
    
    var defaultBlue = UIColor(red: 6/255, green: 31/255, blue: 39/255, alpha: 1)
    /** Contains the File objects of all of the files ( incl. locally deleted) */
    var allFiles: [File]!
    /** Contains the File objects of all of the local files */
    var files: [File]!
    /** The File objects after a filter was applied to "files" */
    var filteredFiles: [File]!
    /** The files that were deleted locally but exists in the Google Drive. */
    var deletedFiles: [File]!
    /** The currently opened file */
    var currentFile: File?
    /** The currently active filter */
    var currentFilter = "All"
    
    var composerNames: [String]?
    var tempoNames: [String]?
    var musicalFormNames: [String]?
    var instruments: [String]?
    var keys: [String]?
    
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
        deletedFiles = [File]()
        
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
        filteredFiles = [File]()
        deletedFiles = [File]()
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
                        } else {
                            // File was deleted locally
                            deletedFiles.append(file)
                        }
                    }
                }
                
            } catch {
                print("Error! Could not read from metadata file")
                fatalError()
            }
        }
        
        filterFiles(currentFilter)
    }
    
    /** 
        Creates the pdf thumbnails from all local files and refreshes the collectionView.
    */
    func loadPDFThumbnails(collectionView: UICollectionView?){
        
        for file in files {
            
            let image = getThumbnailForFile(file)
            
            file.thumbnail = image
            
            collectionView?.reloadData()
        }
    }
    
    /** 
        Returns the thumbnail for a given file. If the thumbnail doesn't already exist
        it is created and stored in the documents directory. The Url path to that image is
        added to a dictionary in the userDefaults for later access.
    */
    func getThumbnailForFile(file: File) -> UIImage {
        var thumbDict = userDefaults.valueForKey("thumbnailDictionary") as? [String:String]
        // check if thumbnail for this file already exists
        if thumbDict != nil {
            
            if let thumbPath = thumbDict?[file.filename], let data = NSData(contentsOfFile: thumbPath) {
                // load the thumbnail from the url
                let thumb = UIImage(data: data)
                return thumb!
            }
        } else {
            thumbDict = [String:String]()
        }
        
        // create thumbnail
        // Draw the first page
        let pdfRef = CGPDFDocumentCreateWithURL(file.getUrl())
        let pageRef = CGPDFDocumentGetPage(pdfRef, 1)
        
        let pdfRect = CGPDFPageGetBoxRect(pageRef, CGPDFBox.MediaBox)
        //print("PDFSize: \(file.filename) :  width \(pdfRect.width) height \(pdfRect.height)")
        let thumbHeight = (((thumbnailSize.width / pdfRect.width) * pdfRect.height) - 3)
        //let thumbHeight = thumbnailSize.height
        //let thumbWidth = (thumbnailSize.height / pdfRect.height) * pdfRect.width - 3
        let thumbWidth = thumbnailSize.width
        
        UIGraphicsBeginImageContext(thumbnailSize)
        //UIGraphicsBeginImageContext(CGSizeMake(thumbWidth, thumbHeight))
        
        let contextRef = UIGraphicsGetCurrentContext()
        
        CGContextTranslateCTM(contextRef, 0.0, thumbHeight);
        CGContextScaleCTM(contextRef, 1, -1);
        
        let pdfTransform = CGPDFPageGetDrawingTransform(
            pageRef,
            CGPDFBox.MediaBox,
            CGRectMake(3, 0, thumbWidth - 4, thumbHeight),
            0,
            true)
        
        // And apply the transform.
        CGContextConcatCTM(contextRef, pdfTransform);
        
        CGContextDrawPDFPage(contextRef, pageRef)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        // clean up
        UIGraphicsEndImageContext()
        
        // save image to documentsdirectory
        let thumbFilename = file.filename.stringByDeletingPathExtension() + "_thumbnail.png"
        let thumbURL = createDocumentURLFromFilename(thumbFilename)
        let imageData = UIImagePNGRepresentation(image)
        
        // write the data to the documents directory
        var success = true
        do {
            try imageData?.writeToFile(thumbURL.path!, options: .DataWritingAtomic)
        } catch {
            print("Could not store thumbnail \(error)")
            success = false
        }
        
        if success {
            // add the entry to the file dictionary
            thumbDict![file.filename] = thumbURL.path!
            userDefaults.setObject(thumbDict, forKey: "thumbnailDictionary")
        }
        
        return image
    }
    
    /** 
        Returns a dictionary that maps composer names to a list of files that belong to this composer
    */
    func getFilesByComposer() -> [String:[File]] {
        
        var result = [String:[File]]()
        
        for file in files {
            
            let composer = file.composer == "" ? "Other" : file.composer
            
            if result[composer] != nil {
                // list already initialized -> append to list
                print("append \(file.filename)")
                result[composer]!.append(file)
            } else {
                // intialize new list
                result[composer] = [file]
            }
        }
        
        return result
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
        instruments = arrayFromContentsOfFileWithName(instrumentsFilename)
        keys = arrayFromContentsOfFileWithName(keysFilename)
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
    
    func filteredFiles(filter: String) -> [File] {
        
        if filter.lowercaseString == "all" {
            return files
        }
        
        var filtered = [File]()
        
        if let files = files {
            
            for file in files {
                
                if file.getFilterString().containsString(filter.lowercaseString) {
                    filtered.append(file)
                }
            }
        }
        
        return filtered
    }
    
    func filterFiles(filter: String) {
        self.currentFilter = filter
        filteredFiles = filteredFiles(filter)
    }
    
    
    /*  Google Drive Sync  */
    
    /** 
        Runs the sync function on the background thread
        
        - Returns: True if the sync was successfully started. False if syncing is disabled.
    */
    func startSync() -> Bool{
        // Only sync if syncing is enabled
        print(syncing)
        print(syncEnabled)
        if let enabled = syncEnabled where !enabled || syncing {
            return false      // TODO Implement syncEnabled = true
        }
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            // This is run on the background thread
            self.syncing = true
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
    private func sync(){
        
        print("Syncing")
        
        var result = [File]()
        var localFiles = allFiles
        var driveFiles = [GTLDriveFile]()
        var filenameChanges = [File]()
        var toDownload = [File]()
        var toUpload = [File]()
        
        var success = true
        var metadataFileExists = true
        
        syncProgress.removeAll()
        
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
                            
                            // needed to ensure that no two files with the same filename are downloaded.
                            var toBeLocalFiles = files
                            toBeLocalFiles.appendContentsOf(toDownload)
                            
                            if NamingManager.sharedInstance.filenameAlreadyExistsInArray(toBeLocalFiles, filename: remoteFile.filename) ||
                                !changeFilenameInDocumentsDirectory(localFile!.filename, newFilename: remoteFile.filename) {
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
        
        // order the files
        if userDefaults.boolForKey("localOrderPriority") {
            allFiles = reorderFiles(result, ref: allFiles, toDownload: toDownload, toUpload: toUpload)
        } else {
            allFiles = result
        }
        
        // store the file information locally
        //allFiles = result
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
        
        // check if syncing was finished
        if self.getSyncProgress() == 1 {
            self.syncing = false
        }
        
        //printMetaDataFile()
        
    }
    
    /** 
        Returns the current sync progress. 0 at the beginning and 1 when finished.
    */
    func getSyncProgress() -> CGFloat {
        
        var totalFinished = 0
        
        for finished in syncProgress.values {
            if finished {
                
                totalFinished += 1
            }
        }
        
        let fileCount = syncProgress.values.count
        
        if fileCount == 0 {
            print("no files in sync progress")
            return 1
        } else {
            return CGFloat(totalFinished/syncProgress.values.count)
        }
    }
    
    /** 
        Uploads the file to the main Google Drive folder.
    */
    func uploadFile(file: File){
        
        let driveFile = GTLDriveFile()
        driveFile.originalFilename = file.filename
        driveFile.name = file.filename
        driveFile.parents = [mainFolderID!]
        
        syncProgress[file.filename] = false
        
        let fileURL = file.getUrl()
        
        let uploadParameters = GTLUploadParameters(fileURL: fileURL, MIMEType: "application/pdf")
        let query = GTLQueryDrive.queryForFilesCreateWithObject(driveFile, uploadParameters: uploadParameters)
        
        service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, updatedFile: AnyObject!, error: NSError?) in
            
            if let error = error {
                print("Error while uploading file \(file.filename): \(error.localizedDescription)")
            } else {
                print("\(file.filename) uploaded to Google Drive")
                // Set the local file status to synced
                file.status = File.STATUS.SYNCED
                file.fileID = (updatedFile as! GTLDriveFile).identifier
                
                
                // TODO: File ID seems to not be set correctly causing redownload
                print("FileID: \(file.fileID)")
                var filesContainID = false
                for localFile in self.allFiles {
                    if localFile.fileID == file.fileID {
                        filesContainID = true
                    }
                }
                print("ID in all Files: \(filesContainID)")
                
                self.writeMetadataFile()
                self.uploadMetadataFile({})
            }
            
            self.syncProgress[file.filename] = true
            
            // check if syncing was finished
            if self.getSyncProgress() == 1 {
                self.syncing = false
            }
        })
    }
    
    /** 
        Changes the filename of the Google drive file.
    */
    func updateRemoteFilename(localFile: File){
        
        let file = GTLDriveFile()
        file.name = localFile.filename
        
        syncProgress[file.name] = false
        
        let query = GTLQueryDrive.queryForFilesUpdateWithObject(file, fileId: localFile.fileID, uploadParameters: nil)
        
        service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, updatedFile: AnyObject!, error: NSError?) in
            
            if let error = error {
                print("Error while updating the filename of \(file.name): \(error.localizedDescription)")
            } else {
                print("\(file.name): Updated the filename. ")
                // Set the local file status to synced
                localFile.status = File.STATUS.SYNCED
                self.writeMetadataFile()
            }
            
            self.syncProgress[file.name] = true
            
            // check if syncing was finished
            if self.getSyncProgress() == 1 {
                self.syncing = false
            }
        })
    }
    
    /** Updates the remote metadata entries with the local metadata file. */
    func updateRemoteMetadata(file: GTLDriveFile) {
        let driveFile = GTLDriveFile()
        
        let uploadParameters = GTLUploadParameters(data: NSData(contentsOfURL: self.createDocumentURLFromFilename(self.metadataFilename))!, MIMEType: "*/*")
        
        let query = GTLQueryDrive.queryForFilesUpdateWithObject(driveFile, fileId: file.identifier, uploadParameters: uploadParameters)
        
        service.executeQuery(query, completionHandler: { (ticket: GTLServiceTicket!, updatedFile: AnyObject!, error: NSError?) in
            
            if let error = error {
                print("Error while updating the remote metadata entries: \(error.localizedDescription)")
            } else {
                print("Updated the remote metadata file. ")

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
                
                self.writeMetadataFile()    // Write the metadata file to make sure it exists
                
                self.updateRemoteMetadata(mfile!)
                /**
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
                     */
                
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
        
        self.writeMetadataFile()    // write Metadata file to make sure it exists locally
        
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
    }
    
    /** 
        Reorders the entries of the list toOrder, keeping the order of ref and putting new files to the beginning.
        
        - Returns: an ordered list
    */
    func reorderFiles(toOrder: [File], ref: [File], toDownload: [File], toUpload: [File]) -> [File] {
    
        var result = [File]()
        
        // first add the files that have to be downloaded
        result.appendContentsOf(toDownload)
        
        for refFile in ref {
            
            if toUpload.contains({ $0.filename == refFile.filename }) {
                // all local file data
                result.append(refFile)
            } else {
                // search for the file entry in the toOrder array
                for file in toOrder {
                    
                    if file.filename == refFile.filename && file.fileID == refFile.fileID {
                        result.append(file)
                        break
                    }
                }
            }
        }
        
        // make sure result has the same dimensions as toOrder (no files are lost)
        assert(result.count == toOrder.count, "Result and toOrder don't contain the same number of files.")
        
        return result
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
        
        // don't download if the filename already exists locally
        if NamingManager.sharedInstance.filenameAlreadyExists(file.name.stringByDeletingPathExtension()) {
            return
        }
        
        syncing = true
        
        print("Downloading \(file.name)")
        let url = "https://www.googleapis.com/drive/v3/files/\(file.identifier)?alt=media"
        
        syncProgress[file.name] = false
        
        let fetcher = service.fetcherService.fetcherWithURLString(url)
        
        fetcher.beginFetchWithCompletionHandler({ (data: NSData?, error: NSError?) in
            
            if let error = error {
                print("Error \(error.localizedDescription)")
                //fatalError()
            } else {
            
                if let data = data {
                    let localFile = self.saveFileToDocumentsDirectory(data,file: file)
                    localFile.status = File.STATUS.SYNCED
                    self.writeMetadataFile()
                
                    print("Finished Download of \(localFile.filename)")
                    
                    // refresh table and collection view if needed
                    dispatch_async(dispatch_get_main_queue(), {
                        self.loadLocalFiles()
                        self.filterFiles(self.currentFilter)
                        self.collectionView?.reloadData()
                        self.tableView?.reloadData()
                    })
                    
                }
            }
            
            self.syncProgress[file.name] = true
            
            // check if syncing was finished
            if self.getSyncProgress() == 1 {
                self.syncing = false
            }
        })
    }
    
    func downloadFile(file: File){
        // setup the GTLDriveFile object 
        let driveFile = GTLDriveFile()
        driveFile.name = file.filename
        driveFile.identifier = file.fileID
        
        downloadFile(driveFile)
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
        
        // Update the entry for the file thumbnail in the user defaults dictionary
        var thumbDict = userDefaults.valueForKey("thumbnailDictionary") as? [String:String]
        let thumbPath = thumbDict?[oldFilename]
        thumbDict?.removeValueForKey(oldFilename)
        thumbDict?[newFilename] = thumbPath
        // Store the dictionary in the user defaults
        userDefaults.setObject(thumbDict, forKey: "thumbnailDictionary")
        
        return true
        
    }
    
    /**
        Deletes the file in the local documents directory and sets the metadata entry to DELETED.
    */
    func deleteFile(file: File) {
        do {
            try NSFileManager.defaultManager().removeItemAtURL(createDocumentURLFromFilename(file.filename))
        } catch {
            print("Could not remove \(file.filename)")
        }
        
        // if the file hadn't been synced with the google drive before
        // if not it can't be downloaded again and should therefore have its
        // metadata entry removed
        if file.status == File.STATUS.NEW {
            
            let index = allFiles.indexOf(file)
            allFiles.removeAtIndex(index!)
        } else {
            // otherwise just set the status to DELETED
            file.status = File.STATUS.DELETED
        }
        
        writeMetadataFile()
        loadLocalFiles()
        
        // Delete the file thumbnail from the thumbnailDictionary
        var thumbDict = userDefaults.valueForKey("thumbnailDictionary") as? [String:String]
        let thumbPath = thumbDict?[file.filename]
        thumbDict?.removeValueForKey(file.filename)
        // Store the dictionary in the user defaults
        userDefaults.setObject(thumbDict, forKey: "thumbnailDictionary")
        
        // Delete the thumbnail locally
        if thumbPath != nil {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(NSURL(fileURLWithPath: thumbPath!))
            } catch {
                print("Could not remove the thumbnail for \(file.filename)")
            }
        }
    }
    
    /**
        Deletes all of the files in the documents directory, and empties the metadata file
    */
    func reset(){
        deleteDocumentsDirectory()
        deleteAllFiles()
        
        resetMetaDataFile()
    }
    
    /** 
        Deletes all of the files in the documents directory and sets their state to DELETED so they can be downloaded again.
    */
    func deleteAllFiles(){
        
        for file in allFiles {
            deleteFile(file)
        }
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
}

extension DataManager {
    
    func matchesForRegexInText(regex: String, text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    func createDocumentURLFromFilename(filename: String) -> NSURL {
        return NSURL(fileURLWithPath: applicationDocumentDirectory()).URLByAppendingPathComponent(filename)
    }
    
    /**
     Returns the path to the Documents Directory.
     
     - Returns: path to Documents Directory
     */
    func applicationDocumentDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    }
    
}











