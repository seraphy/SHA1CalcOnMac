//
//  learningAppDelegate.m
//  TestApp1
//
//  Created by  on 13/05/03.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "learningAppDelegate.h"
#include <CommonCrypto/CommonDigest.h>

@implementation HashItem : NSObject

@synthesize url;
@synthesize hash;

- (id) initWithURL: (NSURL *)aUrl
{
    self = [super init];
    self.url = aUrl;
    return self;
}

- (id) initWithURL: (NSURL *)aUrl hash: (NSString *) aHash
{
    self = [super init];
    self.url = aUrl;
    self.hash = aHash;
    return self;
}

- (NSString *) getName
{
    return [url path];
}

@end


@implementation learningAppDelegate

@synthesize window = _window;

- (id) init
{
    self = [super init];
    array = [[NSMutableArray alloc] init];
    return self;
}

- (void) dealloc
{
    [array release];
    [super dealloc];
}


- (void) openDocument:(id)sender
{
    NSLog(@"openDocument!");
}

- (BOOL) isEmpty
{
    return [array count] <= 0;
}

- (BOOL)windowShouldClose:(id)sender
{
    BOOL ret = YES;
    
    if (![self isEmpty]) {
        NSAlert *alert = [NSAlert alertWithMessageText: @"Confirm"
                                         defaultButton: @"YES"
                                       alternateButton: @"NO"
                                           otherButton: nil
                             informativeTextWithFormat: @"Are you sure discade changes?"];
        if ([alert runModal] != NSAlertDefaultReturn) {
            ret = NO;
        }
    }

    return ret;
}

- (void)windowWillClose: (id) sender
{
    NSLog(@"windowWillClose!!!");

    [threadCond lock];
    [thread cancel];
    [threadCond signal];
    [threadCond unlock];
    
    if (_window) {
        _window = nil;
        //[[NSApplication sharedApplication] terminate: self];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    NSLog(@"applicationShouldTerminateAfterLastWindowClosed");
    return YES;
}

- (IBAction) sayHello: (id) sender {
    NSString *msg = [@"Hello, " stringByAppendingString: [inputField stringValue]];
    [outputField setStringValue: msg];
}

- (IBAction) showMessageDialog: (id) sender {
    NSString *msg = [@"Hello, " stringByAppendingString: [inputField stringValue]];
    NSAlert *alert = [NSAlert alertWithMessageText: msg
                                     defaultButton: @"OK"
                                   alternateButton: nil
                                       otherButton: nil
                         informativeTextWithFormat: @"This is message"];
    [alert runModal];
}

- (IBAction) openFileDialog:(id)sender
{
    NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
    [openPanel setAllowsMultipleSelection: YES];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *urls = [openPanel URLs];
            NSLog(@"%@", [urls description]);
            
            @synchronized(array) {
                for (NSURL *url in urls)
                {
                    NSLog(@"%@", [url path]);
                    HashItem *hashItem = [[HashItem alloc] initWithURL: url];
                    [array addObject: hashItem];
                    [hashItem release];
                }
            }
            
            [tableView reloadData];
            
            [threadCond lock];
            [threadCond signal];
            [threadCond unlock];
        }
        [openPanel release];
        NSLog(@"Release");
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    @synchronized(array) {
        return [array count];
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString *msg = nil;
    NSString *identifier = [aTableColumn identifier];

    HashItem *hashItem;
    @synchronized(array) {
        hashItem = [array objectAtIndex: rowIndex];
    }
    
    if ([identifier isEqualToString: @"Name"]) {
        msg = [[hashItem url] path];
        
    } else if ([identifier isEqualToString: @"SHA1"]) {
        msg = [hashItem hash];
        
    } else {
        msg = [NSString stringWithFormat: @"%@, %d", [aTableColumn identifier], rowIndex];
    }
    return msg;
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray *newDescriptors = [aTableView sortDescriptors];
    NSLog(@"SortDscriptor-Size: %ld", [newDescriptors count]);
    for (NSSortDescriptor *desc in newDescriptors) {
        NSLog(@"SortDscriptor: %@", desc);
    }
    [array sortUsingDescriptors: newDescriptors];
    [tableView reloadData];
}

- (IBAction) cut:(id)sender
{
    NSLog(@"Cut");
}

- (void) threadProc: (id) args
{
    NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    int cnt = 0;
    [threadCond lock];
    while (![[NSThread currentThread] isCancelled]) {
        NSLog(@"tick! %d", cnt++);
        HashItem *hashItem = nil;
        @synchronized(array) {
            for (HashItem *item in array) {
                if ([item.hash length] == 0) {
                    hashItem = [item retain];
                    break;
                }
            }
        }
        if (hashItem == nil) {
            [threadCond wait];
            continue;
        }
        [threadCond unlock];

        hashItem.hash = @"loading...";
        dispatch_async(dispatch_get_main_queue(), ^{
            //[tableView reloadItem: hashItem];
            [tableView reloadData];
        });

        NSAutoreleasePool *internalPool = [[NSAutoreleasePool alloc] init];

        NSString *path = [hashItem.url path];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath: path];
        
        CC_SHA1_CTX ctx = {0};
        CC_SHA1_Init(&ctx);
        for (;;) {
            NSData *contents = [fileHandle readDataOfLength: 4096];
            if ([contents length] == 0) {
                break;
            }
            CC_SHA1_Update(&ctx, [contents bytes], (unsigned int) [contents length]);
        }
        [fileHandle closeFile];

        unsigned char digest[CC_SHA1_DIGEST_LENGTH];
        CC_SHA1_Final(digest, &ctx);
        
        NSMutableString * result = [[NSMutableString alloc]
                                    initWithCapacity: (CC_SHA1_DIGEST_LENGTH * 2)];
        for (int idx = 0; idx < CC_SHA1_DIGEST_LENGTH; idx++) {
            [result appendString: [NSString stringWithFormat: @"%02x", digest[idx]]];
        }
        hashItem.hash = result;
        [result release];
        
        [hashItem release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //[tableView reloadItem: hashItem];
            [tableView reloadData];
        });
        [internalPool release];

        [threadCond lock];
    }
    [threadCond unlock];
    NSLog(@"end thread.");
    [autoreleasePool release];
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    threadCond = [[NSCondition alloc] init];
    thread = [[NSThread alloc] initWithTarget: self selector: @selector(threadProc:) object: nil];
    [thread start];
    
    NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
    [fmt setDateFormat: @"yyyy/MM/dd"];
    
    NSDate *today = [NSDate date];
    NSString *strDate = [fmt stringFromDate: today];
    
    [inputField setStringValue: strDate];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (_window) {
        NSLog(@"window %@", _window);
        [_window performClose: self];
        return NSTerminateCancel;
    }
    return NSTerminateNow;
}

- (void) applicationWillTerminate:(NSNotification *)notification
{
    [thread release];
    [threadCond release];
    NSLog(@"ApplicationWillTerminate!!!");
}

- (IBAction) openPreference: (id) sender
{
    NSLog(@"preference!");
}

@end
