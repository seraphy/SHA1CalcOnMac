//
//  HashItem.m
//  SHA1CalcOnMac
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "HashItem.h"

@implementation HashItem : NSObject

@synthesize checked = _checked;
@synthesize state = _state;
@synthesize rowIndex = _rowIndex;
@synthesize url = _url;
@synthesize fileSize = _fileSize;
@synthesize sha1hash = _sha1hash;
@synthesize md5hash = _md5hash;

- (void) dealloc
{
    self.checked = NO;
    self.state = hashItem_needCalc;
    self.rowIndex = 0;
    self.fileSize = 0;
    self.sha1hash = nil;
    self.md5hash = nil;
    self.url = nil;

    [super dealloc];
}

- (id) init
{
    self = [super init];
    self.rowIndex = -1;
    self.state = hashItem_needCalc;
    return self;
}

- (id) initWithURL: (NSURL *)aUrl
{
    self = [self init];
    self.url = aUrl;
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
    [buf appendFormat: @"HashItem: [%ld]", _rowIndex];
    [buf appendString: sep];
    [buf appendFormat: @"checked=%d", (_checked ? 1 : 0)];
    [buf appendString: sep];
    [buf appendFormat: @"url=%@", _url];
    [buf appendString: sep];
    [buf appendFormat: @"fileSize=%lld", _fileSize];
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
    if (len <= 1) {
        NSLog(@"invalid-separator? :%@", str);
        return nil;
    }

    if (![[cols objectAtIndex: 0] hasPrefix: @"HashItem:"]) {
        // シグネチャ確認
        NSLog(@"invalid-signature? :%@", str);
        return nil;
    }

    HashItem *result = [[[HashItem alloc] init] autorelease];
    for (NSInteger idx = 1; idx < len; idx++) {
        NSString *column = [cols objectAtIndex: idx];
        
        NSScanner *scanner = [NSScanner scannerWithString: column];
        NSString *key;
        if (![scanner scanUpToString: @"=" intoString: &key]) {
            NSLog(@"invalid-keyvalue-format: %@", str);
            return nil;
        }
        key = [key stringByTrimmingCharactersInSet:
               [NSCharacterSet whitespaceAndNewlineCharacterSet]];

        [scanner scanString: @"=" intoString: nil];
        NSString *val = [[column substringFromIndex: [scanner scanLocation]] 
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([key isEqualToString: @"url"]) {
            [result setUrl: [NSURL URLWithString: val]];
            
        } else if ([key isEqualToString: @"checked"]) {
            [result setChecked: [val intValue] != 0];
            
        } else if ([key isEqualToString: @"fileSize"]) {
            [result setFileSize: [val longLongValue]];
            
        } else if ([key isEqualToString: @"sha1"]) {
            [result setSha1hash: val];
            
        } else if ([key isEqualToString: @"md5"]) {
            [result setMd5hash: val];
        }
    }
    
    // ハッシュ値が計算済みであれば成功とみなす.(そうでなければ失敗とみなす)
    if ([[result sha1hash] length] != 0) {
        [result setState: hashItem_calced];
    } else {
        [result setState: hashItem_failed];
    }
    
    if ([result url]) {
        return result;
    }

    NSLog(@"invalid-url? :%@", str);
    return nil;
}

@end

