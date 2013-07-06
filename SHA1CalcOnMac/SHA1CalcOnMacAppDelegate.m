//
//  SHA1CalcOnMacAppDelegate.m
//  SHA1CalcOnMac
//
//  Created by  on 13/05/03.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "SHA1CalcOnMacAppDelegate.h"
#import "HashItem.h"
#import "FindWindowController.h"
#import "PreferenceWindowController.h"

@implementation SHA1CalcOnMacAppDelegate {
@private
    /// ハッシュ値を計算するスレッド
    HashCalcurateThread *thread;

    /// ファイルとハッシュを保持するアイテムのリスト
    HashItemList *hashItemList;

    /// テーブルビューとの接続
    IBOutlet NSTableView *tableView;
    
    /// メニューアイテムの接続
    IBOutlet NSMenuItem *deselectSingle;
    
    /// ステータス表示
    IBOutlet NSTextField *statusField;
    
    /// 検索ウィンドウ
    FindWindowController *findWindowController;

    /// 設定ウィンドウ
    PreferenceWindowController *preferenceWindowController;
}

@synthesize window = _window;

- (id) init
{
    self = [super init];
    hashItemList = [[HashItemList alloc] init];
    [hashItemList setDelegate: self];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver: self
               selector: @selector(hashCalcurateRunningState:)
                   name: @"HashCalcurateRunningState"
                 object: nil];
    
    return self;
}

- (void) hashCalcurateRunningState: (NSNotification *)notification
{
    HashCalcurateThread *calcThread = (HashCalcurateThread *)[notification object];
    BOOL scanning = [calcThread isScanning];
    NSLog(@"Scanning : %d", scanning);

    NSString *msg;
    if (scanning) {
        msg = @"Scanning";
    } else {
        msg = @"Idle";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [statusField setStringValue: msg];
    });    
}

- (void) dealloc
{
    [hashItemList release];
    if (findWindowController) {
        [findWindowController release];
    }
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSDictionary *userDefaultDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool: YES], @"skipHidden",
                                    [NSNumber numberWithInt: 5], @"maxOpenFiles",
                                     nil];
    [userDefault registerDefaults: userDefaultDict];
    
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
    if (!preferenceWindowController) {
        preferenceWindowController = [[PreferenceWindowController alloc] init];
        
        if (!preferenceWindowController) {
            return;
        }
    }
    [preferenceWindowController showWindow: self];
}

- (IBAction) newDocument:(id)sender
{
    [self showConfirmDiscadeDialog: ^(NSInteger returnCode) {
        if (returnCode == NSAlertDefaultReturn) {
            [hashItemList clear];
            [hashItemList setModified: NO];
            [tableView reloadData];
        }
    }];
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
    [self showConfirmDiscadeDialog: ^(NSInteger returnCode) {
        if (returnCode == NSAlertDefaultReturn) {
            // 現在のデータをクリアする.
            [hashItemList clear];
            [tableView reloadData];
            
            [self loadDocumentWithDialog: NO];
        }
    }];
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
        [savePanel setDirectoryURL: [NSURL fileURLWithPath: [prevPath stringByDeletingLastPathComponent]]];

    } else {
        // なければデフォルトファイル名を用いる
        [savePanel setNameFieldStringValue: @"filedigest.txt"];
    }
    
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [savePanel URL];
            [hashItemList setDocumentURL: url];
            [self saveDocumentCore];
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

    NSAlert *alert = [NSAlert alertWithMessageText: @"Are you sure overwrite?"
                                     defaultButton: @"YES"
                                   alternateButton: @"NO"
                                       otherButton: nil
                         informativeTextWithFormat: @""];
    [alert beginSheetModalForWindow: _window
                      modalDelegate: self
                     didEndSelector: @selector(saveDocumentAlertDidEnd:
                                               returnCode: contextInfo:) 
                        contextInfo: nil];
}

- (void) saveDocumentAlertDidEnd:(NSAlert *) alert
                      returnCode:(int) returnCode
                     contextInfo:(void *) contextInfo
{
    if (returnCode != NSAlertDefaultReturn) {
        return;
    }
    [self saveDocumentCore];
}

