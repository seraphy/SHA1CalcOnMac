//
//  HashCalcurateThread.m
//  TestApp1
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#include <CommonCrypto/CommonDigest.h>

#import "HashCalcurateThread.h"

@implementation HashCalcurateThread {
@private
    /// スレッドの同期・待機を行うためのもの
    NSCondition *threadCond;
}

@synthesize hashItemList = _hashItemList;

- (id) init
{
    self = [super init];
    threadCond = [[NSCondition alloc] init];
    return self;
}

- (void) dealloc
{
    [threadCond release];
    [super dealloc];
}

- (void) notify
{
    [threadCond lock];
    [threadCond signal];
    [threadCond unlock];
}

- (void) requestCancel
{
    [self cancel];
    [self notify];
}

- (void) main
{
    NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    unsigned char sha1digest[CC_SHA1_DIGEST_LENGTH];
    unsigned char md5digest[CC_MD5_DIGEST_LENGTH];
    
    int cnt = 0;
    [threadCond lock];
    while (![[NSThread currentThread] isCancelled]) {
        NSLog(@"tick! %d", cnt++);
        HashItem *hashItem = [_hashItemList getFirstUncalcuratedItem];
        if (hashItem == nil) {
            [threadCond wait];
            continue;
        }
        [threadCond unlock];
        
        // ハッシュアイテムの変更通知用ブロック
        void (^notifyChangeHashItem)() = ^{
            [_hashItemList notifyChangeHashItem: hashItem];
            // 非同期中は解放されないようにあらかじめretainしておいたカウントを解放する.
            [hashItem release];
        };
        
        // ループ内リリースプール
        NSAutoreleasePool *internalPool = [[NSAutoreleasePool alloc] init];
        
        // 読み取り開始通知
        hashItem.sha1hash = @"loading...";
        [hashItem retain]; // 非同期中は解放されないようにあらかじめretain
        dispatch_async(dispatch_get_main_queue(), notifyChangeHashItem);
        
        // ハッシュ用バッファ
        CC_MD5_CTX md5ctx = {0};
        CC_SHA1_CTX sha1ctx = {0};
        
        CC_MD5_Init(&md5ctx);
        CC_SHA1_Init(&sha1ctx);
        
        const size_t bufsiz = 4096;
        uint8_t buf[bufsiz] = {0};
        
        // ファイルストリーム
        NSString *path = [hashItem.url path];
        NSInputStream *istm = [NSInputStream inputStreamWithFileAtPath: path];
        
        [istm open];
        NSString *msg = nil;
        while ([istm hasBytesAvailable]) {
            NSInteger len = [istm read: buf maxLength: bufsiz];
            if (len == 0) {
                // 読み取り完了
                break;
            }
            if (len < 0) {
                msg = @"error";
                break;
            }
            if ([hashItem rowIndex] < 0) {
                msg = @"cancel";
                break;
            }
            // ハッシュ値の計算
            CC_MD5_Update(&md5ctx, buf, (unsigned int) len);
            CC_SHA1_Update(&sha1ctx, buf, (unsigned int) len);
        }
        // ファイルを閉じる
        [istm close];
        
        // ハッシュ値の確定
        CC_MD5_Final(md5digest, &md5ctx);
        CC_SHA1_Final(sha1digest, &sha1ctx);
        
        // 表示アイテムの設定
        if (msg) {
            hashItem.checked = NO;
            hashItem.sha1hash = msg;
            hashItem.md5hash = msg;
            
        } else {
            hashItem.checked = YES;
            hashItem.sha1hash = [self bin2hex: sha1digest len:CC_SHA1_DIGEST_LENGTH];
            hashItem.md5hash = [self bin2hex: md5digest len:CC_MD5_DIGEST_LENGTH];
        }
        
        // 表示の更新
        [hashItem retain]; // 非同期中は解放されないようにあらかじめretain
        dispatch_async(dispatch_get_main_queue(), notifyChangeHashItem);
        
        // 保持の解放
        [hashItem release];
        
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

@end
