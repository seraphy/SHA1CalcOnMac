//
//  FindInfo.m
//  SHA1CalcOnMac
//
//  Created by  on 13/06/23.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "FindInfo.h"

@implementation FindInfo

@synthesize searchText = _searchText;
@synthesize searchMode = _searchMode;

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    self.searchMode = PATH_CONTAINS;
    self.searchText = nil;
    [super dealloc];
}



@end
