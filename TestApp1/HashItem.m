//
//  HashItem.m
//  TestApp1
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "HashItem.h"

@implementation HashItem : NSObject

@synthesize checked = _checked;
@synthesize rowIndex = _rowIndex;
@synthesize url = _url;
@synthesize fileSize = _fileSize;
@synthesize sha1hash = _sha1hash;
@synthesize md5hash = _md5hash;

- (void) dealloc
{
    NSLog(@"dealloc %@", self);
    [super dealloc];
}

- (id) init
{
    self = [super init];
    self.rowIndex = -1;
    return self;
}

- (id) initWithURL: (NSURL *)aUrl
{
    self = [self init];
    self.url = aUrl;
    return self;
}

- (id) initWithURL: (NSURL *)aUrl hash: (NSString *) aHash
{
    self = [self init];
    self.url = aUrl;
    self.sha1hash = aHash;
    return self;
}

- (NSString *) getName
{
    return [_url path];
}

- (NSString *)description
{
    return [self descriptionUsingSeparator: @","];
}

- (NSString *) descriptionUsingSeparator: (NSString *)sep
{
    NSMutableString *buf = [[[NSMutableString alloc] init] autorelease];
    [buf appendFormat: @"HashItem: [%d] checked=%d", _rowIndex, (_checked ? 1 : 0)];
    [buf appendString: sep];
    [buf appendFormat: @"url=%@", _url];
    [buf appendString: sep];
    [buf appendFormat: @"fileSize=%ld", _fileSize];
    [buf appendString: sep];
    [buf appendFormat: @"sha1=%@", _sha1hash];
    [buf appendString: sep];
    [buf appendFormat: @"md5=%@", _md5hash];
    return buf;
}


@end

