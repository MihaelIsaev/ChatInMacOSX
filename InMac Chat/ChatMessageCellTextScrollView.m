//
//  ChatMessageCellTextScrollView.m
//  InMac Chat
//
//  Created by mihael on 17.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "ChatMessageCellTextScrollView.h"
#import "Chat.h"

@implementation ChatMessageCellTextScrollView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
        [self hideScrollers];
    return self;
}

- (void)awakeFromNib
{
    [self hideScrollers];
}

- (void)hideScrollers
{
    [self setHasHorizontalScroller:NO];
    [self setHasVerticalScroller:NO];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    [[[Chat shared] chatScrollView] scrollWheel:theEvent];
}


@end
