//
//  learningAppDelegate.m
//  SHA1CalcOnMac
//
//  Created by  on 13/05/03.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "learningAppDelegate.h"
#import "HashItem.h"


@implementation learningAppDelegate {
@private
    /// ハッシュ値を計算するスレッド
    HashCalcurateThread *thread;

    /// ファイルとハッシュを保持するアイテムのリスト
    HashItemList *hashItemList;

    /// テーブルビューとの接続
    IBOutlet NSTableView *tableView;
    
    /// メニューアイテムの接続
    IBOutlet NSMenuItem *deselectSingle;
}

@synthesize window = _window;

- (id) init
{
    self = [super init];
    hashItemList = [[HashItemList alloc] init];
    [hashItemList setDelegate: self];
    return self;
}

- (void) dealloc
{
    [hashItemList release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    thread = [[HashCalcurateThread alloc] init];
    [thread setHashItemList: hashItemList];
    [thread start];
}

- (void) applicationWillTerminate:(NSNotification *)notification
{
    [thread release];
    NSLog(@"ApplicationWillTerminate!!!");
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

- (IBAction) openPreference: (id) sender
{
    NSLog(@"preference!");
}

- (IBAction) newDocument:(id)sender
{
    if ([self showConfirmDiscadeDialog]) {
        [hashItemList clear];
        [hashItemList setModified: NO];
        [tableView reloadData];
    }
}

- (void) loadDocument: (NSURL *) url
{
    NSInputStream *istm = [NSInputStream inputStreamWithURL: url];
    [istm open];

    const size_t bufsiz = 4096;
    uint8_t buf[bufsiz];
    
    NSMutableData *prevbuf = [[[NSMutableData alloc] init] autorelease];

    NSString* msg = nil;
    while ([istm hasBytesAvailable]) {
        NSInteger len = [istm read: buf maxLength: bufsiz];
        if (len < 0) {
            msg = @"error";
            break;
        }
        if (len == 0) {
            // 読み取り完了
            break;
        }
        
        NSInteger idx = 0;
        NSInteger st = 0;
        while (idx < len) {
            uint8_t ch = buf[idx];
            if (ch == '\n') {
                NSInteger span = idx - st + 1;
                [prevbuf appendBytes: (buf + st) length: span];
                NSString *line = [[NSString alloc] initWithData: prevbuf encoding: NSUTF8StringEncoding];
                HashItem *hashItem = [HashItem hashItemFromString: line separator: @"\t"];
                if (hashItem) {
                    [hashItemList add: hashItem];
                }
                [line release];
                
                [prevbuf setLength: 0];
                st = idx + 1;
            }
            idx++;
        }
        if (st < idx) {
            NSInteger span = len - st;
            [prevbuf appendBytes: (buf + st) length: span];
        }
    }
    if ([prevbuf length] > 0) {
        NSString *line = [[NSString alloc] initWithData: prevbuf encoding: NSUTF8StringEncoding];
        HashItem *hashItem = [HashItem hashItemFromString: line separator: @"\t"];
        if (hashItem) {
            [hashItemList add: hashItem];
        }
        [line release];
    }
    
    [istm close];
    
    [tableView reloadData];
}

- (void) loadDocumentWithDialog: (BOOL) merge
{
    // ファイルを開くダイアログ
    NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
    
    // デフォルトの拡張子と選択
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects: @"txt", nil]];
    [openPanel setAllowsOtherFileTypes:YES];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [openPanel URL];
            [self loadDocument: url];
            
            // 新規の場合はファイルのURLを設定する.
            if (!merge) {
                [hashItemList setDocumentURL: url];
                [hashItemList setModified: NO];

            } else {
                [hashItemList setModified: YES];
            }
        }
        [openPanel release];
    }];
}


- (IBAction) mergeDocument:(id)sender
{
    [self loadDocumentWithDialog: YES];
}


- (IBAction) openDocument:(id)sender
{
    if (![self showConfirmDiscadeDialog]) {
        return;
    }
    // 現在のデータをクリアする.
    [hashItemList clear];
    [tableView reloadData];

    [self loadDocumentWithDialog: NO];
}

- (IBAction) saveDocumentAs:(id) sender
{
    HashItem *hashItem = [hashItemList getFirstUncalcuratedItem];
    if (hashItem) {
        // まだ未検査のものがある場合
        [hashItem release];
        
        NSAlert *alert = [NSAlert alertWithMessageText: @"Warning"
                                         defaultButton: @"OK"
                                       alternateButton: @"Cancel"
                                           otherButton: nil
                             informativeTextWithFormat: @"Calculation is not completed. "];
        NSInteger ret = [alert runModal];
        if (ret != NSAlertDefaultReturn) {
            // Cancelされた場合
            return;
        }
    }
    
    NSSavePanel *savePanel = [[NSSavePanel savePanel] retain];
    [savePanel setCanCreateDirectories: YES];
    [savePanel setExtensionHidden: NO];
    
    // デフォルトの拡張子と選択
    [savePanel setAllowedFileTypes:[NSArray arrayWithObjects: @"txt", nil]];
    [savePanel setAllowsOtherFileTypes:YES];
    
    NSURL *prevURL = [hashItemList documentURL];
    if (prevURL) {
        // 前回ファイル名があれば、それを復元する.
        NSString *prevPath = [prevURL path];
        [savePanel setNameFieldStringValue: [prevPath lastPathComponent]];
        [savePanel setDirectory: [prevPath stringByDeletingLastPathComponent]];

    } else {
        // なければデフォルトファイル名を用いる
        [savePanel setNameFieldStringValue: @"filedigest.txt"];
    }
    
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [savePanel URL];
            [hashItemList setDocumentURL: url];
            [self saveDocument: sender];
        }
        [savePanel release];
    }];
}

