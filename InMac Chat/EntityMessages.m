//
//  EntityMessages.m
//  InMac Chat
//
//  Created by mihael on 16.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "EntityMessages.h"
#import "AppDelegate.h"

@implementation EntityMessages

@dynamic avatar;
@dynamic ident;
@dynamic my;
@dynamic text;
@dynamic time;
@dynamic uid;
@dynamic user;
@dynamic userClass;

static NSString * const keyAvatar = @"avatar";
static NSString * const keyIdent = @"ident";
static NSString * const keyMy = @"my";
static NSString * const keyText = @"text";
static NSString * const keyTime = @"time";
static NSString * const keyUID = @"uid";
static NSString * const keyUser = @"user";
static NSString * const keyUserClass = @"userClass";

-(id)init
{
    return self;
}

-(NSString*)getTableName
{
    return @"Messages";
}

-(void)addOrUpdate:(NSString*)ident
               uid:(NSString*)uid
              text:(NSString*)text
              user:(NSString*)user
            avatar:(NSString*)avatar
              time:(NSDecimalNumber*)time
                my:(NSNumber*)my
         userClass:(NSString*)userClass
               moc:(NSManagedObjectContext*)moc
{
    EntityMessages *object = [self getByTime:time uid:uid moc:moc];
    if (!object)
        object = [NSEntityDescription insertNewObjectForEntityForName:[self getTableName] inManagedObjectContext:moc];
    object.avatar = avatar;
    object.ident = ident;
    object.my = my;
    object.uid = uid;
    object.text = text;
    object.user = user;
    object.time = time;
    object.userClass = userClass;
}

-(EntityMessages*)getByTime:(NSDecimalNumber*)time
                        uid:(NSString*)uid
                        moc:(NSManagedObjectContext*)moc
{
    static NSString *temp = @"temp";
    @synchronized (temp)
    {
        NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:[self getTableName] inManagedObjectContext:moc];
        [fetch setEntity:entity];
        NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"%K=%@ AND %K=%@", keyTime, time, keyUID, uid];
        [fetch setPredicate:searchFilter];
        return [[moc executeFetchRequest:fetch error:nil] lastObject];
    }
}

-(NSArray*)getAll
{
    return [self getAll:[[AppDelegate sharedInstance] managedObjectContext]];
}

-(NSArray*)getAll:(NSManagedObjectContext*)moc
{
    static NSString *temp = @"temp";
    @synchronized (temp)
    {
        NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:keyTime ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sd];
        [fetch setSortDescriptors:sortDescriptors];
        NSEntityDescription *entity = [NSEntityDescription entityForName:[self getTableName] inManagedObjectContext:moc];
        [fetch setEntity:entity];
        return [moc executeFetchRequest:fetch error:nil];
    }
}

@end
