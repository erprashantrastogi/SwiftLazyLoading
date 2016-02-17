//
//  ViewController.swift
//  LazyLoadingSwift
//
//  Created by Prashant Rastogi on 04/12/15.
//  Copyright © 2015 Prashant Rastogi. All rights reserved.
//

import UIKit

class RootVC: UITableViewController {

    static var kCustomRowCount = 7
    
    static var CellIdentifier = "LazyTableCell";
    static var PlaceholderCellIdentifier = "PlaceholderCell";
    
    var entries = NSMutableArray()
    
    // the set of IconDownloader objects for each app
    var imageDownloadsInProgress = NSMutableDictionary ();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        // terminate all pending download connections
        self.terminateAllDownloads();
    }
    
    func terminateAllDownloads()
    {
        // terminate all pending download connections
        let allDownloads = self.imageDownloadsInProgress.allValues as! [IconDownloader] ;
        
        allDownloads.forEach({item in
            item.cancelDownload()
        })
        
        self.imageDownloadsInProgress.removeAllObjects();
    }
    
    deinit
    {
        // terminate all pending download connections
        self.terminateAllDownloads();
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let count = self.entries.count;
        
        // if there's no data yet, return enough rows to fill the screen
        if (count == 0)
        {
            return RootVC.kCustomRowCount;
        }
        return count;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell!;
        
        let nodeCount = self.entries.count;
        
        if (nodeCount == 0 && indexPath.row == 0)
        {
            // add a placeholder cell while waiting on table data
            cell = tableView.dequeueReusableCellWithIdentifier(RootVC.PlaceholderCellIdentifier, forIndexPath: indexPath);
            
        }
        else
        {
            cell = tableView.dequeueReusableCellWithIdentifier(RootVC.CellIdentifier, forIndexPath: indexPath);
            
            
            // Leave cells empty if there's no data yet
            if (nodeCount > 0)
            {
                let appRecord = ((self.entries)[indexPath.row]) as! AppRecord
                
                cell.textLabel!.text = appRecord.appName;
                //cell.detailTextLabel!.text = appRecord.artist;
                
                // Only load cached images; defer new downloads until scrolling ends
                if (appRecord.appIcon == nil)
                {
                    if (self.tableView.dragging == false && self.tableView.decelerating == false)
                    {
                        self.startIconDownload(appRecord, forIndexPath: indexPath);
                    }
                    // if a download is deferred or in progress, return a placeholder image
                    cell.imageView!.image = UIImage(named: "Placeholder.png")
                }
                else
                {
                    cell.imageView!.image = appRecord.appIcon;
                }
            }
        }
        
        return cell;
    }
    
    // -------------------------------------------------------------------------------
    //  startIconDownload:forIndexPath:
    // -------------------------------------------------------------------------------
    func startIconDownload(appRecord :AppRecord , forIndexPath indexPath:NSIndexPath )
    {
        var iconDownloader:IconDownloader? = (self.imageDownloadsInProgress)[indexPath] as? IconDownloader;
        
        if (iconDownloader == nil)
        {
            iconDownloader = IconDownloader();
            iconDownloader!.appRecord = appRecord;
            
            iconDownloader?.completionHandler = {
                
                if let cellObj = self.tableView.cellForRowAtIndexPath(indexPath)
                {
                    // Display the newly loaded image
                    cellObj.imageView!.image = appRecord.appIcon;
                    
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                    
                    // Remove the IconDownloader from the in progress list.
                    // This will result in it being deallocated.
                    self.imageDownloadsInProgress.removeObjectForKey(indexPath);
                }
                
            }
            
            (self.imageDownloadsInProgress)[indexPath] = iconDownloader;
            iconDownloader?.startDownload()
        }
    }
    
    // -------------------------------------------------------------------------------
    //  loadImagesForOnscreenRows
    //  This method is used in case the user scrolled into a set of cells that don't
    //  have their app icons yet.
    // -------------------------------------------------------------------------------
    func loadImagesForOnscreenRows()
    {
        if (self.entries.count > 0)
        {
            let visiblePaths = self.tableView.indexPathsForVisibleRows
            
            visiblePaths?.forEach({ indexPath in
            
                let appRecord = ((self.entries)[indexPath.row]) as! AppRecord;
                
                if (appRecord.appIcon == nil)
                    // Avoid the app icon download if the app already has an icon
                {
                    self.startIconDownload(appRecord, forIndexPath: indexPath)
                }
                
            })
            
            
        }
    }
    
    // -------------------------------------------------------------------------------
    //  scrollViewDidEndDragging:willDecelerate:
    //  Load images for all onscreen rows when scrolling is finished.
    // -------------------------------------------------------------------------------
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if (!decelerate)
        {
            self.loadImagesForOnscreenRows();
        }
    }
    
    // -------------------------------------------------------------------------------
    //  scrollViewDidEndDecelerating:scrollView
    //  When scrolling stops, proceed to load the app icons that are on screen.
    // -------------------------------------------------------------------------------
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
         self.loadImagesForOnscreenRows();
    }
    
}

