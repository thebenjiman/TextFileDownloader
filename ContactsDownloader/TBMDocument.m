//
//  TBMDocument.m
//  ContactsDownloader
//
//  Created by Benjamin DOMERGUE on 10/12/12.
//  Copyright (c) 2012 Benjamin DOMERGUE. All rights reserved.
//

#import "TBMDocument.h"

#import "TBMDownloader.h"
#import "TBMContact.h"

#define URL_KEY @"url"
#define INTERVAL_KEY @"interval"

#define INFO_DICTIONARY_ENCODING_KEY @"info"

@interface TBMDocument (Private)

- (NSDictionary *)_decodedDictionaryWithData:(NSData *)data;
- (NSDictionary *)_archivableDictionary;

- (void)_updateContactsCountLabel;
- (void)_parseData:(NSData *)data;

@end

@implementation TBMDocument

- (id)init
{
    if((self = [super init]))
		{
			_contacts = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
	[_contacts release];
	[super dealloc];
}

- (NSString *)windowNibName
{
	return @"TBMDocument";
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

#pragma mark - Download entry point

- (IBAction)startDownload:(id)sender
{
	if(_URL)
	{
		[_URL release];
		_URL = nil;
	}
	_URL = [[_URLField stringValue] retain];
	NSUInteger interval = [[_intervalField stringValue] integerValue];
	
	[[TBMDownloader sharedDownloader] downloadFileAtURL:_URL withInterval:interval delegate:self];
}

#pragma mark - Document saving/reading/display

- (void)awakeFromNib
{
	if(_URL)
	{
		[_URLField setStringValue:_URL];
	}
	if(_interval)
	{
		[_intervalField setStringValue:_interval];
	}
	else [_intervalField setStringValue:@"0"];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSDictionary *info = [self _decodedDictionaryWithData:data];
	if(!info)
	{
		NSLog(@"Failed to load info dictionary");
		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
		return NO;
	}
	else
	{
		[_URL release];
		[_interval release];
		
		_URL = [[info objectForKey:URL_KEY] retain];
		_interval = [[info objectForKey:INTERVAL_KEY] retain];
		return YES;
	}
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	NSMutableData *data = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:[self _archivableDictionary] forKey:INFO_DICTIONARY_ENCODING_KEY];
	[archiver finishEncoding];
	[archiver release];
	
	if(!data)
	{
		NSLog(@"Failed to write info dictionary");
		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
		return nil;
	}
	return [data autorelease];
}

#pragma mark - Downloader delegate

- (void)downloadSucceededWithURL:(NSString *)URL data:(NSData *)data
{
	if([URL isEqualToString:_URL])
	{
		[_contacts removeAllObjects];
		[self _parseData:data];
		[_contactTableView reloadData];
		[self _updateContactsCountLabel];
	}
}

- (void)downloadFailedWithURL:(NSString *)URL
{
	NSString *localizedError = NSLocalizedString(@"Failed to download", @"Fail localized string");
	[_statusField setStringValue:localizedError];
}

@end

@implementation TBMDocument (Private)

- (NSDictionary *)_decodedDictionaryWithData:(NSData *)data
{
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	NSDictionary *info = [[unarchiver decodeObjectForKey:INFO_DICTIONARY_ENCODING_KEY] retain];
	[unarchiver finishDecoding];
	[unarchiver release];
	return [info autorelease];
}

- (NSDictionary *)_archivableDictionary
{
	NSArray *objects = [NSArray arrayWithObjects:[_URLField stringValue], [_intervalField stringValue], nil];
	NSArray *keys = [NSArray arrayWithObjects:URL_KEY, INTERVAL_KEY, nil];
	return [NSDictionary dictionaryWithObjects:objects forKeys:keys];
}

- (void)_updateContactsCountLabel
{
	NSString *localizedStatus = NSLocalizedString(@"Number of lines", @"Number of lines localized string");
	[_statusField setStringValue:[NSString stringWithFormat:localizedStatus, [_contacts count]]];
}

- (void)_parseData:(NSData *)data
{
	NSString *fileContent = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSArray *lines = [fileContent componentsSeparatedByString:@"\n"];
	for(NSString *line in lines)
	{
		NSArray *words = [line componentsSeparatedByString:@"\t"];
		TBMContact *contact = [[TBMContact alloc] init];
		
		NSString *name = [words objectAtIndex:0];
		if(name)
		{
			contact.name = name;
		}
		
		NSString *address = [words objectAtIndex:1];
		if(address)
		{
			contact.address = address;
		}
		
		NSString *city = [words objectAtIndex:2];
		if(city)
		{
			contact.city = city;
		}
		[_contacts addObject:contact];
		[contact release];
	}
}

@end

#define NAME_TABLE_VIEW_IDENTIFIER @"name"
#define ADDRESS_TABLE_VIEW_IDENTIFIER @"address"
#define CITY_TABLE_VIEW_IDENTIFIER @"city"

@implementation TBMDocument (NSTableViewDataSource)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_contacts count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	TBMContact *contact = [_contacts objectAtIndex:row];
	if([[tableColumn identifier] isEqualToString:NAME_TABLE_VIEW_IDENTIFIER])
	{
		return contact.name;
	}
	if([[tableColumn identifier] isEqualToString:ADDRESS_TABLE_VIEW_IDENTIFIER])
	{
		return contact.address;
	}
	if([[tableColumn identifier] isEqualToString:CITY_TABLE_VIEW_IDENTIFIER])
	{
		return contact.city;
	}
	return @"";
}

@end
