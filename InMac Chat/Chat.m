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
#import "EntityMessages.h"
#import "HTMLParser.h"

@interface Chat ()

@property (strong, nonatomic) NSString *lastMessageID;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSHTTPURLResponse *response;
@property (strong, nonatomic) NSMutableData *responseData;
@property (strong, nonatomic) NSUserNotification *notification;
@property (strong, nonatomic) EntityMessages *entityMessages;
@property (strong, nonatomic) TempContext *tempContext;
@property (strong, nonatomic) NSManagedObjectContext *moc;

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
    self.unreadedMessages = 0;
    NSNumber *showNotifications = [AppDelegate getObject:kInMacShowNotifications];
    if(!showNotifications)
    {
        showNotifications = [NSNumber numberWithBool:YES];
        [AppDelegate saveObject:showNotifications forKey:kInMacShowNotifications];
    }
    NSNumber *countUnreadInDock = [AppDelegate getObject:kInMacCountUnreadInDock];
    if(!countUnreadInDock)
    {
        countUnreadInDock = [NSNumber numberWithBool:YES];
        [AppDelegate saveObject:countUnreadInDock forKey:kInMacCountUnreadInDock];
    }
    NSNumber *playSoundIncomingMessage = [AppDelegate getObject:kInMacPlaySoundIncomingMessage];
    if(!playSoundIncomingMessage)
    {
        playSoundIncomingMessage = [NSNumber numberWithBool:YES];
        [AppDelegate saveObject:playSoundIncomingMessage forKey:kInMacPlaySoundIncomingMessage];
    }
    NSNumber *playSoundOutcomingMessage = [AppDelegate getObject:kInMacPlaySoundOutcomingMessage];
    if(!playSoundOutcomingMessage)
    {
        playSoundOutcomingMessage = [NSNumber numberWithBool:YES];
        [AppDelegate saveObject:playSoundOutcomingMessage forKey:kInMacPlaySoundOutcomingMessage];
    }
    NSNumber *removeOldMessages = [AppDelegate getObject:kInMacRemoveOldMessages];
    if(!removeOldMessages)
    {
        removeOldMessages = [NSNumber numberWithBool:NO];
        [AppDelegate saveObject:removeOldMessages forKey:kInMacRemoveOldMessages];
    }
    NSNumber *playRadioOnStart = [AppDelegate getObject:kInMacPlayRadioOnStart];
    if(!playRadioOnStart)
    {
        playRadioOnStart = [NSNumber numberWithBool:NO];
        [AppDelegate saveObject:playRadioOnStart forKey:kInMacPlayRadioOnStart];
    }
    NSNumber *chatUpdateSeconds = [AppDelegate getObject:kInMacChatUpdateSeconds];
    if(!chatUpdateSeconds)
    {
        chatUpdateSeconds = [NSNumber numberWithInt:5];
        [AppDelegate saveObject:chatUpdateSeconds forKey:kInMacChatUpdateSeconds];
    }
    [self registerInMacURL];
    [[self.chatWindow firstResponder] performSelector:@selector(toggleContinuousSpellChecking:)];
    return self;
}

- (void)registerInMacURL
{
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    url = [url replace:@"inmac://" to:@""];
    NSArray *separatedURL = [url componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"~"]];
    NSString *action = [separatedURL objectAtIndex:0];
    NSString *value = [separatedURL objectAtIndex:1];
    if([action isEqualToString:@"clickOnUser"])
    {
        if(self.chatWindow.messageTextField.stringValue.length==0)
            self.chatWindow.messageTextField.stringValue = [NSString stringWithFormat:@"[b]%@[/b]: ", [[self urldecode:value] replace:@":" to:@""]];
        else
            self.chatWindow.messageTextField.stringValue = [NSString stringWithFormat:@"%@, [b]%@[/b]: ", [self.chatWindow.messageTextField.stringValue replace:@"[/b]: " to:@"[/b]"], [[self urldecode:value] replace:@":" to:@""]];
        [self.chatWindow.messageTextField becomeFirstResponder];
        [[self.chatWindow.messageTextField currentEditor] moveToEndOfLine:nil];
    }
    else if([action isEqualToString:@"openURL"])
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:value]];
    }
}

