//
//  PreferencesController.h
//  SHA1CalcOnMac
//
//  Created by  on 13/06/09.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferenceWindowController : NSWindowController

-(id) init;
-(void)controlTextDidChange:(NSNotification *)notification;
-(void) changeMaxOpenFiles;

-(IBAction) changeSkipHidden: (id)sender;

@end
