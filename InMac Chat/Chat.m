//
//  Chat.m
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "Chat.h"
#import "NSString+Magic.h"
#import "AppDelegate.h"

@interface Chat ()

@property (strong, nonatomic) NSString *lastMessageID;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSHTTPURLResponse *response;
@property (strong, nonatomic) NSMutableData *responseData;
@property (strong, nonatomic) NSUserNotification *notification;

@end

@implementation Chat

static Chat *shared;

+ (Chat *)shared
{
    return shared;
}

- (id)init
{
    if(shared)
        NSLog(@"Error: You are creating a second Chat shared object");
    shared = self;
    self.lastMessageID = @"0";
    NSNumber *showNotifications = [AppDelegate getObject:kInMacShowNotifications];
    if(!showNotifications)
    {
        showNotifications = [NSNumber numberWithBool:YES];
        [AppDelegate saveObject:showNotifications forKey:kInMacShowNotifications];
    }
    NSNumber *chatUpdateSeconds = [AppDelegate getObject:kInMacChatUpdateSeconds];
    if(!chatUpdateSeconds)
    {
        chatUpdateSeconds = [NSNumber numberWithInt:5];
        [AppDelegate saveObject:chatUpdateSeconds forKey:kInMacChatUpdateSeconds];
    }
    return self;
}

- (void)didGetNewMessagesRequest
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://inmac.org/json/chat/?last=%@", self.lastMessageID]]];
    NSString *paramsString = [NSString stringWithFormat:@"last=%@", self.lastMessageID];
    [request setHTTPBody:[paramsString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"http://inmac.org/login.php?redirect=/" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    [request setTimeoutInterval:10];
    if(self.connection)
    {
        [self.connection cancel];
        self.connection = nil;
    }
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.connection start];
}

- (void)didSendMessageRequest
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://inmac.org/json/chat/"]];
    NSString *paramsString = [NSString stringWithFormat:@"msg=%@", self.messageTextField.stringValue];
    [request setHTTPBody:[paramsString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"http://inmac.org/login.php?redirect=/" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    [request setTimeoutInterval:10];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [conn start];
    self.messageTextField.stringValue = @"";
}

- (void)didDeleteMessageRequestFromRow:(NSInteger)row
{
    NSDictionary *message = [self.messages objectAtIndex:row];
    NSString *messageID = [message objectForKey:@"id"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://inmac.org/json/chat/"]];
    NSString *paramsString = [NSString stringWithFormat:@"mode=delete&p=%@", messageID];
    [request setHTTPBody:[paramsString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"http://inmac.org/login.php?redirect=/" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    [request setTimeoutInterval:10];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [conn start];
    NSMutableArray *messages = [self.messages mutableCopy];
    [messages removeObjectAtIndex:row];
    self.messages = [messages copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"newMessages" object:nil];
}

#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)resp
{
    self.response = resp;
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    [self.responseData appendData:data];
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    NSError *error = nil;
    NSDictionary *chatAnswer = [NSJSONSerialization JSONObjectWithData:self.responseData options:kNilOptions error:&error];
    if(!error && [[self.response.allHeaderFields objectForKey:@"Content-Type"] isEqualToString:@"application/json"])
    {
        NSArray *messages = [chatAnswer objectForKey:@"messages"];
        if(messages.count>0)
        {
            [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
            self.notification = [[NSUserNotification alloc] init];
            self.notification.title = @"InMac Chat";
            if(messages.count==1)
            {
                NSDictionary *message = [messages objectAtIndex:0];
                NSString *user = [[message objectForKey:@"user"] stringByStrippingHTML];
                NSString *text = [[message objectForKey:@"text"] stringByStrippingHTML];
                self.notification.informativeText = [NSString stringWithFormat:@"%@: %@", user, text];
            }
            else
                self.notification.informativeText = [NSString stringWithFormat:@"Новые сообщения: %liшт.", messages.count];
            if([[AppDelegate getObject:kInMacShowNotifications] boolValue])
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:self.notification];
            NSDictionary *lastMessage = [messages objectAtIndex:0];
            NSString *messageID = [lastMessage objectForKey:@"id"];
            self.lastMessageID = messageID;
            self.messages = [messages arrayByAddingObjectsFromArray:self.messages];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"newMessages" object:nil];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            sleep([[AppDelegate getObject:kInMacChatUpdateSeconds] floatValue]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didGetNewMessagesRequest];
            });
        });
    }
    else
        NSLog(@"chat messages error: %@ responseData: %@", [error localizedDescription], [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [self didGetNewMessagesRequest];
}

#pragma mark - ChatWindow Delegate
- (void)windowDidResize:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"newMessages" object:nil];
}

#pragma mark - NSTextField Delegate
-(void)controlTextDidEndEditing:(NSNotification *)notification
{
    if([[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
    {
        [self didSendMessageRequest];
    }
}

#pragma mark - SettingsWindow Delegate
- (IBAction)changeShowNotifications:(NSButton*)sender
{
    if(sender.state==0)
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    [AppDelegate saveObject:[NSNumber numberWithInteger:sender.state] forKey:kInMacShowNotifications];
}

- (IBAction)changeChatUpdateSeconds:(NSStepper*)sender
{
    [AppDelegate saveObject:[NSNumber numberWithInt:sender.intValue] forKey:kInMacChatUpdateSeconds];
    self.chatUpdateSecondsTextField.stringValue = [NSString stringWithFormat:@"%i", sender.intValue];
}

- (IBAction)openSettings:(id)sender
{
    if([self.popover isShown])
        [self.popover close];
    else
    {
        [self.popover showRelativeToRect:self.settingsButton.bounds ofView:self.settingsButton preferredEdge:NSMaxYEdge];
        NSNumber *showNotifications = [AppDelegate getObject:kInMacShowNotifications];
        [self.showNotificationsButton setState:[showNotifications boolValue]];
        NSNumber *chatUpdateSeconds = [AppDelegate getObject:kInMacChatUpdateSeconds];
        self.chatUpdateSecondsTextField.stringValue = [NSString stringWithFormat:@"%.0f", [chatUpdateSeconds floatValue]];
        [self.chatUpdateSecondsStepper setIntValue:[chatUpdateSeconds intValue]];
    }
}

@end