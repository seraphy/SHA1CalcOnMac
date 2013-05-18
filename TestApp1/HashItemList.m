//
//  HashItemList.m
//  TestApp1
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "HashItemList.h"


@implementation HashItemList {
@private
    /// テーブルビューに格納するHashItemのリスト
    NSMutableArray *array;
    
    /// 最後に保存してからハッシュ値が新たに計算されたか配列が増えた場合
    BOOL modified;
}

@synthesize delegate = _delegate;
@synthesize modified = _modified;

- (id) init
{
    self = [super init];
    array = [[NSMutableArray alloc] init];
    return self;
}

- (void) dealloc
{
    [array release];
    [super dealloc];
}

- (void) addWithURLArray: (NSArray *)urls
{
    @synchronized(array) {
        for (NSURL *url in urls)
        {
            NSLog(@"%@", [url path]);
            HashItem *hashItem = [[HashItem alloc] initWithURL: url];
            [array addObject: hashItem];
            [hashItem setRowIndex: [array count] - 1];
            [hashItem release];
        }

        _modified = true;
    }
}

- (void) notifyChangeHashItem: (HashItem *) hashItem
{
    _modified = true;
    if ([_delegate respondsToSelector: @selector(notifyChangeHashItem:)]) {
        [_delegate notifyChangeHashItem: hashItem];
    }
}

- (HashItem *) getItemByIndex: (NSInteger) rowIndex;
{
    HashItem *hashItem = nil;
    @synchronized(array) {
        NSInteger cnt = [array count];
        if (cnt > rowIndex && rowIndex >= 0) {
            hashItem = [array objectAtIndex: rowIndex];
        }
    }
    return hashItem;
}

- (HashItem *) getFirstUncalcuratedItem
{
    NSLog(@"getFirstUncalcuratedItem");
    @synchronized(array) {
        NSUInteger mx = [array count];
        for (NSUInteger idx = 0; idx < mx; idx++) {
            HashItem *item = [array objectAtIndex: idx];
            if ([item.sha1hash length] == 0) {
                // スレッドで使っている間は解放されいようにretainする
                return [item retain];
            }
        }
    }
    return nil;
}

- (void) sortUsingDescriptors: sortDescriptors
{
    @synchronized(array) {
        [array sortUsingDescriptors: sortDescriptors];
        NSInteger count = [array count];
        for (NSInteger rowIndex = 0; rowIndex < count; rowIndex++) {
            [[array objectAtIndex: rowIndex] setRowIndex: rowIndex];
        }
    }
}

- (NSInteger) count
{
    @synchronized(array) {
        return [array count];
    }
}

- (BOOL) isModified
{
    return modified;
}

@end
