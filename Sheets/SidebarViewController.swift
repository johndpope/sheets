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
        
        menuItems = ["title","sheets","composers","filter","download","deleted","settings"]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "filterSegue" {
            let navController = segue.destination as! UINavigationController
            let nextScene = navController.visibleViewController as! MainViewController
            
            // Pass the attribute to the new view controller.
            nextScene.shouldShowFilterOptions = true
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = menuItems.object(at: (indexPath as NSIndexPath).row)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID as! String, for: indexPath)
        
        return cell
    }

}
