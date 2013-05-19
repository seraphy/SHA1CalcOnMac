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

- (NSString *)description {
    return [NSString stringWithFormat: @"HashItem: [%d] checked=%d, url=%@, fileSize=%ld, sha1=%@, md5=%@",
            _rowIndex, (_checked ? 1 : 0), _url, _fileSize, _sha1hash, _md5hash];
}

@end

