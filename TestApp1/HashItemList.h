//
//  HashItemList.h
//  TestApp1
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HashItem.h"

/**
 * ハッシュアイテムの変更通知を受け取るプロトコル
 */
@protocol HashItemListNotification <NSObject>
@optional

/**
 * ハッシュ値が変更されたことを通知する.
 * @param hashItem ハッシュアイテム
 */
- (void) notifyChangeHashItem: (HashItem *) hashItem;

@end


/**
 * パスとハッシュ値を保持するクラス.
 */
@interface HashItemList : NSObject

@property (retain) id<HashItemListNotification> delegate;
@property (assign) BOOL modified;

- (void) addWithURLArray: (NSArray *)urls;
- (HashItem *) getItemByIndex: (NSInteger) rowIndex;
- (HashItem *) getFirstUncalcuratedItem;
- (void) notifyChangeHashItem: (HashItem *) hashItem;
- (NSInteger) count;
- (void) sortUsingDescriptors: sortDescriptors;

@end
