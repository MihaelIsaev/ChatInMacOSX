//
//  ChatWindow.h
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreText/CoreText.h>

@interface ChatWindow : NSWindow <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *messagesTable;
- (IBAction)removeMessage:(id)sender;

@end
