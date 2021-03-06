//
//  AppDelegate.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 27.06.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import UIKit
import Foundation
import vfrReader
import GoogleAPIClient
import AppAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    
    var currentAuthorizationFlow: OIDAuthorizationFlowSession?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let finalURL = URL(fileURLWithPath: documentsDirectory)
        self.addSkipBackupAttributeToItemAtURL(finalURL.path)
        
        return true
    }
    
    //Handler for opening PDFs from outside the application
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        //url contains a URL to the file this app shall open
        
        DataManager.sharedInstance.downloadFileFromURL(url)
        
        VFRController.sharedInstance.showPDFInReader(DataManager.sharedInstance.currentFile!)
        return true
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Sends the URL to the current authorization flow (if any) which will
        // process it if it relates to an authorization response.
        if let flow = currentAuthorizationFlow, flow.resumeAuthorizationFlow(with: url) {
            currentAuthorizationFlow = nil
            return true
        } else {
            DataManager.sharedInstance.downloadFileFromURL(url)
            
            VFRController.sharedInstance.showPDFInReader(DataManager.sharedInstance.currentFile!)
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func addSkipBackupAttributeToItemAtURL(_ filePath:String) -> Bool {
        
        let url:Foundation.URL = URL(fileURLWithPath: filePath)
        
        assert(FileManager.default.fileExists(atPath: filePath), "File \(filePath) does not exist")
        
        var success: Bool
        do {
            try (url as NSURL).setResourceValue(true, forKey:URLResourceKey.isExcludedFromBackupKey)
            success = true
        } catch let error as NSError {
            success = false
            print("Error excluding \(url.lastPathComponent) from backup \(error)");
        }
        
        return success
    }


}

