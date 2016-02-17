//
//  AppDelegate.swift
//  LazyLoadingSwift
//
//  Created by Prashant Rastogi on 04/12/15.
//  Copyright © 2015 Prashant Rastogi. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static let TopPaidAppsFeed = "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=200/xml";
    
    // the queue to run our "ParseOperation"
    var queue : NSOperationQueue?
    
    // the NSOperation driving the parsing of the RSS feed
    var parser : ParseOperation?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        let urlOfRequest = NSURL(string: AppDelegate.TopPaidAppsFeed)
        let request = NSURLRequest(URL: urlOfRequest!)
        
        let sessionTask1 = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { [weak self] (responseData, urlResponse, errorObj) -> Void in
           
            // in case we want to know the response status code
            let httpStatusCode = (urlResponse as! NSHTTPURLResponse).statusCode
            print("HTTP Response Code = \(httpStatusCode)")
            
            errorObj?.code
            
            if( errorObj != nil)
            {
                let isAtsErro = errorObj?.code == NSURLErrorAppTransportSecurityRequiresSecureConnection
                
                if( isAtsErro )
                {
                    // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    //
                    abort();
                }
                else
                {
                    self!.handleError(errorObj!);
                }
            }
            else
            {
                // create the queue to run our ParseOperation
                self!.queue = NSOperationQueue()
                
                // create an ParseOperation (NSOperation subclass) to parse the RSS feed data so that the UI is not blocked
                self!.parser = ParseOperation(contents: responseData!)
                
                self!.parser?.errorHandler = {
                    (parseError :NSError) in
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                            self!.handleError(parseError)
                    })
                }
                
                self?.parser?.completionBlock = {
                    
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    if( self?.parser?.appRecordList != nil)
                    {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            let navigationController:UINavigationController = self?.window?.rootViewController as! UINavigationController
                            
                            let rootVC = navigationController.topViewController as! RootVC
                            
                            rootVC.entries = (self?.parser?.appRecordList)!
                            rootVC.tableView.reloadData()
                        })
                    }
                    
                    //self!.queue?.addOperation((self?.parser)!)
                }
                //print(self?.queue);
                //print(self?.parser);
                self!.queue?.addOperation((self?.parser)!)
                
            }
        })
        
        sessionTask1.resume()
        return true
    }
    
    // -------------------------------------------------------------------------------
    //	handleError:error
    //  Reports any error with an alert which was received from connection or loading failures.
    // -------------------------------------------------------------------------------
    func handleError(error:NSError )
    {
        let errorMessage = error.localizedDescription;
        print("Error Occured: \(errorMessage)")
    }
}

