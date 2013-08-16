//
//  Chat.h
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Chat : NSObject <NSURLConnectionDelegate, NSTextFieldDelegate, NSWindowDelegate>

+ (Chat *)shared;

- (void)didGetNewMessagesRequest;

@property (nonatomic) Boolean moderatorMode;
@property (nonatomic) NSInteger unreadedMessages;
@property (strong, nonatomic) NSArray *messages;

@property (weak) IBOutlet NSTextField *messageTextField;
@property (weak) IBOutlet NSWindow *loginWindow;
@property (weak) IBOutlet NSWindow *chatWindow;

//Окно настроек
@property (weak) IBOutlet NSButton *showNotificationsButton;
@property (weak) IBOutlet NSButton *countUnreadInDockButton;
@property (weak) IBOutlet NSButton *playSoundIncomingMessageButton;
@property (weak) IBOutlet NSButton *playSoundOutcomingMessageButton;
@property (weak) IBOutlet NSStepper *chatUpdateSecondsStepper;
@property (weak) IBOutlet NSTextField *chatUpdateSecondsTextField;
@property (weak) IBOutlet NSMenuItem *alwaysOnTopMenuItem;
@property (weak) IBOutlet NSButton *settingsButton;
@property (weak) IBOutlet NSPopover *popover;

- (IBAction)changeShowNotifications:(id)sender;
- (IBAction)changeCountUnreadInDock:(id)sender;
- (IBAction)changePlaySoundIncomingMessage:(id)sender;
- (IBAction)changePlaySoundOutcomingMessage:(id)sender;
- (IBAction)changeChatUpdateSeconds:(id)sender;
- (IBAction)changeAlwaysOnTop:(id)sender;
- (IBAction)openSettings:(id)sender;

- (void)didDeleteMessageRequestFromRow:(NSInteger)row;
- (void)loadMessages;

@end
