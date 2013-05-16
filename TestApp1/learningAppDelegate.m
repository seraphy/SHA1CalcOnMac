//
//  learningAppDelegate.m
//  TestApp1
//
//  Created by  on 13/05/03.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "learningAppDelegate.h"
#include <CommonCrypto/CommonDigest.h>

@implementation HashItem : NSObject

@synthesize checked = _checked;
@synthesize url = _url;
@synthesize sha1hash = _sha1hash;
@synthesize md5hash = _md5hash;

- (void) dealloc
{
    NSLog(@"dealloc %@", self);
    [super dealloc];
}

- (id) initWithURL: (NSURL *)aUrl
{
    self = [super init];
    self.url = aUrl;
    return self;
}

- (id) initWithURL: (NSURL *)aUrl hash: (NSString *) aHash
{
    self = [super init];
    self.url = aUrl;
    self.sha1hash = aHash;
    return self;
}

- (NSString *) getName
{
    return [_url path];
}

@end


@implementation learningAppDelegate

@synthesize window = _window;

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


- (void) openDocument:(id)sender
{
    NSLog(@"openDocument!");
}

- (BOOL) isEmpty
{
    return [array count] <= 0;
}

- (BOOL)windowShouldClose:(id)sender
{
    BOOL ret = YES;
    
    if (![self isEmpty]) {
        NSAlert *alert = [NSAlert alertWithMessageText: @"Confirm"
                                         defaultButton: @"YES"
                                       alternateButton: @"NO"
                                           otherButton: nil
                             informativeTextWithFormat: @"Are you sure discade changes?"];
        if ([alert runModal] != NSAlertDefaultReturn) {
            ret = NO;
        }
    }

    return ret;
}

