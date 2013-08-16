//
//  TempContext.h
//
//  Created by mihael on 06.01.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"

@interface TempContext : NSObject

-(NSManagedObjectContext*)get;
-(void)save;

@end
