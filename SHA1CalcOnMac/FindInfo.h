//
//  FindInfo.h
//  SHA1CalcOnMac
//
//  Created by  on 13/06/23.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PATH_CONTAINS = 1,
    PATH_STARTS_WITH = 2,
    PATH_ENDS_WITH = 3,
    PATH_REGEX = 4,
    SHA1 = 10,
    MD5 = 11
} SEARCH_MODE;

@interface FindInfo : NSObject

@property(assign, nonatomic) SEARCH_MODE searchMode;
@property(retain, nonatomic) NSString *searchText;

@end