- (void) saveDocumentCore
{
    NSURL *url = [hashItemList documentURL];
    if (url == nil) {
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
    if (preferenceWindowController) {
        [preferenceWindowController close];
        [preferenceWindowController release];
        preferenceWindowController = nil;
    }
    [self showConfirmDiscadeDialog: ^(NSInteger returnCode){
        if (returnCode == NSAlertDefaultReturn) {
            // ウィンドウをクローズする。
            [_window close];
        }
    }];
    return NO;
}

- (void) showConfirmDiscadeDialog: (void(^)(NSInteger)) block;
{
    if ([hashItemList modified]) {
        // 変更ある場合は実行有無を問い合わせ
        NSAlert *alert = [NSAlert alertWithMessageText: @"Are you sure discade changes?"
                                         defaultButton: @"YES"
                                       alternateButton: @"NO"
                                           otherButton: nil
                             informativeTextWithFormat: @""];
        [alert beginSheetModalForWindow: _window
                          modalDelegate: self
                         didEndSelector: @selector(showConfirmDiscadeDialogDidEnd:
                                                   returnCode: contextInfo:) 
                            contextInfo: [block copy]]; // __bridge_retained
        return;
    }
    
    // 変更ない場合はYESと見なして実行
    block(NSAlertDefaultReturn);
}

- (void) showConfirmDiscadeDialogDidEnd:(NSAlert *) alert
                             returnCode:(int) returnCode
                            contextInfo:(void *) contextInfo
{
    void (^block)(NSInteger) = contextInfo; // __bridge_transfer
    block(returnCode);
    [block release];
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
            
            // 現在の隠しファイルのスキップ有無の設定を反映する.
            NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
            BOOL skipHidden = [userDefault boolForKey: @"skipHidden"];
            [hashItemList setSkipHidden: skipHidden];
            
            // ファイルもしくはフォルダをリストに追加する.
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
            msg = [NSString stringWithFormat: @"%lld", [hashItem fileSize]];

        } else if ([identifier isEqualToString: @"SHA1"]) {
            if ([hashItem state] == hashItem_loading) {
                msg = @"loading...";
                
            } else if ([hashItem state] == hashItem_failed) {
                msg = @"failed";
            
            } else {
                msg = [hashItem sha1hash];
            }
            
        } else if ([identifier isEqualToString: @"MD5"]) {
            if ([hashItem state] == hashItem_loading) {
                msg = @"loading...";

            } else if ([hashItem state] == hashItem_failed) {
                msg = @"failed";
                
            } else {
                msg = [hashItem md5hash];
            }
            
        } else {
            msg = [NSString stringWithFormat: @"%@, %ld", [aTableColumn identifier], rowIndex];
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

- (IBAction) deleteIfUnmarked:(id)sender
{
    [hashItemList deleteIf: ^(HashItem *hashItem) {
        if ([hashItem checked]) {
            return NO;
        }
        return YES;
    }];
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

- (IBAction) markIfSelected:(id)sender
{
    // 現在選択の行番号の取得
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    [hashItemList setChecked: selrows state: YES];
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
        NSString *key = [NSString stringWithFormat: @"%lld:%@:%@",
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

- (void) openFileAtWorkspaceCore: (NSIndexSet *) selrows
{
    // 対応するハッシュアイテムの取得
    NSArray *selItems = [hashItemList getItemByIndexes: selrows];    
    
    // ファイルを開く.
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    for (HashItem *hashItem in selItems) {
        [workspace openFile: [[hashItem url] path]];
    }
}

- (void) manyOpenAlertDidEnd:(NSAlert *) alert
                      returnCode:(int) returnCode
                     contextInfo:(NSIndexSet *) selrows
{
    if (returnCode != NSAlertDefaultReturn) {
        [self openFileAtWorkspaceCore: selrows];
    }
    [selrows release];
}

- (IBAction) openFileAtWorkspace:(id) sender
{
    // 現在選択の行番号の取得
    NSIndexSet *selrows = [tableView selectedRowIndexes];

    // 同時に開くファイルの最大数制限
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSInteger maxOpenFile = [userDefault integerForKey: @"maxOpenFiles"];
    
    if ([selrows count] > maxOpenFile) {
        // 設定で指定されたより多くのファイルが選択されている場合は警告を表示する.
        NSAlert *alert = [NSAlert alertWithMessageText: @"Warnings"
                                         defaultButton: @"Cancel"
                                       alternateButton: @"Continue"
                                           otherButton: nil
                             informativeTextWithFormat: @"too many files. (%ld)", [selrows count]];
        [alert beginSheetModalForWindow: _window
                          modalDelegate: self
                         didEndSelector: @selector(manyOpenAlertDidEnd: returnCode: contextInfo:)
                            contextInfo: [selrows retain]];
    } else {
        [self openFileAtWorkspaceCore: selrows];
    }
}

- (IBAction) performFindPanelAction:(id)sender
{
    if (!findWindowController) {
        findWindowController = [[FindWindowController alloc] init];

        if (!findWindowController) {
            return;
        }
        
        [findWindowController setDelegate: self];
    }

    NSInteger tag = [sender tag];
    NSLog(@"find menu: tag=%ld", tag);
    switch (tag)
    {
        case 1: // find...
            [findWindowController showWindow: self];
            break;
            
        case 2: // next
            [self findNext: sender];
            break;

        case 3: // prev
            [self findPrev: sender];
            break;

        case 7: // select to find
            [self findSelect: sender];
            break;
    }
}

- (IBAction) findNext: (id) sender
{
    FindInfo *findInfo = [findWindowController findInfo];
    FindInfoMatcher *findInfoMatcher = [FindInfoMatcher findInfoMatcher: findInfo];

    NSInteger selrow = [tableView selectedRow];
    NSInteger nextrow = [hashItemList findNext: findInfoMatcher startRow: selrow];
    if (nextrow >= 0 && nextrow != selrow) {
        [tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: nextrow]
               byExtendingSelection: NO];
        [tableView scrollRowToVisible: nextrow];
    }
}

- (IBAction) findPrev: (id) sender
{
    FindInfo *findInfo = [findWindowController findInfo];
    FindInfoMatcher *findInfoMatcher = [FindInfoMatcher findInfoMatcher: findInfo];

    NSInteger selrow = [tableView selectedRow];
    NSInteger nextrow = [hashItemList findPrev: findInfoMatcher startRow: selrow];
    if (nextrow >= 0 && nextrow != selrow) {
        [tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: nextrow]
               byExtendingSelection: NO];
        [tableView scrollRowToVisible: nextrow];
    }
}

- (IBAction) findSelect: (id) sender
{
    FindInfo *findInfo = [findWindowController findInfo];
    FindInfoMatcher *findInfoMatcher = [FindInfoMatcher findInfoMatcher: findInfo];

    NSIndexSet *selrows = [hashItemList findAll: findInfoMatcher];
    if ([selrows count] > 0) {
        [tableView selectRowIndexes: selrows byExtendingSelection: NO];
        [tableView scrollRowToVisible: [selrows firstIndex]];
    }
}

- (IBAction) centerSelectionInVisibleArea:(id)sender
{
    NSIndexSet *sels = [tableView selectedRowIndexes];
    NSInteger firstIdx = [sels firstIndex];
    if (firstIdx != NSNotFound) {
        [tableView scrollRowToVisible: firstIdx];
    }
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
    NSLog(@"validateUserIFItem: item=%@", anItem);
    return YES;
}

- (IBAction) uncheckFirstItem: (id) sender
{
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    if ([selrows count] <= 1) {
        [[NSAlert alertWithMessageText: @"no selection"
                         defaultButton: @"OK"
                       alternateButton: nil
                           otherButton: nil
             informativeTextWithFormat: @""] runModal];
        return;
    }
    
    [hashItemList uncheckFirstItem: selrows];
}

- (IBAction) recalcHash:(id)sender
{
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    if ([selrows count] <= 1) {
        [[NSAlert alertWithMessageText: @"no selection"
                         defaultButton: @"OK"
                       alternateButton: nil
                           otherButton: nil
             informativeTextWithFormat: @""] runModal];
        return;
    }
    
    [hashItemList setStateByIndexes: selrows state: hashItem_needCalc];
    [thread notify];
    [tableView reloadData];
}

- (IBAction) unmarkMissingFiles:(id)sender
{
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    if ([selrows count] <= 1) {
        [[NSAlert alertWithMessageText: @"no selection"
                         defaultButton: @"OK"
                       alternateButton: nil
                           otherButton: nil
             informativeTextWithFormat: @""] runModal];
        return;
    }
    
    [hashItemList unmarkMissingFiles: selrows];
}

@end
