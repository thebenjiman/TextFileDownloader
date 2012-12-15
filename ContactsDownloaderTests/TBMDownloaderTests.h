//
//  TBMDownloaderTests.h
//  ContactsDownloader
//
//  Created by Benjamin DOMERGUE on 13/12/12.
//  Copyright (c) 2012 Benjamin DOMERGUE. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class TBMDownloader;
@interface TBMDownloaderTests : SenTestCase
{
	TBMDownloader *_downloader;
	id _downloaderMock;
}

@end
