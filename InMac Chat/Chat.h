//
//  Chat.h
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Chat : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSTextFieldDelegate, NSWindowDelegate>

+ (Chat *)shared;

- (void)didGetNewMessagesRequest;

@property (strong, nonatomic) NSArray *messages;

@property (weak) IBOutlet NSTextField *messageTextField;
@property (weak) IBOutlet NSWindow *loginWindow;
@property (weak) IBOutlet NSWindow *chatWindow;

//Окно настроек
@property (weak) IBOutlet NSButton *showNotificationsButton;
@property (weak) IBOutlet NSStepper *chatUpdateSecondsStepper;
@property (weak) IBOutlet NSTextField *chatUpdateSecondsTextField;
@property (weak) IBOutlet NSButton *settingsButton;

- (IBAction)changeShowNotifications:(id)sender;
- (IBAction)changeChatUpdateSeconds:(id)sender;
- (IBAction)openSettings:(id)sender;
@property (weak) IBOutlet NSPopover *popover;

- (void)didDeleteMessageRequestFromRow:(NSInteger)row;

@end
