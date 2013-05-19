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

@synthesize documentURL = _documentURL;
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

- (void) addWithURL: (NSURL *) url
{
    // ファイルの実在チェック
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *path = [url path];
    BOOL dir = NO;
    if ([fileMgr fileExistsAtPath: path isDirectory: &dir]) {
        if (dir) {
            // ディレクトリであれば中身をリストして再帰的に呼び出す
            NSDirectoryEnumerator *enm = [fileMgr enumeratorAtPath: path];
            NSString *child = nil;
            while ((child = [enm nextObject]) != nil) {
                NSString *fullPath = [path stringByAppendingPathComponent: child];
                [self addWithURL: [NSURL fileURLWithPath: fullPath]];
            }
            return;
        }
        
        // ファイルであれば、
        // ファイルサイズの取得
        NSError *err = nil;
        NSDictionary *attr = [fileMgr attributesOfItemAtPath: path error: &err];
        NSNumber *fileSize = [attr objectForKey: NSFileSize];
        
        // アイテムの設定
        @synchronized(array) {
            HashItem *hashItem = [[HashItem alloc] initWithURL: url];
            [hashItem setFileSize: [fileSize unsignedLongLongValue]];
            [array addObject: hashItem];
            [hashItem setRowIndex: [array count] - 1];
            [hashItem release];
        }

        // 変更フラグON
        _modified = true;
    }
}

- (void) addWithURLArray: (NSArray *)urls
{
    @synchronized(array) {
        for (NSURL *url in urls) {
            [self addWithURL: url];
        }
    }
}

- (void) clear
{
    @synchronized (array) {
        NSInteger count = [array count];
        for (NSInteger rowIndex = 0; rowIndex < count; rowIndex++) {
            [[array objectAtIndex: rowIndex] setRowIndex: -1];
        }
        [array removeAllObjects];
    }
}

- (void ) removeByIndexes: selrows
{
    @synchronized(array) {
        [selrows enumerateIndexesWithOptions: NSEnumerationReverse
                                  usingBlock: ^(NSUInteger idx, BOOL *stop) {
                                      [[array objectAtIndex: idx] setRowIndex: -1];
                                      [array removeObjectAtIndex: idx];
                                  }];
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

- (NSArray *) getItemByIndexes: (NSIndexSet *) indexes
{
    NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
    @synchronized(array) {
        [indexes enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
            [result addObject: [array objectAtIndex: idx]];
        }];
    }
    return result;
}

- (HashItem *) getFirstUncalcuratedItem
{
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
