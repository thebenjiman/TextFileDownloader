//
//  TBMDownloader.h
//  ContactsDownloader
//
//  Created by Benjamin DOMERGUE on 10/12/12.
//  Copyright (c) 2012 Benjamin DOMERGUE. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* TBMDownloader : An utility object in charge of all download operations;
 * It handles an array of TBMDownload structures that can be automatically relaunched on the provided delay.
 * It also notifies the specified delegate of the download of the success or fail of the operation.
 */

@protocol TBMDownloaderDelegate;
@interface TBMDownloader : NSObject
{
	NSMutableArray *_downloads;
}

+ (TBMDownloader *)sharedDownloader;

- (void)downloadFileAtURL:(NSString *)URLString withInterval:(NSUInteger)interval delegate:(id <TBMDownloaderDelegate>)delegate;

@end

@protocol TBMDownloaderDelegate <NSObject>

@required
- (void)downloadSucceededWithURL:(NSString *)URL data:(NSData *)data;
- (void)downloadFailedWithURL:(NSString *)URL;

@end