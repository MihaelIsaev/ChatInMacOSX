//
//  TempContext.m
//
//  Created by mihael on 06.01.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "TempContext.h"

@implementation TempContext

NSManagedObjectContext *moc;

-(id)init
{
    moc = nil;
    return self;
}

-(NSManagedObjectContext*)get
{
    if(!moc)
    {
        moc = [[NSManagedObjectContext alloc] init];
        [moc setRetainsRegisteredObjects:YES];
        [moc setPersistentStoreCoordinator:[[AppDelegate sharedInstance] persistentStoreCoordinator]];
    }
    return moc;
}

-(void)save
{
    NSError *error = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tempContextSaved:) name:NSManagedObjectContextDidSaveNotification object:moc];
    });
    [moc save:&error];
    if (error)
        NSLog(@"tempContext save error: %@", [error localizedDescription]);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:moc];
    });
}

-(void)tempContextSaved:(NSNotification *)notification
{
    if([AppDelegate sharedInstance])
        [[[AppDelegate sharedInstance] managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
}

@end
