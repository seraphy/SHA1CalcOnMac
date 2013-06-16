//
//  PreferencesController.m
//  SHA1CalcOnMac
//
//  Created by  on 13/06/09.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "PreferenceWindowController.h"

@implementation PreferenceWindowController {
    
    IBOutlet NSButton *chkSkipHidden;
    
    IBOutlet NSTextField *txtMaxOpenFiles;
    
}

-(id) init
{
    if (![super initWithWindowNibName: @"PreferenceWindow" owner: self]) {
        return nil;
    }
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    BOOL skipHidden = [userDefault boolForKey: @"skipHidden"];
    [chkSkipHidden setState: (skipHidden ? NSOnState : NSOffState)];
    
    NSInteger maxOpenFiles = [userDefault integerForKey: @"maxOpenFiles"];
    [txtMaxOpenFiles setIntegerValue: maxOpenFiles];
}

-(IBAction) changeSkipHidden: (id)sender
{
    NSInteger state = [chkSkipHidden state];
    NSLog(@"changeSkipHidden %ld", state);

    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool: state ? YES : NO forKey: @"skipHidden"];
}

-(void) changeMaxOpenFiles
{
    NSInteger maxOpenFiles = [txtMaxOpenFiles integerValue];
    NSLog(@"changeMaxOpenFiles %ld", maxOpenFiles);
    
    if (maxOpenFiles <= 0) {
        maxOpenFiles = 1;
        [txtMaxOpenFiles setIntegerValue: maxOpenFiles];
    }

    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setInteger: maxOpenFiles forKey: @"maxOpenFiles"];
}

- (void)controlTextDidChange:(NSNotification *)notification
{
    NSTextField *textField = [notification object];
    if ([textField isEqual: txtMaxOpenFiles]) {
        [self changeMaxOpenFiles];
    }
}

@end
