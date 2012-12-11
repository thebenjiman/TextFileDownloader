//
//  TBMDocument.h
//  ContactsDownloader
//
//  Created by Benjamin DOMERGUE on 10/12/12.
//  Copyright (c) 2012 Benjamin DOMERGUE. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TBMDownloader.h"

@protocol TBMDownloaderDelegate;
@interface TBMDocument : NSDocument <TBMDownloaderDelegate , NSTableViewDataSource>
{
	IBOutlet NSTextField *_statusField;
	IBOutlet NSTextField *_URLField;
	IBOutlet NSTextField *_intervalField;
	IBOutlet NSTableView *_contactTableView;
	
	NSString *_URL;
	NSString *_interval;
	NSMutableArray *_contacts;
}

- (IBAction)startDownload:(id)sender;

@end
