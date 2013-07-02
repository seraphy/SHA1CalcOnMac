//
//  FindInfoMatcher.h
//  SHA1CalcOnMac
//
//  Created by  on 13/06/23.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HashItem.h"
#import "FindInfo.h"

@interface FindInfoMatcher : NSObject

@property(readonly) FindInfo *findInfo;

+(FindInfoMatcher *) findInfoMatcher: (FindInfo *) aFindInfo;

-(id) initWithFindInfo: (FindInfo *) aFindInfo;

-(NSString *) itemString: (HashItem *) hashItem;

-(BOOL) isMatch: (HashItem *) hashItem;

-(BOOL) isMatchWithItemString: (NSString *) itemString;

@end

