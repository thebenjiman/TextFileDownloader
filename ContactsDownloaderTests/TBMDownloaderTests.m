//
//  TBMDownloaderTests.m
//  ContactsDownloader
//
//  Created by Benjamin DOMERGUE on 13/12/12.
//  Copyright (c) 2012 Benjamin DOMERGUE. All rights reserved.
//

#import "TBMDownloaderTests.h"
#import "TBMDownloader.h"

#import "TBMDownload.h" //For mocking purpose

#import <OCMock/OCMock.h>

@interface TBMDownloader (MockedMethods)
@property (nonatomic, retain) NSMutableArray *downloads;
- (TBMDownload *)_cleanDownload;
- (void)_autoDownloadTimerWithInterval:(NSUInteger)interval download:(TBMDownload *)download;
- (NSRunLoop *)_currentRunLoop;
- (NSURLConnection *)_connectionForURL:(NSString *)URL;
- (NSMutableData *)_newMutableData;
@end

@interface TBMDownloader (TestedMethods)
- (TBMDownload *)_downloadObjectWithURL:(NSString *)URLString delegate:(id <TBMDownloaderDelegate>)delegate;
- (void)_removeActiveDownloadWithDelegate:(id <TBMDownloaderDelegate>)delegate;
- (void)startDownload:(TBMDownload *)download;
- (void)timerDidFire:(NSTimer *)timer;
- (TBMDownload *)_downloadForConnection:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
@end

@implementation TBMDownloaderTests

- (void)setUp
{
	[super setUp];
	
	_downloader = [[TBMDownloader alloc] init];
	_downloaderMock = [OCMockObject partialMockForObject:_downloader];
}

- (void)tearDown
{
	[_downloader release];
	
	[super tearDown];
}

#define FAKE_URL_STRING @"http://fake"

- (void)testDownloadObjectWithURLDelegate
{
	id <TBMDownloaderDelegate> fakeDelegate = [OCMockObject niceMockForProtocol:@protocol(TBMDownloaderDelegate)];
	id downloadMock = [OCMockObject niceMockForClass:[TBMDownload class]];

	[[[_downloaderMock expect] andReturn:downloadMock] _cleanDownload];
	[(TBMDownload *)[downloadMock expect] setURL:FAKE_URL_STRING];
	[[downloadMock expect] setDelegate:fakeDelegate];
	
	STAssertEqualObjects([_downloader _downloadObjectWithURL:FAKE_URL_STRING delegate:fakeDelegate], downloadMock, @"Returned object mismatch");
	
	[downloadMock verify];
	[_downloaderMock verify];
}

- (void)testRemoveActiveDownloadWithDelegate
{
	id fakeDownload1 = [OCMockObject niceMockForClass:[TBMDownload class]];
	id <TBMDownloaderDelegate> fakeDelegate1 = [OCMockObject niceMockForProtocol:@protocol(TBMDownloaderDelegate)];
	id fakeTimer1 = [[OCMockObject niceMockForClass:[NSTimer class]] retain];
	[[[fakeDownload1 stub] andReturn:fakeTimer1] timer];
	[[[fakeDownload1 stub] andReturn:fakeDelegate1] delegate];
	
	id fakeDownload2 = [OCMockObject niceMockForClass:[TBMDownload class]];
	id <TBMDownloaderDelegate> fakeDelegate2 = [OCMockObject niceMockForProtocol:@protocol(TBMDownloaderDelegate)];
	id fakeTimer2 = [OCMockObject niceMockForClass:[NSTimer class]];
	[[[fakeDownload2 stub] andReturn:fakeTimer2] timer];
	[[[fakeDownload2 stub] andReturn:fakeDelegate2] delegate];
	
	NSMutableArray *activeDownloads = [NSMutableArray arrayWithObjects:fakeDownload1, fakeDownload2, nil];
	[[[_downloaderMock expect] andReturn:activeDownloads] downloads];
	
	id activeDownloadsMock = [OCMockObject partialMockForObject:activeDownloads];
	[[activeDownloadsMock expect] removeObject:fakeDownload1];
	[[activeDownloadsMock reject] removeObject:fakeDownload2];
	
	[[fakeTimer1 expect] invalidate];
	//[[fakeTimer1 expect] release];
	
	[_downloader _removeActiveDownloadWithDelegate:fakeDelegate1];
	
	[fakeTimer1 verify];
	[activeDownloadsMock verify];
	[_downloaderMock verify];
}