-(NSString *)urldecode:(NSString*)string
{
    NSString *result = [(NSString *)string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
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
    if(self.chatWindow.messageTextField.stringValue.length==0)
        return;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://inmac.org/json/chat/"]];
    NSString *paramsString = [NSString stringWithFormat:@"msg=%@", self.chatWindow.messageTextField.stringValue];
    [request setHTTPBody:[paramsString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"http://inmac.org/login.php?redirect=/" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    [request setTimeoutInterval:10];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [conn start];
    self.chatWindow.messageTextField.stringValue = @"";
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"sent_message" ofType:@"aiff"];
    NSSound *systemSound = [[NSSound alloc] initWithContentsOfFile:resourcePath byReference:YES];
    if(systemSound && [[AppDelegate getObject:kInMacPlaySoundOutcomingMessage] boolValue])
        [systemSound play];
}

- (void)didDeleteMessageRequestFromRow:(NSInteger)row
{
    EntityMessages *message = [self.messages objectAtIndex:row];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://inmac.org/json/chat/"]];
    NSString *paramsString = [NSString stringWithFormat:@"mode=delete&p=%@", message.ident];
    [request setHTTPBody:[paramsString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"http://inmac.org/login.php?redirect=/" forHTTPHeaderField:@"Referer"];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    [request setTimeoutInterval:10];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [conn start];
    [self.moc deleteObject:[self.entityMessages getByTime:message.time uid:message.uid moc:self.moc]];
    [self.tempContext save];
    [self loadMessages];
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
        NSString *moderatorMode = [chatAnswer objectForKey:@"modcp"];
        self.moderatorMode = (moderatorMode && [[chatAnswer objectForKey:@"modcp"] boolValue]);
        NSArray *messages = [chatAnswer objectForKey:@"messages"];
        if(messages.count>0)
        {
            for(NSDictionary *message in messages)
            {
                HTMLParser *parser = [[HTMLParser alloc] initWithString:[message objectForKey:@"user"] error:nil];
                HTMLNode *userBodyNode = [parser doc];
                HTMLNode *userSpanNode = [userBodyNode findChildTag:@"span"];
                NSString *userClass = [userSpanNode getAttributeNamed:@"class"];
                [self.entityMessages addOrUpdate:[message objectForKey:@"id"]
                                             uid:[message objectForKey:@"uid"]
                                            text:[message objectForKey:@"text"]
                                            user:[message objectForKey:@"user"]
                                          avatar:[message objectForKey:@"avatar"]
                                            time:[NSDecimalNumber decimalNumberWithString:[message objectForKey:@"time"]]
                                              my:[NSNumber numberWithInt:[[message objectForKey:@"my"] intValue]]
                                       userClass:(userClass)?userClass:@""
                                             moc:self.moc];
            }
            [self loadMessages];
            [self.tempContext save];
            [self showUserNotification:messages];
            [self playNewIncomingMessageSound];
            [self didRecalculateBage:messages];
            self.lastMessageID = [[messages objectAtIndex:0] objectForKey:@"id"];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            sleep([[AppDelegate getObject:kInMacChatUpdateSeconds] floatValue]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didGetNewMessagesRequest];
            });
        });
    }/*
    else
        NSLog(@"chat messages error: %@ responseData: %@", [error localizedDescription], [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
      */
}

-(void)loadMessages
{
    if(!self.entityMessages)
        self.entityMessages = [[EntityMessages alloc] init];
    if(!self.tempContext)
        self.tempContext = [[TempContext alloc] init];
    if(!self.moc)
        self.moc = [self.tempContext get];
    self.messages = [[self.entityMessages getAll:self.moc] copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"newMessages" object:nil];
}

-(void)showUserNotification:(NSArray*)messages
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    self.notification = [[NSUserNotification alloc] init];
    if(messages.count==1)
    {
        self.notification.title = @"Новое сообщение";
        NSDictionary *message = [messages objectAtIndex:0];
        NSString *user = [[message objectForKey:@"user"] stringByStrippingHTML];
        NSString *text = [[message objectForKey:@"text"] stringByStrippingHTML];
        self.notification.informativeText = [NSString stringWithFormat:@"%@: %@", user, text];
    }
    else
    {
        self.notification.title = @"Новые сообщения";
        NSMutableString *from = [[NSMutableString alloc] init];
        NSMutableDictionary *users = [[NSMutableDictionary alloc] init];
        for(NSDictionary *message in messages)
            [users setObject:@"" forKey:[[message objectForKey:@"user"] stringByStrippingHTML]];
        for(int i=0;i<users.allKeys.count;i++)
            [from appendFormat:(i<users.allKeys.count-1)?@"%@, ":@"%@", [users.allKeys objectAtIndex:i]];
        self.notification.informativeText = [NSString stringWithFormat:@"от %@", from];
    }
    if([[AppDelegate getObject:kInMacShowNotifications] boolValue])
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:self.notification];
}

