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

+ (HashItem *) hashItemFromString: (NSString *)str separator: (NSString *)sep
{
    NSArray *cols = [str componentsSeparatedByString: sep];
    NSInteger len = [cols count];
    if (len > 1) {
        if ([[cols objectAtIndex: 0] hasPrefix: @"HashItem:"]) {
            // シグネチャ確認OK
            HashItem *result = [[[HashItem alloc] init] autorelease];
            for (NSInteger idx = 1; idx < len; idx++) {
                NSString *col = [cols objectAtIndex: idx];
                NSArray *tokens = [col componentsSeparatedByString: @"="];
                if ([tokens count] == 2) {
                    NSString *key = [tokens objectAtIndex: 0];
                    NSString *val = [[tokens objectAtIndex: 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([key isEqualToString: @"url"]) {
                        NSURL *url = [NSURL URLWithString: val];
                        // [val stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                        [result setUrl: url];
                        
                    } else if ([key isEqualToString: @"fileSize"]) {
                        [result setFileSize: [val longLongValue]];
                        
                    } else if ([key isEqualToString: @"sha1"]) {
                        [result setSha1hash: val];
                        
                    } else if ([key isEqualToString: @"md5"]) {
                        [result setMd5hash: val];
                    }
                }
            }
            if ([result url]) {
                [result setChecked: YES];
                return result;
            }
        }
    }
    NSLog(@"unknown :%@", str);
    return nil;
}

@end

