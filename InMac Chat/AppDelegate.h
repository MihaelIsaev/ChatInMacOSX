//
//  AppDelegate.h
//  InMac Chat
//
//  Created by mihael on 14.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kInMacShowNotifications @"showNotifications"
#define kInMacChatUpdateSeconds @"chatUpdateSeconds"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

+(id)getObject:(NSString*)key;
+(void)saveObject:(id)value forKey:(NSString*)key;

@end
