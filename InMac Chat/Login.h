//
//  Login.h
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Login : NSObject <NSURLConnectionDelegate, NSTextFieldDelegate>

+ (Login *)shared;

@property (nonatomic) BOOL isAuthorized;

@property (weak) IBOutlet NSWindow *loginWindow;
@property (weak) IBOutlet NSWindow *chatWindow;
@property (weak) IBOutlet NSProgressIndicator *loginProgressIndicator;
@property (weak) IBOutlet NSTextField *loginTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSButton *loginButton;
@property (weak) IBOutlet NSMenuItem *logoutMenuItem;

- (IBAction)didLogin:(id)sender;
- (IBAction)didLogout:(id)sender;

@end
