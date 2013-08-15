//
//  Login.m
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "Login.h"
#import "Chat.h"

@interface Login ()

@end

@implementation Login

static Login *shared;

+ (Login *)shared
{
    return shared;
}

- (id)init
{
    if(shared)
        NSLog(@"Error: You are creating a second Login shared object");
    shared = self;
    return self;
}

- (IBAction)didLogin:(id)sender
{
    [self didTryLoginRequest];
}

- (void)didTryLoginRequest
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://inmac.org/login.php"]];
    NSString *paramsString = [NSString stringWithFormat:@"redirect=/&login_username=%@&login_password=%@&fc0103a2=nto7f49BvuY=&login=Вход", self.loginTextField.stringValue, self.passwordTextField.stringValue];
    [request setHTTPBody:[paramsString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"http://inmac.org/login.php?redirect=/" forHTTPHeaderField:@"Referer"];
    [request setTimeoutInterval:10];
    [self didStartLogining];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [connection start];
}

#pragma mark - NSTextField Delegate
-(void)controlTextDidEndEditing:(NSNotification *)notification
{
    if([[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
    {
        if([notification.object isEqual:self.loginTextField])
            [self.passwordTextField becomeFirstResponder];
        else if([notification.object isEqual:self.passwordTextField])
            [self didTryLoginRequest];
    }
}

#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)resp
{
    NSString *expires = [resp.allHeaderFields objectForKey:@"Expires"];
    self.isAuthorized = (expires && [expires isEqualToString:@"0"]);
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    [self didEndLogining];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [self didEndLogining];
    NSLog(@"login fail with error connection");
}

- (void)didStartLogining
{
    [self.loginProgressIndicator startAnimation:self.loginProgressIndicator];
    [self.loginTextField setEnabled:NO];
    [self.passwordTextField setEnabled:NO];
    [self.loginButton setEnabled:NO];
    [self.loginButton setTitle:@"..."];
}

- (void)didEndLogining
{
    [self.loginProgressIndicator stopAnimation:self.loginProgressIndicator];
    [self.loginTextField setEnabled:YES];
    [self.passwordTextField setEnabled:YES];
    [self.loginButton setEnabled:YES];
    [self.loginButton setTitle:@"Войти"];
    if(self.isAuthorized)
    {
        [self.loginWindow close];
        [self.chatWindow setIsVisible:YES];
        [[Chat shared] didGetNewMessagesRequest];
    }
}

@end
