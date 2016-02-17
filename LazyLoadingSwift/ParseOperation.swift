//
//  ParseOperation.swift
//  LazyLoadingSwift
//
//  Created by Prashant Rastogi on 04/12/15.
//  Copyright © 2015 Prashant Rastogi. All rights reserved.
//

import UIKit

class ParseOperation: NSOperation,NSXMLParserDelegate {
    
    // string contants found in the RSS feed
    static var kIDStr     = "id";
    static var kNameStr   = "im:name";
    static var kImageStr  = "im:image";
    static var kArtistStr = "im:artist";
    static var kEntryStr  = "entry";
    
    // A clousure to call when an error is encountered during parsing.
    var errorHandler:((NSError) -> ())?
    
    // NSArray containing AppRecord instances for each entry parsed
    // from the input data.
    // Only meaningful after the operation has completed.
    var appRecordList = NSMutableArray()
    
    var dataToParse:NSData!
    var workingArray:NSMutableArray? = NSMutableArray()
    var workingEntry:AppRecord!
    
    var workingPropertyString:NSMutableString? = NSMutableString();
    var elementsToParse = NSMutableArray();
    
    var storingCharacterData :Bool = false;
    
    // The initializer for this NSOperation subclass.
    init(contents data:NSData)
    {
        self.dataToParse = data;
        self.elementsToParse = ["id", "im:name", "im:image", "im:artist"];
    }
    
    override func main() {
        
        // The default implemetation of the -start method sets up an autorelease pool
        // just before invoking -main however it does NOT setup an excption handler
        // before invoking -main.  If an exception is thrown here, the app will be
        // terminated.
        
        // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not
        // desirable because it gives less control over the network, particularly in responding to
        // connection errors.
        //
        let parser = NSXMLParser(data: self.dataToParse) ;
        parser.delegate = self;
        parser.parse();
        
        if (!self.cancelled)
        {
            // Set appRecordList to the result of our parsing
            self.appRecordList = NSMutableArray(array: self.workingArray!);
        }
        
        self.workingArray = nil;
        self.workingPropertyString = nil;
        self.dataToParse = nil;
    }
    
    // -------------------------------------------------------------------------------
    //  parser:didStartElement:namespaceURI:qualifiedName:attributes:
    // -------------------------------------------------------------------------------
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
    {
    
        if (elementName == ParseOperation.kEntryStr)
        {
            self.workingEntry = AppRecord ();
        }
        self.storingCharacterData = self.elementsToParse.containsObject(elementName);
    }
    
    // -------------------------------------------------------------------------------
    //  parser:didEndElement:namespaceURI:qualifiedName:
    // -------------------------------------------------------------------------------
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    {
        if (self.workingEntry != nil)
        {
            if (self.storingCharacterData)
            {
                let trimmedString =
                    self.workingPropertyString!.stringByTrimmingCharactersInSet(
                        NSCharacterSet.whitespaceAndNewlineCharacterSet());
                        
                self.workingPropertyString = "";  // clear the string for next time
                if (elementName == ParseOperation.kIDStr)
                {
                    self.workingEntry.appURLString = trimmedString;
                }
                else if (elementName == ParseOperation.kNameStr)
                {
                    self.workingEntry.appName = trimmedString;
                }
                else if (elementName == ParseOperation.kImageStr)
                {
                    self.workingEntry.imageURLString = trimmedString;
                }
                else if (elementName == ParseOperation.kArtistStr)
                {
                    self.workingEntry.artist = trimmedString;
                }
            }
            else if (elementName == ParseOperation.kEntryStr)
            {
                self.workingArray!.addObject(self.workingEntry);
                self.workingEntry = nil;
            }
        }
    }
    
    // -------------------------------------------------------------------------------
    //  parser:foundCharacters:
    // -------------------------------------------------------------------------------
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        
        if (self.storingCharacterData)
        {
            self.workingPropertyString!.appendString(string);
        }
    }
    
    // -------------------------------------------------------------------------------
    //  parser:parseErrorOccurred:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        
        if ((self.errorHandler) != nil)
        {
            self.errorHandler!(parseError);
        }
    }
    
}
