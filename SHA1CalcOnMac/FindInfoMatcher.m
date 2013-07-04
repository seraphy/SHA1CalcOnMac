//
//  FindInfoMatcher.m
//  SHA1CalcOnMac
//
//  Created by  on 13/06/23.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "FindInfoMatcher.h"
#import <regex.h>


@interface FindInfoPathMatcher : FindInfoMatcher

-(NSString *) itemString: (HashItem *) hashItem;

-(BOOL) isMatchWithItemString: (NSString *) itemString;

@end

@interface FindInfoPathRegexMatcher : FindInfoPathMatcher {
    @private
    regex_t regex;
    int regex_err;
}

- (id) initWithFindInfo:(FindInfo *)aFindInfo;

-(BOOL) isMatchWithItemString: (NSString *) itemString;

@end

@interface FindInfoSHA1Matcher : FindInfoMatcher

-(NSString *) itemString: (HashItem *) hashItem;

@end

@interface FindInfoMD5Matcher : FindInfoMatcher

-(NSString *) itemString: (HashItem *) hashItem;

@end

////////////////

@implementation FindInfoMatcher {
    @private
    FindInfo *_findInfo;
}

@synthesize findInfo = _findInfo;

+(FindInfoMatcher *) findInfoMatcher: (FindInfo *) aFindInfo
{
    SEARCH_MODE searchMode = [aFindInfo searchMode];
    FindInfoMatcher *inst = nil;
    switch (searchMode)
    {
        case PATH_CONTAINS:
        case PATH_STARTS_WITH:
        case PATH_ENDS_WITH:
            inst = [[FindInfoPathMatcher alloc] initWithFindInfo: aFindInfo];
            break;
            
        case PATH_REGEX:
            inst = [[FindInfoPathRegexMatcher alloc] initWithFindInfo: aFindInfo];
            break;
        
        case SHA1:
            inst = [[FindInfoSHA1Matcher alloc] initWithFindInfo: aFindInfo];
            break;
        
        case MD5:
            inst = [[FindInfoMD5Matcher alloc] initWithFindInfo: aFindInfo];
            break;
    }
    return [inst autorelease];
}

-(BOOL) isMatch: (HashItem *) hashItem
{
    NSString *targetString = [self itemString: hashItem];
    return [self isMatchWithItemString: targetString];
}

- (id) initWithFindInfo:(FindInfo *)aFindInfo
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _findInfo = [aFindInfo retain];
    return self;
}

- (void) dealloc
{
    [_findInfo release];
    _findInfo = nil;
}

-(NSString *) itemString: (HashItem *) hashItem
{
    return nil;
}

-(BOOL) isMatchWithItemString: (NSString *) itemString
{
    return NO;
}

@end

////////////////
// パスの前方・後方・部分一致

@implementation FindInfoPathMatcher

-(NSString *) itemString: (HashItem *) hashItem
{
    return [[hashItem url] path];
}

-(BOOL) isMatchWithItemString: (NSString *) itemString
{
    NSRange foundPos = [itemString rangeOfString: [[self findInfo] searchString]
                                         options: NSCaseInsensitiveSearch];
    if (foundPos.location != NSNotFound) {
        SEARCH_MODE mode = [[self findInfo] searchMode];
        if (mode == PATH_CONTAINS) {
            // 含まれる。
            return YES;
        }
        if (mode == PATH_STARTS_WITH) {
            // 先頭にマッチ
            return foundPos.location == 0;
        }
        if (mode == PATH_ENDS_WITH) {
            // 末尾にマッチ
            return foundPos.location == ([itemString length] - [[[self findInfo] searchString] length]);
        }
        return NO;
    }
    // 該当なし
    return NO;
}

@end

////////////////
// PATHの正規表現

@implementation FindInfoPathRegexMatcher

- (id) initWithFindInfo:(FindInfo *)aFindInfo
{
    id ret = [super initWithFindInfo: aFindInfo];

    NSString *searchString = [aFindInfo searchString];
    const char *strutf8 = [searchString UTF8String];
    regex_err = regcomp(&regex, strutf8, REG_EXTENDED);

    return ret;
}

- (void) dealloc
{
    regfree(&regex);
    [super dealloc];
}

-(BOOL) isMatchWithItemString: (NSString *) itemString
{
    const char *strutf8 = [itemString UTF8String];
    
    regmatch_t pmatch[1] = {0};
    if (!regex_err) {
        int isFail = regexec(&regex, strutf8, 1, pmatch, 0);
        if (!isFail) {
            // マッチしている場合
            return YES;
        }
    }
    return NO;
}

@end

////////////////
// SHA1の前方一致

@implementation FindInfoSHA1Matcher

-(NSString *) itemString: (HashItem *) hashItem
{
    return [hashItem sha1hash];
}

-(BOOL) isMatchWithItemString: (NSString *) itemString
{
    NSRange foundPos = [itemString rangeOfString: [[self findInfo] searchString]
                                         options: NSCaseInsensitiveSearch];
    if (foundPos.location != NSNotFound) {
        return foundPos.location == 0;
    }
    // 該当なし
    return NO;
}

@end

////////////////
// MD5の前方一致

@implementation FindInfoMD5Matcher

-(NSString *) itemString: (HashItem *) hashItem
{
    return [hashItem md5hash];
}

-(BOOL) isMatchWithItemString: (NSString *) itemString
{
    NSRange foundPos = [itemString rangeOfString: [[self findInfo] searchString]
                                         options: NSCaseInsensitiveSearch];
    if (foundPos.location != NSNotFound) {
        return foundPos.location == 0;
    }
    // 該当なし
    return NO;
}

@end
