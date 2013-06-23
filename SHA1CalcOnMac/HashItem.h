//
//  HashItem.h
//  SHA1CalcOnMac
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum 
{
    hashItem_needCalc,
    hashItem_loading,
    hashItem_calced,
    hashItem_failed
} HashItemState;

@interface HashItem : NSObject

/**
 * 行位置、0ベース.
 * 負の場合は削除済み
 */
@property(assign) NSInteger rowIndex;

/**
 *
 */
@property(assign, nonatomic) BOOL checked;
@property(assign, nonatomic) HashItemState state;
@property(retain, nonatomic) NSURL *url;
@property(assign, nonatomic) unsigned long long fileSize;
@property(retain, nonatomic) NSString *sha1hash;
@property(retain, nonatomic) NSString *md5hash;

@property(readonly, getter=getName) NSString *name;

- (id) initWithURL: (NSURL *)aUrl;
- (NSString *) getName;
- (NSString *) descriptionUsingSeparator: (NSString *)sep;
+ (HashItem *) hashItemFromString: (NSString *)str separator: (NSString *)sep;
@end
