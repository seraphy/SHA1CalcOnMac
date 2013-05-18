//
//  HashCalcurateThread.h
//  TestApp1
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HashItemList.h"

/**
 * ハッシュ値を計算するスレッド.
 */
@interface HashCalcurateThread : NSThread

/**
 * 計算すべきハッシュリスト
 */
@property (retain) HashItemList *hashItemList;

/**
 * スレッドに変更を通知する.
 */
- (void) notify;

/**
 * スレッドに停止を要求する.
 */
- (void) requestCancel;

/**
 * バイナリを16進数文字列にする.
 * @param digest バイナリ
 * @return 16進数文字列
 */
- (NSString *) bin2hex: (unsigned char *) digest len:(int) len;

@end
