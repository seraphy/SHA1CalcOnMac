//
//  HashItem.h
//  TestApp1
//
//  Created by  on 13/05/18.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HashItem : NSObject

@property(assign) BOOL checked;
@property(assign) NSInteger rowIndex;
@property(retain) NSURL *url;
@property(retain) NSString *sha1hash;
@property(retain) NSString *md5hash;

@property(readonly, getter=getName) NSString *name;

- (id) initWithURL: (NSURL *)aUrl;
- (id) initWithURL: (NSURL *)aUrl hash: (NSString *) aHash;
- (NSString *) getName;
@end
