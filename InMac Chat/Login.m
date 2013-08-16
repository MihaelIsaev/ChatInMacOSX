//
//  Login.m
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "Login.h"
#import "Chat.h"
#import "HTMLParser.h"
#import "NSString+Magic.h"

@interface Login ()

@property (strong, nonatomic) NSString *secretKey;
@property (strong, nonatomic) NSString *secretValue;

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
    [self.logoutMenuItem setHidden:YES];
    return self;
}

- (IBAction)didLogin:(id)sender
{
    [self didStartLogining];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *error = nil;
            HTMLParser *parser = [[HTMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://inmac.org"] error:&error];
            if(!error)
            {
                HTMLNode *bodyNode = [parser body];
                HTMLNode *loginFormNode = [bodyNode findChildWithAttribute:@"id" matchingName:@"form_login" allowPartial:NO];
                for(HTMLNode *hiddenNode in [loginFormNode findChildrenWithAttribute:@"type" matchingName:@"hidden" allowPartial:NO])
                    if([hiddenNode getAttributeNamed:@"id"].length>0)
                    {
                        self.secretKey = [hiddenNode getAttributeNamed:@"id"];
                        for(HTMLNode *scriptNode in [[parser doc] findChildTags:@"script"])
                        {
                            NSString *keyFormat = [NSString stringWithFormat:@"document.getElementById('%@').value = '", [hiddenNode getAttributeNamed:@"id"]];
                            if([[scriptNode rawContents] contains:keyFormat])
                            {
                                NSString *result = [scriptNode rawContents];
                                result = [result replace:keyFormat to:@""];
                                result = [result replace:@"<script>" to:@""];
                                result = [result replace:@"</script>" to:@""];
                                result = [result replace:@"window.onload = function() {" to:@""];
                                result = [result replace:@"}" to:@""];
                                result = [result replace:@"';" to:@""];
                                self.secretValue = [result trim];
                            }
                        }
                        break;
                    }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didTryLoginRequest];
            });
        });
}

- (IBAction)didLogout:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://inmac.org/login.php"]];
        [request setHTTPBody:[@"logout=1" dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPMethod:@"POST"];
        [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.logoutMenuItem setHidden:YES];
            self.isAuthorized = NO;
            [self.chatWindow close];
            [self.loginWindow setIsVisible:YES];
        });
    });
}

- (void)didTryLoginRequest
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://inmac.org/login.php"]];
    NSString *paramsString = [NSString stringWithFormat:@"redirect=/&login_username=%@&login_password=%@&%@=%@&login=Вход", self.loginTextField.stringValue, self.passwordTextField.stringValue, self.secretKey, self.secretValue];
    [request setHTTPBody:[paramsString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"http://inmac.org/login.php?redirect=/" forHTTPHeaderField:@"Referer"];
    [request setTimeoutInterval:10];
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
        [self.logoutMenuItem setHidden:NO];
        [self.loginWindow close];
        [self.chatWindow setIsVisible:YES];
        [[Chat shared] didGetNewMessagesRequest];
    }
    else
    {
        [self.logoutMenuItem setHidden:YES];
        [self.loginTextField becomeFirstResponder];
    }
}

@end