-(void)playNewIncomingMessageSound
{
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"new_message" ofType:@"aiff"];
    NSSound *systemSound = [[NSSound alloc] initWithContentsOfFile:resourcePath byReference:YES];
    if(systemSound && [[AppDelegate getObject:kInMacPlaySoundIncomingMessage] boolValue] && ![[NSApplication sharedApplication] isActive])
        [systemSound play];
}

-(void)didRecalculateBage:(NSArray*)messages
{
    if(![[NSApplication sharedApplication] isActive] && [[AppDelegate getObject:kInMacCountUnreadInDock] boolValue])
    {
        self.unreadedMessages += messages.count;
        NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
        [tile setBadgeLabel:[NSString stringWithFormat:@"%li", self.unreadedMessages]];
    }
}

-(void)removeOldMessages
{
    [self.entityMessages removeOldMessages:self.moc];
    [self.tempContext save];
    [self loadMessages];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [self didGetNewMessagesRequest];
}

#pragma mark - ChatWindow Delegate
- (void)windowDidResize:(NSNotification *)notification
{
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"newMessages" object:nil];
}

#pragma mark - SettingsWindow Delegate
- (IBAction)changeShowNotifications:(NSButton*)sender
{
    if(sender.state==0)
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    [AppDelegate saveObject:[NSNumber numberWithInteger:sender.state] forKey:kInMacShowNotifications];
}

- (IBAction)changeCountUnreadInDock:(NSButton*)sender
{
    if(sender.state==0)
        [AppDelegate resetDockBage];
    [AppDelegate saveObject:[NSNumber numberWithInteger:sender.state] forKey:kInMacCountUnreadInDock];
}

- (IBAction)changePlaySoundIncomingMessage:(NSButton*)sender
{
    [AppDelegate saveObject:[NSNumber numberWithInteger:sender.state] forKey:kInMacPlaySoundIncomingMessage];
}

- (IBAction)changePlaySoundOutcomingMessage:(NSButton*)sender
{
    [AppDelegate saveObject:[NSNumber numberWithInteger:sender.state] forKey:kInMacPlaySoundOutcomingMessage];
}

- (IBAction)changeRemoveOldMessages:(NSButton*)sender
{
    [AppDelegate saveObject:[NSNumber numberWithInteger:sender.state] forKey:kInMacRemoveOldMessages];
}

- (IBAction)changePlayRadioOnStart:(NSButton*)sender
{
    [AppDelegate saveObject:[NSNumber numberWithInteger:sender.state] forKey:kInMacPlayRadioOnStart];
    if(sender.state)
        [self removeOldMessages];
}

- (IBAction)changeChatUpdateSeconds:(NSStepper*)sender
{
    [AppDelegate saveObject:[NSNumber numberWithInt:sender.intValue] forKey:kInMacChatUpdateSeconds];
    self.chatUpdateSecondsTextField.stringValue = [NSString stringWithFormat:@"%i", sender.intValue];
}

- (IBAction)changeAlwaysOnTop:(NSMenuItem*)sender
{
    sender.state = (sender.state==1)?0:1;
    [[[Chat shared] chatWindow] setLevel:(sender.state==1)?5:0];
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
        NSNumber *countUnreadInDock = [AppDelegate getObject:kInMacCountUnreadInDock];
        [self.countUnreadInDockButton setState:[countUnreadInDock boolValue]];
        NSNumber *playSoundIncomingMessage = [AppDelegate getObject:kInMacPlaySoundIncomingMessage];
        [self.playSoundIncomingMessageButton setState:[playSoundIncomingMessage boolValue]];
        NSNumber *playSoundOutcomingMessage = [AppDelegate getObject:kInMacPlaySoundOutcomingMessage];
        [self.playSoundOutcomingMessageButton setState:[playSoundOutcomingMessage boolValue]];
        NSNumber *removeOldMessages = [AppDelegate getObject:kInMacRemoveOldMessages];
        [self.removeOldMessagesButton setState:[removeOldMessages boolValue]];
        NSNumber *playRadioOnStart = [AppDelegate getObject:kInMacPlayRadioOnStart];
        [self.playRadioOnStartButton setState:[playRadioOnStart boolValue]];
        NSNumber *chatUpdateSeconds = [AppDelegate getObject:kInMacChatUpdateSeconds];
        self.chatUpdateSecondsTextField.stringValue = [NSString stringWithFormat:@"%.0f", [chatUpdateSeconds floatValue]];
        [self.chatUpdateSecondsStepper setIntValue:[chatUpdateSeconds intValue]];
    }
}

@end