- (IBAction) saveDocument:(id) sender
{
    NSURL *url = [hashItemList documentURL];
    if (url == nil) {
        [self saveDocumentAs: sender];
        return;
    }
    
    // 空のファイルの事前作成
    [[NSFileManager defaultManager] createFileAtPath:[url path] contents:nil attributes:nil];
    
    // ファイルの書き込みオープン
    NSError *err = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL: url error: &err]; 
    if (err) {
        [[NSAlert alertWithError: err] runModal];
    }
    if (fileHandle == nil) {
        return;
    }

    // データの書き込み
    NSData *crlf = [@"\r\n" dataUsingEncoding: NSUTF8StringEncoding];
    NSInteger rowIndex = 0;
    while (rowIndex < [hashItemList count]) {
        HashItem *hashItem = [hashItemList getItemByIndex: rowIndex];
        [fileHandle writeData: [[hashItem descriptionUsingSeparator: @"\t"] dataUsingEncoding: NSUTF8StringEncoding]];
        [fileHandle writeData: crlf];
        rowIndex++;
    }
    [fileHandle closeFile];
    
    // 保存済みフラグ
    [hashItemList setModified: NO];
}

- (BOOL)windowShouldClose:(id)sender
{
    return [self showConfirmDiscadeDialog];
}

- (BOOL) showConfirmDiscadeDialog
{
    BOOL ret = YES;
    
    if ([hashItemList modified]) {
        NSAlert *alert = [NSAlert alertWithMessageText: @"Are you sure discade changes?"
                                         defaultButton: @"YES"
                                       alternateButton: @"NO"
                                           otherButton: nil
                             informativeTextWithFormat: @""];
        if ([alert runModal] != NSAlertDefaultReturn) {
            ret = NO;
        }
    }
    return ret;
}

- (void)windowWillClose: (id) sender
{
    NSLog(@"windowWillClose!!!");

    [thread requestCancel];
    
    if (_window) {
        _window = nil;
        //[[NSApplication sharedApplication] terminate: self];
    }
    
    [hashItemList setDelegate: nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    NSLog(@"applicationShouldTerminateAfterLastWindowClosed");
    return YES;
}

- (IBAction) openFileDialog:(id)sender
{
    // ファイルを開くダイアログ
    NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
    [openPanel setAllowsMultipleSelection: YES]; // 複数選択可
    [openPanel setCanChooseDirectories: YES]; // フォルダ選択可
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *urls = [openPanel URLs];
            [hashItemList addWithURLArray: urls];
            [thread notify];
            [tableView reloadData];
        }
        [openPanel release];
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [hashItemList count];
}

- (void) updateHashItem: (HashItem *) hashItem
{
    if (hashItem) {
        NSInteger rowIndex = [hashItem rowIndex];
        
        if (rowIndex >= 0) {
            [tableView setNeedsDisplayInRect:[tableView rectOfRow:rowIndex]];
        }
    } else {
        [tableView reloadData];
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    id msg = nil;
    NSString *identifier = [aTableColumn identifier];

    HashItem *hashItem = [hashItemList getItemByIndex: rowIndex];
    if (hashItem) {
        if ([identifier isEqualToString: @"Checked"]) {
            msg = [NSNumber numberWithBool: [hashItem checked]];
            
        } else if ([identifier isEqualToString: @"Name"]) {
            msg = [[hashItem url] path];
            
        } else if ([identifier isEqualToString: @"FileSize"]) {
            msg = [NSString stringWithFormat: @"%ld", [hashItem fileSize]];

        } else if ([identifier isEqualToString: @"SHA1"]) {
            msg = [hashItem sha1hash];
            
        } else if ([identifier isEqualToString: @"MD5"]) {
            msg = [hashItem md5hash];
            
        } else {
            msg = [NSString stringWithFormat: @"%@, %d", [aTableColumn identifier], rowIndex];
        }
    }
    return msg;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString *identifier = [aTableColumn identifier];
    if ([identifier isEqualToString: @"Checked"]) {
        HashItem *hashItem = [hashItemList getItemByIndex: rowIndex];
        if (hashItem) {
            [hashItem setChecked: [anObject boolValue]];
        }
    }
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray *newDescriptors = [aTableView sortDescriptors];
    [hashItemList sortUsingDescriptors: newDescriptors];
    [tableView reloadData];
}

- (IBAction) copy:(id)sender
{
    // 現在選択の行番号の取得
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    
    // 対応するハッシュアイテムの取得
    NSArray *selItems = [hashItemList getItemByIndexes: selrows];    

    // データの作成
    NSMutableString *buf = [[[NSMutableString alloc] init] autorelease];
    NSString *crlf = @"\r\n";
    for (HashItem *hashItem in selItems) {
        [buf appendString: [hashItem descriptionUsingSeparator: @"\t"]];
        [buf appendString: crlf];
    }
    
    // クリップボードに格納
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb setString: buf forType: NSPasteboardTypeString];
}

