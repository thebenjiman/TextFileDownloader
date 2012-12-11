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

@implementation TBMDownloader

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

- (TBMDownload *)_downloadObjectWithURL:(NSString *)URLString delegate:(id <TBMDownloaderDelegate>)delegate
{
	TBMDownload *download = [[TBMDownload alloc] init];
	download.delegate = delegate;
	download.URL = URLString;
	return [download autorelease];
}

- (void)_removeActiveDownloadWithDelegate:(id <TBMDownloaderDelegate>)delegate
{
	TBMDownload *downloadToRemove = nil;
	for(TBMDownload *managedDownload in _downloads)
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
		[_downloads removeObject:downloadToRemove];
	}
}

- (void)downloadFileAtURL:(NSString *)URLString withInterval:(NSUInteger)interval delegate:(id <TBMDownloaderDelegate>)delegate
{
	[self _removeActiveDownloadWithDelegate:delegate];
	
	TBMDownload *download = [self _downloadObjectWithURL:URLString delegate:delegate];
	if(interval != 0)
	{
		NSTimer *timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(timerDidFire:) userInfo:download repeats:YES];
		download.timer = [timer retain];
		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	}
	[_downloads addObject:download];
	[self startDownload:download];
}

- (NSURLConnection *)_connectionForURL:(NSString *)URL
{
	NSURL *url = [NSURL URLWithString:URL];
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	return [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
}

- (void)startDownload:(TBMDownload *)download
{
	NSURLConnection *connection = [self _connectionForURL:download.URL];
	if(connection)
	{
		if(!download.connection)
		{
			download.connection = [connection retain];
			download.data = [[NSMutableData data] retain];
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
	for(TBMDownload *download in _downloads)
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
	TBMDownload *download = [self _downloadForConnection:connection];
	if(download)
	{
		[download.delegate downloadFailedWithURL:download.URL];
		[download.data release];
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
		download.connection = nil;
		
		if(!download.timer)
		{
			[_downloads removeObject:download];
		}
	}
	[connection release];
}

@end