- (void)windowWillClose: (id) sender
{
    NSLog(@"windowWillClose!!!");

    [threadCond lock];
    [thread cancel];
    [threadCond signal];
    [threadCond unlock];
    
    if (_window) {
        _window = nil;
        //[[NSApplication sharedApplication] terminate: self];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    NSLog(@"applicationShouldTerminateAfterLastWindowClosed");
    return YES;
}

- (IBAction) sayHello: (id) sender {
    NSString *msg = [@"Hello, " stringByAppendingString: [inputField stringValue]];
    [outputField setStringValue: msg];
}

- (IBAction) showMessageDialog: (id) sender {
    NSString *msg = [@"Hello, " stringByAppendingString: [inputField stringValue]];
    NSAlert *alert = [NSAlert alertWithMessageText: msg
                                     defaultButton: @"OK"
                                   alternateButton: nil
                                       otherButton: nil
                         informativeTextWithFormat: @"This is message"];
    [alert runModal];
}

- (IBAction) openFileDialog:(id)sender
{
    NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
    [openPanel setAllowsMultipleSelection: YES];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *urls = [openPanel URLs];
            NSLog(@"%@", [urls description]);
            
            @synchronized(array) {
                for (NSURL *url in urls)
                {
                    NSLog(@"%@", [url path]);
                    HashItem *hashItem = [[HashItem alloc] initWithURL: url];
                    [array addObject: hashItem];
                    [hashItem release];
                }
            }
            
            [tableView reloadData];
            
            [threadCond lock];
            [threadCond signal];
            [threadCond unlock];
        }
        [openPanel release];
        NSLog(@"Release");
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    @synchronized(array) {
        return [array count];
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString *identifier = [aTableColumn identifier];

    HashItem *hashItem;
    @synchronized(array) {
        hashItem = [array objectAtIndex: rowIndex];
    }
    
    id msg = nil;
    if ([identifier isEqualToString: @"Checked"]) {
        msg = [NSNumber numberWithBool: [hashItem checked]];
        
    } else if ([identifier isEqualToString: @"Name"]) {
        msg = [[hashItem url] path];
        
    } else if ([identifier isEqualToString: @"SHA1"]) {
        msg = [hashItem sha1hash];

    } else if ([identifier isEqualToString: @"MD5"]) {
        msg = [hashItem md5hash];
        
    } else {
        msg = [NSString stringWithFormat: @"%@, %d", [aTableColumn identifier], rowIndex];
    }
    return msg;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString *identifier = [aTableColumn identifier];

    HashItem *hashItem;
    @synchronized(array) {
        hashItem = [array objectAtIndex: rowIndex];
    }
    if ([identifier isEqualToString: @"Checked"]) {
        [hashItem setChecked: [anObject boolValue]];
    }
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray *newDescriptors = [aTableView sortDescriptors];
    NSLog(@"SortDscriptor-Size: %ld", [newDescriptors count]);
    for (NSSortDescriptor *desc in newDescriptors) {
        NSLog(@"SortDscriptor: %@", desc);
    }
    @synchronized(array) {
        [array sortUsingDescriptors: newDescriptors];
        arrayVersion++;
    }
    [tableView reloadData];
}

- (IBAction) cut:(id)sender
{
    NSLog(@"Cut");
}

- (void) threadProc: (id) args
{
    NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    unsigned char sha1digest[CC_SHA1_DIGEST_LENGTH];
    unsigned char md5digest[CC_MD5_DIGEST_LENGTH];

    int cnt = 0;
    [threadCond lock];
    while (![[NSThread currentThread] isCancelled]) {
        NSLog(@"tick! %d", cnt++);
        HashItem *hashItem = nil;
        NSUInteger rowIndex = 0;
        NSUInteger arrayVerSnap;
        @synchronized(array) {
            // 現在の行番号ならびが変更されていないことを確認するためのチェッカ
            arrayVerSnap = arrayVersion;
            
            NSUInteger mx = [array count];
            for (NSUInteger idx = 0; idx < mx; idx++) {
                HashItem *item = [array objectAtIndex: idx];
                if ([item.sha1hash length] == 0) {
                    // スレッドで使っている間は解放されいようにretainする
                    hashItem = [item retain];
                    // 行番号
                    rowIndex = idx;
                    break;
                }
            }
        }
        if (hashItem == nil) {
            [threadCond wait];
            continue;
        }
        [threadCond unlock];
        
        // 行更新ブロック
        void (^updateRow)() = ^{
            //[tableView reloadItem: hashItem];
            NSUInteger arrayVerCur;
            @synchronized (array) {
                arrayVerCur = arrayVersion;
            }
            if (arrayVerCur == arrayVerSnap) {
                // 行番号はかわっていない
                [tableView reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: rowIndex]
                                     columnIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, 3)]];
            } else {
                // 行番号が変更されている可能性あり
                [tableView reloadData];
            }
        };

        // ループ内リリースプール
        NSAutoreleasePool *internalPool = [[NSAutoreleasePool alloc] init];

        // 読み取り開始通知
        hashItem.sha1hash = @"loading...";
        dispatch_async(dispatch_get_main_queue(), updateRow);

        // ファイルの読み取り
        NSString *path = [hashItem.url path];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath: path];
        
        // ハッシュ用バッファ
        CC_MD5_CTX md5ctx = {0};
        CC_SHA1_CTX sha1ctx = {0};

        CC_MD5_Init(&md5ctx);
        CC_SHA1_Init(&sha1ctx);
        
        for (;;) {
            // ファイルの読み取りループ内自動リリースプール
            NSAutoreleasePool *internalPool2 = [[NSAutoreleasePool alloc] init];
            
            // ハッシュ値の計算
            NSData *contents = [fileHandle readDataOfLength: 4096];
            unsigned int len = (unsigned int) [contents length];
            if (len > 0) {
                const void *data = [contents bytes];
                
                CC_MD5_Update(&md5ctx, data, len);
                CC_SHA1_Update(&sha1ctx, data, len);
            }
            
            [internalPool2 release];
            if (len == 0) {
                // 読み取り完了
                break;
            }
        }
        // ファイルを閉じる
        [fileHandle closeFile];

        // ハッシュ値の確定
        CC_MD5_Final(md5digest, &md5ctx);
        CC_SHA1_Final(sha1digest, &sha1ctx);
        
        // 表示アイテムの設定
        hashItem.checked = YES;
        hashItem.sha1hash = [self bin2hex: sha1digest len:CC_SHA1_DIGEST_LENGTH];
        hashItem.md5hash = [self bin2hex: md5digest len:CC_MD5_DIGEST_LENGTH];
        
        // 保持の解放
        [hashItem release];
        
        // 表示の更新
        dispatch_async(dispatch_get_main_queue(), updateRow);

        // プール開放
        [internalPool release];
        [threadCond lock];
    }
    [threadCond unlock];
    NSLog(@"end thread.");
    [autoreleasePool release];
}

- (NSString *) bin2hex: (unsigned char *) digest len:(int) len
{
    NSMutableString * result = [[[NSMutableString alloc]
                                initWithCapacity: (len * 2)]
                                autorelease];
    for (int idx = 0; idx < len; idx++) {
        [result appendString: [NSString stringWithFormat: @"%02x", digest[idx]]];
    }
    return result;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    threadCond = [[NSCondition alloc] init];
    thread = [[NSThread alloc] initWithTarget: self selector: @selector(threadProc:) object: nil];
    [thread start];
    
    NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
    [fmt setDateFormat: @"yyyy/MM/dd"];
    
    NSDate *today = [NSDate date];
    NSString *strDate = [fmt stringFromDate: today];
    
    [inputField setStringValue: strDate];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (_window) {
        NSLog(@"window %@", _window);
        [_window performClose: self];
        return NSTerminateCancel;
    }
    return NSTerminateNow;
}

- (void) applicationWillTerminate:(NSNotification *)notification
{
    [thread release];
    [threadCond release];
    NSLog(@"ApplicationWillTerminate!!!");
}

- (IBAction) openPreference: (id) sender
{
    NSLog(@"preference!");
}

@end
