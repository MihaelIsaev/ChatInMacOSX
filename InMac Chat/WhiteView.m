//
//  WhiteView.m
//  InMac Chat
//
//  Created by mihael on 17.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "WhiteView.h"

@implementation WhiteView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // set any NSColor for filling, say white:
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

@end