#define FAKE_INTERVAL 5

- (void)testDownloadFileAtURLWithIntervalDelegate
{
	id fakeTimer = [OCMockObject niceMockForClass:[NSTimer class]];
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	id <TBMDownloaderDelegate> fakeDelegate = [OCMockObject niceMockForProtocol:@protocol(TBMDownloaderDelegate)];
	
	[[_downloaderMock expect] _removeActiveDownloadWithDelegate:fakeDelegate];
	[[[_downloaderMock expect] andReturn:fakeDownload] _downloadObjectWithURL:FAKE_URL_STRING delegate:fakeDelegate];
	[[[_downloaderMock expect] andReturn:fakeTimer] _autoDownloadTimerWithInterval:FAKE_INTERVAL download:fakeDownload];
	
	id fakeLoop = [OCMockObject niceMockForClass:[NSRunLoop class]];
	[[fakeDownload expect] setTimer:fakeTimer];
	[[[_downloaderMock expect] andReturn:fakeLoop] _currentRunLoop];
	[[fakeLoop expect] addTimer:fakeTimer forMode:NSDefaultRunLoopMode];
	
	NSMutableArray *activeDownloads = [NSMutableArray array];
	id activeDownloadsMock = [OCMockObject partialMockForObject:activeDownloads];
	[[[_downloaderMock expect] andReturn:activeDownloadsMock] downloads];
	[[activeDownloadsMock expect] addObject:fakeDownload];
	
	[[_downloaderMock expect] startDownload:fakeDownload];
	
	[_downloader downloadFileAtURL:FAKE_URL_STRING withInterval:FAKE_INTERVAL delegate:fakeDelegate];
	
	[fakeLoop verify];
	[activeDownloadsMock verify];
	[_downloaderMock verify];
}

- (void)testDownloadFileAtURLWithIntervalDelegateWithNoInterval
{
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	id <TBMDownloaderDelegate> fakeDelegate = [OCMockObject niceMockForProtocol:@protocol(TBMDownloaderDelegate)];
	
	[[_downloaderMock expect] _removeActiveDownloadWithDelegate:fakeDelegate];
	[[[_downloaderMock expect] andReturn:fakeDownload] _downloadObjectWithURL:FAKE_URL_STRING delegate:fakeDelegate];
	[[_downloaderMock reject] _autoDownloadTimerWithInterval:FAKE_INTERVAL download:fakeDownload];
	
	[[fakeDownload reject] setTimer:OCMOCK_ANY];
	[[_downloaderMock reject] _currentRunLoop];
	
	NSMutableArray *activeDownloads = [NSMutableArray array];
	id activeDownloadsMock = [OCMockObject partialMockForObject:activeDownloads];
	[[[_downloaderMock expect] andReturn:activeDownloadsMock] downloads];
	[[activeDownloadsMock expect] addObject:fakeDownload];
	
	[[_downloaderMock expect] startDownload:fakeDownload];
	
	[_downloader downloadFileAtURL:FAKE_URL_STRING withInterval:0 delegate:fakeDelegate];
	
	[activeDownloadsMock verify];
	[_downloaderMock verify];
}

- (void)testStartDownload
{
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	[[[fakeDownload expect] andReturn:FAKE_URL_STRING] URL];
	
	id fakeConnection = [[OCMockObject niceMockForClass:[NSURLConnection class]] retain];
	[[[_downloaderMock expect] andReturn:fakeConnection] _connectionForURL:FAKE_URL_STRING];
	[[[fakeDownload expect] andReturn:nil] connection];
	
	//[[fakeConnection expect] retain];
	[[fakeDownload expect] setConnection:fakeConnection];
	id fakeData = [[OCMockObject niceMockForClass:[NSMutableData class]] retain];
	[[[_downloaderMock expect] andReturn:fakeData] _newMutableData];
	[[fakeDownload expect] setData:fakeData];
	
	[_downloader startDownload:fakeDownload];
	
	[fakeDownload verify];
	[fakeConnection verify];
	[_downloaderMock verify];
}

