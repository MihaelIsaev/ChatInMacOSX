//
//  News.h
//  InMac Chat
//
//  Created by mihael on 17.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface News : NSObject <NSTableViewDataSource, NSTableViewDelegate>

@property (strong, nonatomic) NSArray *news;
@property (weak) IBOutlet NSProgressIndicator *progressBar;

@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSTableView *tableView;

- (IBAction)clickButton:(NSButton*)sender;

@end
