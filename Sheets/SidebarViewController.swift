//
//  SidebarViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 12.08.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation

class SidebarViewController: UITableViewController {

    var menuItems: NSArray!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuItems = ["title","sheets","composers","filter","sync","download","settings"]
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "filterSegue" {
            let navController = segue.destinationViewController as! UINavigationController
            let nextScene = navController.visibleViewController as! MainViewController
            
            // Pass the attribute to the new view controller.
            nextScene.shouldShowFilterOptions = true
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellID = menuItems.objectAtIndex(indexPath.row)
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID as! String, forIndexPath: indexPath)
        
        return cell
    }

}