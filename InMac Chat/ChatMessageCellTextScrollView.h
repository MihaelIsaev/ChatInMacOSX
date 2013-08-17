//
//  ChatMessageCellTextScrollView.h
//  InMac Chat
//
//  Created by mihael on 17.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ChatMessageCellTextScrollView : NSScrollView

- (id)initWithFrame:(NSRect)frameRect; // in case you generate the scroll view manually
- (void)awakeFromNib; // in case you generate the scroll view via IB
- (void)hideScrollers; // programmatically hide the scrollers, so it works all the time
- (void)scrollWheel:(NSEvent *)theEvent; // disable scrolling

@end
