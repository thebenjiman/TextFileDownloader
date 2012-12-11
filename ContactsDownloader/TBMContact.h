//
//  TBMContact.h
//  ContactsDownloader
//
//  Created by Benjamin DOMERGUE on 10/12/12.
//  Copyright (c) 2012 Benjamin DOMERGUE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TBMContact : NSObject
{
	NSString *name;
	NSString *address;
	NSString *city;
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *city;

@end
