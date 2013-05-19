//
//  learningAppDelegate.m
//  TestApp1
//
//  Created by  on 13/05/03.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
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

- (void) newDocument:(id)sender
{
    if ([self showConfirmDiscadeDialog]) {
        [hashItemList clear];
        [tableView reloadData];
    }
}

- (void) openDocument:(id)sender
{
    NSLog(@"openDocument!");
}

- (void) saveDocument:(id) sender
{
    NSLog(@"saveDocument!");
}

- (void) saveDocumentAs:(id) sender
{
    NSLog(@"saveDocument!");
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
    NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
    [openPanel setAllowsMultipleSelection: YES];
    [openPanel setCanChooseDirectories: YES];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *urls = [openPanel URLs];
            [hashItemList addWithURLArray: urls];
            [thread notify];
            [tableView reloadData];
        }
        [openPanel release];
        NSLog(@"Release");
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [hashItemList count];
}

- (void) notifyChangeHashItem: (HashItem *) hashItem
{
    NSInteger rowIndex = [hashItem rowIndex];

    if (rowIndex >= 0) {
        [tableView reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: rowIndex]
                             columnIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, 5)]];
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

- (IBAction) cut:(id)sender
{
    NSIndexSet *selrows = [tableView selectedRowIndexes];
    [tableView deselectAll: nil];
    [hashItemList removeByIndexes: selrows];
    [tableView reloadData];
}

@end
