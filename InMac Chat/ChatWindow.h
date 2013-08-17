//
//  ChatWindow.h
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ChatWindow : NSWindow <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, NSTabViewDelegate>

@property (weak) IBOutlet NSTextField *messageTextField;
@property (weak) IBOutlet NSTableView *messagesTable;
@property (weak) IBOutlet NSButton *smilesButton;
@property (weak) IBOutlet NSPopover *smilesPopover;

- (IBAction)showSmiles:(id)sender;
- (IBAction)removeMessage:(id)sender;
- (IBAction)clickSmile:(id)sender;
@property (weak) IBOutlet NSImageView *smile;

@end
