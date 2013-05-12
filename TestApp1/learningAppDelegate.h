//
//  learningAppDelegate.h
//  TestApp1
//
//  Created by  on 13/05/03.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HashItem : NSObject
@property(retain) NSURL *url;
@property(retain) NSString *hash;
@property(readonly, getter=getName) NSString *name;

- (id) initWithURL: (NSURL *)aUrl;
- (id) initWithURL: (NSURL *)aUrl hash: (NSString *) aHash;
- (NSString *) getName;
@end


@interface learningAppDelegate : NSObject <NSApplicationDelegate> {
@private
    IBOutlet id inputField;
    IBOutlet id outputField;
    IBOutlet id tableView;
    NSMutableArray *array;
    NSThread *thread;
    NSCondition *threadCond;
}

@property (assign) IBOutlet NSWindow *window;

- (void) threadProc: (id)args;
- (BOOL) isEmpty;
- (IBAction) sayHello:(id)sender;
- (IBAction) showMessageDialog:(id)sender;
- (IBAction) openPreference:(id)sender;

@end
