//
//  HashItemList.h
//  SHA1CalcOnMac
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HashItem.h"
#import "FindInfoMatcher.h"

// 前方宣言
@class HashItemList;

typedef BOOL (^ProgressCallback)(NSUInteger max, NSUInteger current);

/**********
 * ハッシュアイテムの変更通知を受け取るプロトコル
 **********/
@protocol HashItemListNotification <NSObject>
@optional

/**
 * ハッシュ値が変更されたことを通知する.
 * @param hashItem ハッシュアイテム
 */
- (void) updateHashItem: (HashItem *) hashItem;

@end


/**********
 * パスとハッシュ値を保持するクラス.
 **********/
@interface HashItemList : NSObject

/**
 * 隠しファイルをスキップするか?
 */
@property (assign) BOOL skipHidden;

/**
 * ハッシュ値が変更されたことを通知されるデリゲート
 */
@property (retain) id<HashItemListNotification> delegate;

/**
 * 保存済みドキュメントのパス
 */
@property (retain) NSURL *documentURL;

/**
 * リストが変更されるとtrueとなる.
 */
@property (assign) BOOL modified;

/**
 * ハッシュアイテムを登録する
 */
- (void) add: (HashItem *) hashItem;

/**
 * URLを登録する.
 * ディレクトリのURLは無視される.
 */
- (void) addFileWithURL: (NSURL *) url;

/**
 * URLのリストを登録する.
 * サブディレクトリ内も列挙される.
 */
- (void) addWithURLArray: (NSArray *)urls;

/**
 * 指定したインデックスのチェック状態を変更する.
 */
- (void) setChecked: (NSIndexSet *) selrow state: (BOOL) sw;

/**
 * 指定したインデックスのチェック状態を反転する.
 */
- (void) reverseChecked: (NSIndexSet *) selrows;

/**
 * クリアする.
 */
- (void) clear;

/**
 * 指定したインデックスを削除する.
 */
- (void ) removeByIndexes: (NSIndexSet *) selrows;

/**
 * 指定したインデックスのハッシュアイテムを取得する.
 * 範囲外であればnilを返す.
 * @param rowIndex インデックス(0ベース)
 * @return ハッシュインデックス、またはnil
 */
- (HashItem *) getItemByIndex: (NSInteger) rowIndex;

/**
 * 指定されたインデックスセットのアイテムを返す.
 * @param indexes インデックスセット
 * @return ハッシュアイテムのリスト
 */
- (NSArray *) getItemByIndexes: (NSIndexSet *) indexes;

/**
 * まだ計算されていないハッシュアイテムを検索して取得する.
 * すべて計算済みであればnilを返す.
 * @return ハッシュインデックス、またはnil
 */
- (HashItem *) getFirstUncalcuratedItem;

/**
 * 指定したインデックス以降の対象文字列を検索する.
 */
- (NSInteger) findNext: (FindInfoMatcher *)findInfoMatcher startRow: (NSInteger) startRow;

/**
 * 指定したインデックス以前の対象文字列を検索する.
 */
- (NSInteger) findPrev: (FindInfoMatcher *)findInfoMatcher startRow: (NSInteger) startRow;

/**
 * 対象文字列をすべて検索する.
 */
- (NSIndexSet *) findAll: (FindInfoMatcher *)findInfoMatcher;

/**
 * ハッシュアイテムの内容を変更したことを通知する.
 * @param hashItem ハッシュアイテム
 */
- (void) updateHashItem: (HashItem *) hashItem;

/**
 * ハッシュアイテムの保持している個数
 * @return 個数
 */
- (NSInteger) count;

/**
 * ソートする
 * @param ソート対象のプロパティ情報
 */
- (void) sortUsingDescriptors: sortDescriptors;

/**
 * 指定した行セットでSHA1SUMの最初のアイテムのチェックを外す.
 */
- (void) uncheckFirstItem: (NSIndexSet *) selrows;

/**
 * チェックされている行を取得する
 */
- (NSIndexSet *) getCheckedRowIndexes;

/**
 * 評価ブロックがYESを返すアイテムを除去する.
 */
- (void) deleteIf: (BOOL (^)(HashItem *)) block;

/**
 * ハッシュアイテムのステートを一括変更する.
 */
- (void) setStateByIndexes: (NSIndexSet *) selrows state: (HashItemState) state;

/**
 * 存在しないファイルはチェックを外す.
 */
- (void) unmarkMissingFiles:(NSIndexSet *)selrows ProgressCallback: (ProgressCallback) callback;

@end

BOOL isInvisible(NSString *str, BOOL isFile);
