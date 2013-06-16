//
//  SHA1CalcOnMacAppDelegate.h
//  SHA1CalcOnMac
//
//  Created by  on 13/05/03.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HashItemList.h"
#import "HashCalcurateThread.h"

/**
 * シングルウィンドウ用デリゲート.
 */
@interface SHA1CalcOnMacAppDelegate : NSObject <NSApplicationDelegate, HashItemListNotification>

/**
 * ウィンドウとの接続
 */
@property (assign) IBOutlet NSWindow *window;

/**
 * チェック結果の選択モード
 */
@property (readonly, getter = getDeselectSingleMode) BOOL deselectSingleMode;

/**
 * 変更がある場合に破棄の有無を確認するダイアログを開く
 */
- (BOOL) showConfirmDiscadeDialog;

/**
 * ドキュメントをロードする.
 */
- (void) loadDocument: (NSURL *) url;

/**
 * ファイルダイアログを開き、そのドキュメントをロードする.
 * @param merge マージする場合
 */
- (void) loadDocumentWithDialog: (BOOL) merge;

/**
 * ファイルを開く
 */
- (IBAction) openFileDialog:(id)sender;

/**
 * 設定
 */
- (IBAction) openPreference:(id)sender;

/**
 * ウィンドウを閉じる確認のシートダイアログのイベントを受け取るメソッド
 */
- (void) closeConfirmAlertDidEnd:(NSAlert *) alert
                      returnCode:(int) returnCode
                     contextInfo:(void *) contextInfo;

/**
 * 開くファイル数が多い場合の警告シートダイアログのイベントを受け取るメソッド
 */
- (void) manyOpenAlertDidEnd:(NSAlert *) alert
                  returnCode:(int) returnCode
                 contextInfo:(NSIndexSet *) selrows;

- (void) openFileAtWorkspaceCore: (NSIndexSet *) selrows;

- (BOOL) getDeselectSingleMode;

- (IBAction) newDocument:(id)sender;
- (IBAction) openDocument:(id)sender;
- (IBAction) mergeDocument:(id)sender;
- (IBAction) saveDocumentAs:(id) sender;
- (IBAction) saveDocument:(id) sender;
- (IBAction) copy:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) performFindPanelAction:(id)sender;
- (IBAction) centerSelectionInVisibleArea:(id)sender;
- (IBAction) findNext: (id) sender;
- (IBAction) findPrev: (id) sender;
- (IBAction) findSelect: (id) sender;

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem;

- (IBAction) resetMark: (id)sender;
- (IBAction) reverseMark: (id)sender;
- (IBAction) delete: (id)sender;
- (IBAction) deleteIfUnmarked: (id)sender;
- (IBAction) deselectSingle: (id) sender;
- (IBAction) check: (id) sender;
- (IBAction) selectIfChecked:(id) sender;
- (IBAction) deleteMarkedFile:(id) sender;
- (IBAction) openFileAtWorkspace:(id) sender;
- (IBAction) uncheckFirstItem: (id) sender;

@end
