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
    
    /// HashItemのURL別のマップ
    NSMutableDictionary *dict;
}

@synthesize skipHidden = _skipHidden;
@synthesize documentURL = _documentURL;
@synthesize delegate = _delegate;
@synthesize modified = _modified;

- (id) init
{
    self = [super init];
    array = [[NSMutableArray alloc] init];
    dict = [[NSMutableDictionary alloc] init];
    _modified = NO;
    return self;
}

- (void) dealloc
{
    self.skipHidden = NO;
    self.documentURL = nil;
    self.delegate = nil;
    self.modified = NO;
    
    [array release];
    [dict release];
    [super dealloc];
}

- (void) add: (HashItem *) hashItem
{
    @synchronized(array) {
        NSURL *url = [hashItem url];
        HashItem *prev = [dict objectForKey: url];
        if (prev == nil) {
            // 新しいURLの場合
            [array addObject: hashItem];
            [hashItem setRowIndex: [array count] - 1];
            [dict setObject: hashItem forKey: url];

        } else {
            // 既存のURLの場合
            // チェック状態とファイルサイズのみ更新する.
            [prev setChecked: YES];
            [prev setFileSize: [hashItem fileSize]];
        }

        // 変更フラグON
        _modified = true;
    }
}

/**
 * ファイルが隠しファイルであるか？
 */
BOOL isInvisible(NSString *str, BOOL isFile){
    CFURLRef inURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)str, kCFURLPOSIXPathStyle, isFile);
    LSItemInfoRecord itemInfo;
    LSCopyItemInfoForURL(inURL, kLSRequestAllFlags, &itemInfo);
    
    BOOL isInvisible = itemInfo.flags & kLSItemInfoIsInvisible;
    return (isInvisible != 0);
}

- (void) addFileWithURL: (NSURL *) url
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
        
        // 隠しファイルであるか？
        if ([self skipHidden] && isInvisible(path, YES)) {
            NSLog(@"skip %@", path);
            return;
        }
        
        // ファイルであれば、ファイルサイズの取得
        NSError *err = nil;
        NSDictionary *attr = [fileMgr attributesOfItemAtPath: path error: &err];
        NSNumber *fileSize = [attr objectForKey: NSFileSize];
        
        // アイテムの設定
        HashItem *hashItem = [[HashItem alloc] initWithURL: url];
        [hashItem setFileSize: [fileSize unsignedLongLongValue]];
        [self add: hashItem];
        [hashItem release];
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
                        [self addFileWithURL: [NSURL fileURLWithPath: fullPath]];
                        [loopPool drain];
                    }

                } else {
                    // ファイルであれば単体で設定する.
                    [self addFileWithURL: url];
                }
            }
        }
    }
}

- (void) clear
{
    @synchronized (array) {
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setRowIndex: -1];
        }];
        [array removeAllObjects];
        [dict removeAllObjects];
        [self setDocumentURL: nil];
        [self setModified: NO];
    }
}

- (void ) removeByIndexes: (NSIndexSet *) selrows
{
    @synchronized(array) {
        [selrows enumerateIndexesWithOptions: NSEnumerationReverse
                                  usingBlock: ^(NSUInteger idx, BOOL *stop) {
                                      HashItem *hashItem = [array objectAtIndex: idx];
                                      [hashItem setRowIndex: -1];
                                      [array removeObjectAtIndex: idx];
                                      [dict removeObjectForKey: [hashItem url]];
                                  }];
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setRowIndex: idx];
        }];
        // 変更フラグON
        _modified = true;
    }
}

- (void) updateHashItem: (HashItem *) hashItem
{
    if ([_delegate respondsToSelector: @selector(updateHashItem:)]) {
        [_delegate updateHashItem: hashItem];
    }
    // 変更フラグON
    _modified = true;
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
        NSInteger cnt = [array count];
        [indexes enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
            if (cnt > idx) {
                [result addObject: [array objectAtIndex: idx]];
            }
        }];
    }
    return result;
}

- (void) setChecked: (NSIndexSet *) selrows state: (BOOL) sw
{
    @synchronized(array) {
        [selrows enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
            [[array objectAtIndex: idx] setChecked: sw];
        }];
        // 変更フラグON
        _modified = true;
    }
}

