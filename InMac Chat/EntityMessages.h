//
//  EntityMessages.h
//  InMac Chat
//
//  Created by mihael on 16.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EntityMessages : NSManagedObject

@property (nonatomic, retain) NSString * avatar;
@property (nonatomic, retain) NSString * ident;
@property (nonatomic, retain) NSNumber * my;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDecimalNumber * time;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * userClass;

-(NSString*)getTableName;
-(void)addOrUpdate:(NSString*)ident
               uid:(NSString*)uid
              text:(NSString*)text
              user:(NSString*)user
            avatar:(NSString*)avatar
              time:(NSDecimalNumber*)time
                my:(NSNumber*)my
         userClass:(NSString*)userClass
               moc:(NSManagedObjectContext*)moc;
-(EntityMessages*)getByTime:(NSDecimalNumber*)time
                        uid:(NSString*)uid
                        moc:(NSManagedObjectContext*)moc;
-(NSArray*)getAll;
-(NSArray*)getAll:(NSManagedObjectContext*)moc;
-(void)removeOldMessages:(NSManagedObjectContext*)moc;

@end
