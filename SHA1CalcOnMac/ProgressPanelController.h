//
//  ProgressPanelController.h
//  SHA1CalcOnMac
//
//  Created by  on 13/07/06.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProgressPanelController : NSObject

@property(assign) BOOL cancelled;
@property(assign) IBOutlet NSWindow *window;

-(void) showSheet:(NSWindow *)parent;
-(void) setProgress:(NSUInteger)current max: (NSUInteger)max;

-(IBAction) onProgressCancel:(id)sender;

@end
