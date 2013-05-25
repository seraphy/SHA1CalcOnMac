//
//  HashItem.h
//  SHA1CalcOnMac
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HashItem : NSObject

/**
 * 行位置、0ベース.
 * 負の場合は削除済み
 */
@property(assign) NSInteger rowIndex;

/**
 *
 */
@property(assign) BOOL checked;
@property(retain) NSURL *url;
@property(assign) unsigned long long fileSize;
@property(retain) NSString *sha1hash;
@property(retain) NSString *md5hash;

@property(readonly, getter=getName) NSString *name;

- (id) initWithURL: (NSURL *)aUrl;
- (id) initWithURL: (NSURL *)aUrl hash: (NSString *) aHash;
- (NSString *) getName;
- (NSString *) descriptionUsingSeparator: (NSString *)sep;
+ (HashItem *) hashItemFromString: (NSString *)str separator: (NSString *)sep;
@end