- (IBAction) cut:(id)sender
{
    // コピー動作
    [self copy: sender];

    // 削除動作
    [self delete: sender];
}

- (IBAction) delete: (id)sender
{
    // 現在選択の行番号の取得
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    
    // 選択の解除
    [tableView deselectAll: nil];
    
    // アイテムの除去
    [hashItemList removeByIndexes: selrows];
    
    // テーブルの再表示
    [tableView reloadData];
}


- (BOOL) getDeselectSingleMode
{
    return [deselectSingle state] == NSOnState;
}

- (IBAction) resetMark: (id)sender
{
    // 現在選択の行番号の取得
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    [hashItemList setChecked: selrows state: NO];
    [tableView reloadData];
}

- (IBAction) reverseMark: (id)sender
{
    // 現在選択の行番号の取得
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    [hashItemList reverseChecked: selrows];
    [tableView reloadData];
}

- (IBAction) deselectSingle: (id) sender
{
    NSInteger newState = [deselectSingle state] != NSOnState ? NSOnState : NSOffState;
    [deselectSingle setState: newState];
}

- (IBAction) check: (id) sender
{
    NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    if ([selrows count] <= 1) {
        [[NSAlert alertWithMessageText: @"no selection"
                         defaultButton: @"OK"
                       alternateButton: nil
                           otherButton: nil
             informativeTextWithFormat: @""] runModal];
        return;
    }
    NSArray *hashItems = [hashItemList getItemByIndexes: selrows];
    [hashItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        HashItem *hashItem = obj;
        NSString *key = [NSString stringWithFormat: @"%ld:%@:%@",
                         [hashItem fileSize], [hashItem sha1hash], [hashItem md5hash]];
        NSMutableArray *arr = [dict objectForKey: key];
        if (arr == nil) {
            arr = [[NSMutableArray alloc] init];
            [dict setObject: arr forKey: key];
            [arr release];
        }
        [arr addObject: hashItem];    
    }];

    BOOL sw = self.deselectSingleMode;
    
    [[dict allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *arr = obj;
        if ([arr count] <= 1) {
            // single object
            if (sw) {
                [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    HashItem *hashItem = obj;
                    [hashItem setChecked: NO];
                }];
            }
        } else {
            // multi object
            if (!sw) {
                [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    HashItem *hashItem = obj;
                    [hashItem setChecked: NO];
                }];
            }
        }
    }];
    
    [tableView reloadData];
}

- (IBAction) selectIfChecked:(id) sender
{
    NSIndexSet *checkedRow = [hashItemList getCheckedRowIndexes];
    [tableView selectRowIndexes: checkedRow byExtendingSelection: NO];
}

- (IBAction) deleteMarkedFile:(id) sender
{
    // 現在選択の行番号の取得
    NSIndexSet *selrows = [hashItemList getCheckedRowIndexes];
    
    // 対応するハッシュアイテムの取得
    NSArray *selItems = [hashItemList getItemByIndexes: selrows];    
    
    // ファイルの削除
    NSMutableArray *files = [[[NSMutableArray alloc] init] autorelease];
    for (HashItem *hashItem in selItems) {
        NSString *path = [[hashItem url] path];
        [files addObject: path];
    }

    // ファイルをゴミ箱に入れる
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    [workspace performFileOperation: NSWorkspaceRecycleOperation
                             source: @""
                        destination: @""
                              files: files
                                tag: nil];
    
    // 選択の解除
    [tableView deselectAll: nil];
    
    // アイテムの除去
    [hashItemList removeByIndexes: selrows];
    
    // テーブルの再表示
    [tableView reloadData];
}

- (IBAction) openFileAtWorkspace:(id) sender
{
    // 現在選択の行番号の取得
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    
    if ([selrows count] > 5) {
        // 5より多くのファイルが選択されている場合は警告を表示する.
        NSAlert *alert = [NSAlert alertWithMessageText: @"Warnings"
                                         defaultButton: @"Cancel"
                                       alternateButton: @"Continue"
                                           otherButton: nil
                             informativeTextWithFormat: @"too many files. (%ld)", [selrows count]];
        NSInteger ret = [alert runModal];
        if (ret == NSAlertDefaultReturn) {
            // 中止する.
            return;
        }
    }
    
    // 対応するハッシュアイテムの取得
    NSArray *selItems = [hashItemList getItemByIndexes: selrows];    
    
    // ファイルを開く.
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    for (HashItem *hashItem in selItems) {
        [workspace openFile: [[hashItem url] path]];
    }
}

@end