- (void) reverseChecked: (NSIndexSet *) selrows
{
    @synchronized(array) {
        [selrows enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
            HashItem *hashItem = [array objectAtIndex: idx];
            [hashItem setChecked: ![hashItem checked]];
        }];
        // 変更フラグON
        _modified = true;
    }
}


- (HashItem *) getFirstUncalcuratedItem
{
    @synchronized(array) {
        NSUInteger mx = [array count];
        for (NSUInteger idx = 0; idx < mx; idx++) {
            HashItem *item = [array objectAtIndex: idx];
            if ([item state] == hashItem_needCalc) {
                // スレッドで使っている間は解放されいようにretainしてから返す.
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
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setRowIndex: idx];
        }];
        // 変更フラグON
        _modified = true;
    }
}

- (NSInteger) count
{
    @synchronized(array) {
        return [array count];
    }
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

- (NSInteger) findNext: (FindInfoMatcher *)findInfoMatcher startRow: (NSInteger) startRow
{
    @synchronized (array) {
        NSInteger mx = [array count];
        if (startRow < -1) {
            startRow = -1;
        }

        NSInteger idx = startRow + 1;
        while (idx < mx) {
            HashItem *hashItem = [array objectAtIndex: idx];
            
            if ([findInfoMatcher isMatch: hashItem]) {
                return idx;
            }
            
            idx++;
        }
        return -1;
    }
}

- (NSInteger) findPrev: (FindInfoMatcher *)findInfoMatcher startRow: (NSInteger) startRow
{
    @synchronized (array) {
        NSInteger mx = [array count];
        if (startRow < -1) {
            startRow = mx;
        }
        @synchronized (array) {
            NSInteger idx = startRow - 1;
            while (idx >= 0) {
                HashItem *hashItem = [array objectAtIndex: idx];
                
                if ([findInfoMatcher isMatch: hashItem]) {
                    return idx;
                }
                
                idx--;
            }
            return -1;
        }
    }
}

- (NSIndexSet *) findAll: (FindInfoMatcher *)findInfoMatcher
{
    NSMutableIndexSet *idxes = [[[NSMutableIndexSet alloc] init] autorelease];
    @synchronized (array) {
        NSInteger idx = 0;
        NSInteger mx = [array count];
        while (idx < mx) {
            HashItem *hashItem = [array objectAtIndex: idx];
            
            if ([findInfoMatcher isMatch: hashItem]) {
                [idxes addIndex: idx];
            }
            idx++;
        }
    }
    return idxes;
}

- (void) uncheckFirstItem:(NSIndexSet *)selrows
{
    NSMutableSet *checker = [[[NSMutableSet alloc] init] autorelease];
    
    // 対応するハッシュアイテムの取得
    @synchronized (array) {
        NSArray *selItems = [self getItemByIndexes: selrows];
        for (HashItem *hashItem in selItems) {
            NSString *sha1hash = [hashItem sha1hash];
            if (![checker containsObject: sha1hash]) {
                // ハッシュ値が初回登場の場合はチェックを外す.
                [hashItem setChecked: NO];
                [self updateHashItem: hashItem];
                [checker addObject: sha1hash];
                // 変更フラグON
                _modified = true;
            }
        }
    }
}

- (void) deleteIf: (BOOL (^)(HashItem *)) block
{
    __block NSMutableIndexSet *selrows = [[[NSMutableIndexSet alloc] init] autorelease];
    
    @synchronized (array) {
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (block((HashItem *)obj)) {
                [selrows addIndex: idx];
            }
        }];
        [self removeByIndexes: selrows];
    }
}

- (void) setStateByIndexes: (NSIndexSet *) selrows state: (HashItemState) state
{
    // 対応するハッシュアイテムの取得
    @synchronized (array) {
        NSArray *selItems = [self getItemByIndexes: selrows];
        for (HashItem *hashItem in selItems) {
            [hashItem setState: state];
        }
        // 変更フラグON
        _modified = true;
    }
}

- (void) unmarkMissingFiles:(NSIndexSet *)selrows
{
    // 対応するハッシュアイテムの取得
    @synchronized (array) {
        NSArray *selItems = [self getItemByIndexes: selrows];
        for (HashItem *hashItem in selItems) {
            NSURL *url = [hashItem url];
            NSError *err = nil;
            if ([url checkResourceIsReachableAndReturnError: &err] == NO) {
                [hashItem setChecked: NO];
                [self updateHashItem: hashItem];
                // 変更フラグON
                _modified = true;
            }
        }
    }
}


@end
