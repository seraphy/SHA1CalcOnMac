//
//  learningAppDelegate.h
//  TestApp1
//
//  Created by  on 13/05/03.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HashItemList.h"
#import "HashCalcurateThread.h"

/**
 * シングルウィンドウ用デリゲート.
 */
@interface learningAppDelegate : NSObject <NSApplicationDelegate, HashItemListNotification>

/**
 * ウィンドウとの接続
 */
@property (assign) IBOutlet NSWindow *window;


/**
 * 変更がある場合に破棄の有無を確認するダイアログを開く
 */
- (BOOL) showConfirmDiscadeDialog;

/**
 * ファイルを開く
 */
- (IBAction) openFileDialog:(id)sender;

/**
 * 設定
 */
- (IBAction) openPreference:(id)sender;

- (IBAction) newDocument:(id)sender;
- (IBAction) openDocument:(id)sender;
- (IBAction) saveDocumentAs:(id) sender;
- (IBAction) saveDocument:(id) sender;
- (IBAction) copy:(id)sender;
- (IBAction) cut:(id)sender;

@end
