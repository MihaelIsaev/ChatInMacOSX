//
//  Chat.h
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatWindow.h"

@interface Chat : NSObject <NSURLConnectionDelegate, NSWindowDelegate>

+ (Chat *)shared;

- (void)didGetNewMessagesRequest;

@property (nonatomic) Boolean moderatorMode;
@property (nonatomic) NSInteger unreadedMessages;
@property (strong, nonatomic) NSArray *messages;

@property (weak) IBOutlet NSWindow *loginWindow;
@property (weak) IBOutlet ChatWindow *chatWindow;

//Окно настроек
@property (weak) IBOutlet NSButton *showNotificationsButton;
@property (weak) IBOutlet NSButton *countUnreadInDockButton;
@property (weak) IBOutlet NSButton *playSoundIncomingMessageButton;
@property (weak) IBOutlet NSButton *playSoundOutcomingMessageButton;
@property (weak) IBOutlet NSButton *removeOldMessagesButton;
@property (weak) IBOutlet NSButton *playRadioOnStartButton;
@property (weak) IBOutlet NSStepper *chatUpdateSecondsStepper;
@property (weak) IBOutlet NSTextField *chatUpdateSecondsTextField;
@property (weak) IBOutlet NSMenuItem *alwaysOnTopMenuItem;
@property (weak) IBOutlet NSButton *settingsButton;
@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSScrollView *chatScrollView;

- (IBAction)changeShowNotifications:(id)sender;
- (IBAction)changeCountUnreadInDock:(id)sender;
- (IBAction)changePlaySoundIncomingMessage:(id)sender;
- (IBAction)changePlaySoundOutcomingMessage:(id)sender;
- (IBAction)changeRemoveOldMessages:(id)sender;
- (IBAction)changePlayRadioOnStart:(id)sender;
- (IBAction)changeChatUpdateSeconds:(id)sender;
- (IBAction)changeAlwaysOnTop:(id)sender;
- (IBAction)openSettings:(id)sender;

- (void)didDeleteMessageRequestFromRow:(NSInteger)row;
- (void)didSendMessageRequest;
- (void)loadMessages;
- (void)removeOldMessages;

@end
