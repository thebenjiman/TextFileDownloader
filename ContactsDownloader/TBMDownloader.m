//
//  TBMDownloader.m
//  ContactsDownloader
//
//  Created by Benjamin DOMERGUE on 10/12/12.
//  Copyright (c) 2012 Benjamin DOMERGUE. All rights reserved.
//

#import "TBMDownloader.h"
#import "TBMDownload.h"

static TBMDownloader *__sharedDownloader = nil;

@interface TBMDownloader (/* For mocking purpose */)
@property (nonatomic, retain) NSMutableArray *downloads;
@end

@implementation TBMDownloader
@synthesize downloads = _downloads;

+ (TBMDownloader *)sharedDownloader
{
	if(__sharedDownloader == nil)
	{
		__sharedDownloader = [[TBMDownloader alloc] init];
	}
	return __sharedDownloader;
}

- (id)init
{
	if((self = [super init]))
	{
		_downloads = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_downloads release];
	[super dealloc];
}

- (TBMDownload *)_cleanDownload
{
	return [[[TBMDownload alloc] init] autorelease];
}

- (TBMDownload *)_downloadObjectWithURL:(NSString *)URLString delegate:(id <TBMDownloaderDelegate>)delegate
{
	TBMDownload *download = [self _cleanDownload];
	download.delegate = delegate;
	download.URL = URLString;
	return download;
}

- (void)_removeActiveDownloadWithDelegate:(id <TBMDownloaderDelegate>)delegate
{
	TBMDownload *downloadToRemove = nil;
	NSMutableArray *downloads = self.downloads;
	for(TBMDownload *managedDownload in downloads)
	{
		if(managedDownload.delegate == delegate)
		{
			downloadToRemove = managedDownload;
		}
	}
	if(downloadToRemove)
	{
		[downloadToRemove.timer invalidate];
		[downloadToRemove.timer release];
		[downloads removeObject:downloadToRemove];
	}
}

- (NSTimer *)_autoDownloadTimerWithInterval:(NSUInteger)interval download:(TBMDownload *)download
{
	
	return [NSTimer timerWithTimeInterval:interval target:self selector:@selector(timerDidFire:) userInfo:download repeats:YES];
}

- (NSRunLoop *)_currentRunLoop
{
	return [NSRunLoop currentRunLoop];
}

- (void)downloadFileAtURL:(NSString *)URLString withInterval:(NSUInteger)interval delegate:(id <TBMDownloaderDelegate>)delegate
{
	[self _removeActiveDownloadWithDelegate:delegate];
	
	TBMDownload *download = [self _downloadObjectWithURL:URLString delegate:delegate];
	if(interval != 0)
	{
		NSTimer *timer = [self _autoDownloadTimerWithInterval:interval download:download];
		download.timer = [timer retain];
		[[self _currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	}
	[self.downloads addObject:download];
	[self startDownload:download];
}

- (NSURLConnection *)_connectionForURL:(NSString *)URL
{
	NSURL *url = [NSURL URLWithString:URL];
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	return [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
}

- (NSMutableData *)_newMutableData
{
	return [[NSMutableData data] retain];
}

- (void)startDownload:(TBMDownload *)download
{
	NSURLConnection *connection = [self _connectionForURL:download.URL];
	if(connection)
	{
		if(!download.connection)
		{
			download.connection = [connection retain];
			download.data = [self _newMutableData];
		}
		else
		{
			NSLog(@"Download already in progress, skyping");
		}
	}
	else
	{
		NSLog(@"Failed to start download at URL: %@", download.URL);
		[download.delegate downloadFailedWithURL:download.URL];
	}
}

- (void)timerDidFire:(NSTimer *)timer
{
	TBMDownload *download = [timer userInfo];
	[self startDownload:download];
}

- (TBMDownload *)_downloadForConnection:(NSURLConnection *)connection
{
	for(TBMDownload *download in self.downloads)
	{
		if(download.connection == connection)
		{
			return download;
		}
	}
	return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	TBMDownload *download = [self _downloadForConnection:connection];
	if(!download)
	{
		[connection release];
	}
	else
	{
		[download.data appendData:data];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"Error while downloading: %@", error);
	
	TBMDownload *download = [self _downloadForConnection:connection];
	if(download)
	{
		[download.delegate downloadFailedWithURL:download.URL];
		[download.data release];
		download.data = nil;
		download.connection = nil;
	}
	[connection release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	TBMDownload *download = [self _downloadForConnection:connection];
	if(download)
	{
		[download.delegate downloadSucceededWithURL:download.URL data:download.data];
		[download.data release];
		download.data = nil;
		download.connection = nil;
		
		if(!download.timer)
		{
			[self.downloads removeObject:download];
		}
	}
	[connection release];
}

@end
