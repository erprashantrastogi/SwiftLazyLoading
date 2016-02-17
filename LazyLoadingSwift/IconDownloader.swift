//
//  IconDownloader.swift
//  LazyLoadingSwift
//
//  Created by Prashant Rastogi on 04/12/15.
//  Copyright © 2015 Prashant Rastogi. All rights reserved.
//

import UIKit

class IconDownloader: NSObject {
    
    static var kAppIconSize:CGFloat = 48
    var sessionTask:NSURLSessionDataTask?;
    
    var appRecord:AppRecord?
    var completionHandler:(()->())?

    func startDownload()
    {
        let urlOfIcon = NSURL(string: (self.appRecord?.imageURLString)!)
        let request = NSURLRequest(URL: urlOfIcon!);
        
        // create an session data task to obtain and download the app icon
        sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (responseData, urlResponse, errorObj) -> Void in
            
            // in case we want to know the response status code
            //NSInteger HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
            
            if (errorObj != nil)
            {
                if(errorObj!.code == NSURLErrorAppTransportSecurityRequiresSecureConnection)
                {
                    // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    //
                    abort();
                }
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                // Set appIcon and clear temporary data/image
                let image:UIImage! = UIImage(data: responseData!);
                
                if (image!.size.width != IconDownloader.kAppIconSize || image!.size.height != IconDownloader.kAppIconSize)
                {
                    let itemSize = CGSizeMake(IconDownloader.kAppIconSize, IconDownloader.kAppIconSize);
                    
                    UIGraphicsBeginImageContextWithOptions(itemSize, false, 0.0);
                    
                    let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
                    
                    image.drawInRect(imageRect);
                    self.appRecord!.appIcon = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
                else
                {
                    self.appRecord!.appIcon = image;
                }
                
                // call our completion handler to tell our client that our icon is ready for display
                if (self.completionHandler != nil)
                {
                    self.completionHandler!();
                }
            })
        })
        
        sessionTask?.resume()
    }
    
    func cancelDownload()
    {
        self.sessionTask?.cancel();
        self.sessionTask = nil;
    }
}