- (void)testStartDownloadWithAlreadyRunningDownload
{
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	[[[fakeDownload expect] andReturn:FAKE_URL_STRING] URL];
	
	id fakeConnection = [[OCMockObject niceMockForClass:[NSURLConnection class]] retain];
	[[[_downloaderMock expect] andReturn:fakeConnection] _connectionForURL:FAKE_URL_STRING];
	
	[[[fakeDownload expect] andReturn:fakeConnection] connection];
	[[fakeDownload reject] setConnection:OCMOCK_ANY];
	[[fakeDownload reject] setData:OCMOCK_ANY];

	[_downloader startDownload:fakeDownload];
	
	[fakeDownload verify];
	[_downloaderMock verify];
}

- (void)testStartDownloadWithConnectionCreationError
{
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	[[[fakeDownload expect] andReturn:FAKE_URL_STRING] URL];
	
	[[[_downloaderMock expect] andReturn:nil] _connectionForURL:FAKE_URL_STRING];
	
	[[fakeDownload reject] connection];
	[[fakeDownload reject] setConnection:OCMOCK_ANY];
	[[fakeDownload reject] setData:OCMOCK_ANY];
	
	id fakeDelegate = [OCMockObject niceMockForProtocol:@protocol(TBMDownloaderDelegate)];
	[[[fakeDownload expect] andReturn:fakeDelegate] delegate];
	[[[fakeDownload expect] andReturn:FAKE_URL_STRING] URL]; //Log
	[[[fakeDownload expect] andReturn:FAKE_URL_STRING] URL]; //delegate
	[[fakeDelegate expect] downloadFailedWithURL:FAKE_URL_STRING];
	
	[_downloader startDownload:fakeDownload];
	
	[fakeDelegate verify];
	[fakeDownload verify];
	[_downloaderMock verify];
}

- (void)timerDidFire
{
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	id fakeTimer = [OCMockObject niceMockForClass:[NSTimer class]];
	[[[fakeTimer expect] andReturn:fakeDownload] userInfo];
	
	[[_downloaderMock expect] startDownload:fakeDownload];
	
	[_downloader timerDidFire:fakeTimer];
	
	[fakeTimer verify];
	[_downloaderMock verify];
}

- (void)testDownloadForConnection
{
	id fakeDownload1 = [OCMockObject niceMockForClass:[TBMDownload class]];
	id fakeConnection1 = [[OCMockObject niceMockForClass:[NSURLConnection class]] retain];
	[[[fakeDownload1 stub] andReturn:fakeConnection1] connection];
	
	id fakeDownload2 = [OCMockObject niceMockForClass:[TBMDownload class]];
	id fakeConnection2 = [[OCMockObject niceMockForClass:[NSURLConnection class]] retain];
	[[[fakeDownload2 stub] andReturn:fakeConnection2] connection];
	
	NSMutableArray *activeDownloads = [NSMutableArray arrayWithObjects:fakeDownload1, fakeDownload2, nil];
	[[[_downloaderMock expect] andReturn:activeDownloads] downloads];
	
	STAssertEqualObjects([_downloader _downloadForConnection:fakeConnection1], fakeDownload1, @"Returned download mismatch");
	
	[_downloaderMock verify];
}

- (void)testConnectionDidReceiveData
{
	id fakeConnection = [[OCMockObject niceMockForClass:[NSURLConnection class]] retain];
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	
	[[[_downloaderMock expect] andReturn:fakeDownload] _downloadForConnection:fakeConnection];
	
	id fakeData = [[OCMockObject niceMockForClass:[NSMutableData class]] retain];
	[[[fakeDownload expect] andReturn:fakeData] data];
	[[fakeData expect] appendData:OCMOCK_ANY];
	
	[_downloader connection:fakeConnection didReceiveData:[NSData data]];
	
	[_downloaderMock verify];
	[fakeDownload verify];
	[fakeData verify];
}

- (void)testConnectionDidReceiveDataWithCanceledDownload
{
	id fakeConnection = [[OCMockObject niceMockForClass:[NSURLConnection class]] retain];
	
	[[[_downloaderMock expect] andReturn:nil] _downloadForConnection:fakeConnection];
	
	//[[fakeConnection expect] release];
	
	[_downloader connection:fakeConnection didReceiveData:[NSData data]];
	
	[_downloaderMock verify];
	[fakeConnection verify];
}

