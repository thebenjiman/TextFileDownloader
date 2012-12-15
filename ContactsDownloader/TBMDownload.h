//
//  TBMDownload.h
//  ContactsDownloader
//
//  Created by Benjamin DOMERGUE on 10/12/12.
//  Copyright (c) 2012 Benjamin DOMERGUE. All rights reserved.
//

#import "TBMDownloader.h"

@protocol TBMDownloaderDelegate;
@interface TBMDownload : NSObject
{
	NSString *URL;
	NSTimer *timer;
  id <TBMDownloaderDelegate> delegate;
	NSURLConnection *connection;
	NSMutableData *data;
}
@property (nonatomic, retain) NSString *URL;
@property (nonatomic, assign) NSTimer *timer;
@property (nonatomic, weak) id <TBMDownloaderDelegate> delegate;
@property (nonatomic, retain) NSURLConnection *connection; // File might be large, we need a connection to allow asynchronous download
@property (nonatomic, retain) NSMutableData *data;

@end
