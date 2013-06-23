//
//  FindWindowController.m
//  SHA1CalcOnMac
//
//  Created by  on 13/06/02.
//  Copyright (c) 2013 seraphyware.jp. All rights reserved.
//

#import "FindWindowController.h"

@implementation FindWindowController {
    
    IBOutlet NSComboBox *txtSearch;
    
    IBOutlet NSPopUpButton *popupSearchMode;
}

@synthesize delegate = _delegate;

-(id) init
{
    if (![super initWithWindowNibName: @"FindWindow" owner: self]) {
        return nil;
    }
    
    return self;
}

- (void) dealloc
{
    self.delegate = nil;
    [super dealloc];
}

- (void)awakeFromNib
{
    // Panelの初期化
}

- (void) saveSearchText
{
    bool skip = NO;
    NSString *searchText = [txtSearch stringValue];
    for (NSString *text in [txtSearch objectValues]) {
        if ([searchText isEqualToString: text]) {
            skip = YES;
            break;
        }
    }
    if (!skip) {
        [txtSearch insertItemWithObjectValue: searchText atIndex: 0];
    }
}

-(IBAction) findNext:(id)sender
{
    [self saveSearchText];
    [_delegate findNext: sender];
}

-(IBAction) findPrev:(id)sender
{
    [self saveSearchText];
    [_delegate findPrev: sender];
}

-(IBAction) findSelect:(id)sender
{
    [self saveSearchText];
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

- (SEARCH_MODE) searchMode
{
    return (SEARCH_MODE)[popupSearchMode selectedTag];
}

- (void) setSearchMode: (SEARCH_MODE) aSearchMode
{
    for (NSMenuItem *menuItem in [popupSearchMode itemArray]) {
        NSInteger tag = [menuItem tag];
        if (tag == aSearchMode) {
            [popupSearchMode selectItem: menuItem];
            break;
        }
    }
}


@end