- (void)testConnectionDidFailWithError
{
	id fakeConnection = [[OCMockObject niceMockForClass:[NSURLConnection class]] retain];
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	
	[[[_downloaderMock expect] andReturn:fakeDownload] _downloadForConnection:fakeConnection];
	
	id fakeData = [[OCMockObject niceMockForClass:[NSMutableData class]] retain];
	id fakeDelegate = [OCMockObject niceMockForProtocol:@protocol(TBMDownloaderDelegate)];
	[[[fakeDownload expect] andReturn:fakeDelegate] delegate];
	[[[fakeDownload expect] andReturn:FAKE_URL_STRING] URL];
	[[[fakeDownload expect] andReturn:fakeData] data];
	[[fakeDelegate expect] downloadFailedWithURL:FAKE_URL_STRING];
	//[[fakeData expect] release];
	[[fakeDownload expect] setConnection:nil];
	
	//[[fakeConnection expect] release];
	
	[_downloader connection:fakeConnection didFailWithError:nil];
	
	[fakeConnection verify];
	[fakeDownload verify];
	[fakeData verify];
	[fakeDelegate verify];
	[_downloaderMock verify];
}

- (void)testConnectionDidFinishLoading
{
	id fakeConnection = [[OCMockObject niceMockForClass:[NSURLConnection class]] retain];
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	[[[_downloaderMock expect] andReturn:fakeDownload] _downloadForConnection:fakeConnection];
	
	id fakeData = [[OCMockObject niceMockForClass:[NSMutableData class]] retain];
	id fakeDelegate = [OCMockObject niceMockForProtocol:@protocol(TBMDownloaderDelegate)];
	[[[fakeDownload expect] andReturn:fakeDelegate] delegate];
	[[[fakeDownload expect] andReturn:FAKE_URL_STRING] URL];
	[[[fakeDownload expect] andReturn:fakeData] data];
	[[fakeDelegate expect] downloadSucceededWithURL:FAKE_URL_STRING data:fakeData];
	//[[fakeData expect] release];
	
	id fakeTimer = [OCMockObject niceMockForClass:[NSTimer class]];
	[[[fakeDownload expect] andReturn:fakeTimer] timer];
	
	//[[fakeConnection expect] release];
	
	[_downloader connectionDidFinishLoading:fakeConnection];
	
	[fakeConnection verify];
	[fakeData verify];
	[fakeDownload verify];
	[fakeDelegate verify];
}

- (void)testConnectionDidFinishLoadingWithNonRepetitiveDownload
{
	id fakeConnection = [[OCMockObject niceMockForClass:[NSURLConnection class]] retain];
	id fakeDownload = [OCMockObject niceMockForClass:[TBMDownload class]];
	[[[_downloaderMock expect] andReturn:fakeDownload] _downloadForConnection:fakeConnection];
	
	id fakeData = [[OCMockObject niceMockForClass:[NSMutableData class]] retain];
	id fakeDelegate = [OCMockObject niceMockForProtocol:@protocol(TBMDownloaderDelegate)];
	[[[fakeDownload expect] andReturn:fakeDelegate] delegate];
	[[[fakeDownload expect] andReturn:FAKE_URL_STRING] URL];
	[[[fakeDownload expect] andReturn:fakeData] data];
	[[fakeDelegate expect] downloadSucceededWithURL:FAKE_URL_STRING data:fakeData];
	//[[fakeData expect] release];
	
	id fakeActiveDownloads = [OCMockObject niceMockForClass:[NSMutableArray class]];
	[[[_downloaderMock expect] andReturn:fakeActiveDownloads] downloads];
	[[[fakeDownload expect] andReturn:nil] timer];
	[[fakeActiveDownloads expect] removeObject:fakeDownload];
	
	//[[fakeConnection expect] release];
	
	[_downloader connectionDidFinishLoading:fakeConnection];
	
	[fakeConnection verify];
	[fakeData verify];
	[fakeDownload verify];
	[fakeDelegate verify];
}


@end
