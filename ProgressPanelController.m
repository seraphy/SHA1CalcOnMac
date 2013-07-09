//
//  ProgressPanelController.m
//  SHA1CalcOnMac
//
//  Created by  on 13/07/06.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "ProgressPanelController.h"

@implementation ProgressPanelController {
    @private
    IBOutlet NSProgressIndicator *progressBar;
}

@synthesize window = _window;
@synthesize cancelled = _cancelled;

-(void) dealloc
{
    [super dealloc];
}

-(void) showSheet: (NSWindow *)parent
{
    _cancelled = NO;
    [NSApp beginSheet: _window
       modalForWindow: parent
        modalDelegate: nil
       didEndSelector: NULL
          contextInfo: NULL];
}

-(IBAction) onProgressCancel:(id)sender
{
    _cancelled = YES;
    [NSApp endSheet: _window
         returnCode: 1];
    [_window orderOut: sender];
}

-(void) setProgress:(NSUInteger)current max: (NSUInteger)max
{
    NSUInteger pert = (current / (double) max) * 100;
    
    [progressBar setMinValue: 0];
    [progressBar setMaxValue: 100];
    [progressBar setDoubleValue: pert];
}

@end
