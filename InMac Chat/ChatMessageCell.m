//
//  ChatMessageCell.m
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "ChatMessageCell.h"

@implementation ChatMessageCell

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

-(void)setDate:(NSString*)date
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm:ss"];
    self.time.stringValue = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:[date integerValue]]];
}

@end
