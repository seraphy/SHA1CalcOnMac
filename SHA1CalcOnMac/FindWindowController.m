//
//  FindWindowController.m
//  SHA1CalcOnMac
//
//  Created by  on 13/06/02.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "FindWindowController.h"

@implementation FindWindowController {
    
    IBOutlet NSTextField *txtSearch;
    
}

@synthesize delegate = _delegate;

-(id) init
{
    if (![super initWithWindowNibName: @"FindWindow" owner: self]) {
        return nil;
    }
    return self;
}

-(IBAction) findNext:(id)sender
{
    [_delegate findNext: sender];
}

-(IBAction) findPrev:(id)sender
{
    [_delegate findPrev: sender];
}

-(IBAction) findSelect:(id)sender
{
    [_delegate findSelect: sender];
}

-(NSString *) searchString
{
    return [txtSearch stringValue];
}

-(void) setSearchString: stringValue
{
    [txtSearch setStringValue: stringValue];
}

@end
