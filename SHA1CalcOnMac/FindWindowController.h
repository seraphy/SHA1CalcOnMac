//
//  FindWindowController.h
//  SHA1CalcOnMac
//
//  Created by  on 13/06/02.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface FindWindowController : NSWindowController

@property(retain) id delegate;

-(id) init;

-(NSString *) searchString;
-(void) setSearchString: stringValue;

@end
