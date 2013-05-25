//
//  HashItemList.m
//  SHA1CalcOnMac
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

- (void) add: (HashItem *) hashItem
{
    @synchronized(array) {
        [array addObject: hashItem];
        [hashItem setRowIndex: [array count] - 1];

        // 変更フラグON
        _modified = true;
    }
}

- (void) addWithURL: (NSURL *) url depth:(NSInteger)depth
{
    // ファイルの実在チェック
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *path = [url path];
    BOOL dir = NO;
    if ([fileMgr fileExistsAtPath: path isDirectory: &dir]) {
        if (dir) {
            // フォルダは無視する。
            return;
        }
        
        // ファイルであれば、ファイルサイズの取得
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

            // 変更フラグON
            _modified = true;
        }
    }
}

- (void) addWithURLArray: (NSArray *)urls
{
    @synchronized(array) {
        for (NSURL *url in urls) {
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            NSString *path = [url path];
            BOOL dir = NO;
            if ([fileMgr fileExistsAtPath: path isDirectory: &dir]) {
                if (dir) {
                    // ディレクトリであれば中身をリストする。(サブディレクトリ内も列挙される。)
                    NSDirectoryEnumerator *enm = [fileMgr enumeratorAtPath: path];
                    NSString *child = nil;
                    while ((child = [enm nextObject]) != nil) {
                        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
                        NSString *fullPath = [path stringByAppendingPathComponent: child];
                        [self addWithURL: [NSURL fileURLWithPath: fullPath] depth: 0];
                        [loopPool drain];
                    }
                    return;

                } else {
                    // ファイルであれば単体で設定する.
                    [self addWithURL: url depth: 0];
                }
            }
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
        [self setDocumentURL: nil];
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

- (void) updateHashItem: (HashItem *) hashItem
{
    _modified = true;
    if ([_delegate respondsToSelector: @selector(updateHashItem:)]) {
        [_delegate updateHashItem: hashItem];
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

- (void) setChecked: (NSIndexSet *) selrow state: (BOOL) sw
{
    @synchronized(array) {
        [selrow enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
            [[array objectAtIndex: idx] setChecked: sw];
        }];
    }
}

- (void) reverseChecked: (NSIndexSet *) selrow
{
    @synchronized(array) {
        [selrow enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
            HashItem *hashItem = [array objectAtIndex: idx];
            [hashItem setChecked: ![hashItem checked]];
        }];
    }
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

- (NSIndexSet *) getCheckedRowIndexes
{
    NSMutableIndexSet *indexes = [[[NSMutableIndexSet alloc] init] autorelease];
    @synchronized (array) {
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            HashItem *hashItem = obj;
            if ([hashItem checked]) {
                NSInteger rowIndex = [hashItem rowIndex];
                if (rowIndex >= 0) {
                    [indexes addIndex: rowIndex];
                }
            }
        }];
    }
    return indexes;
}

@end
