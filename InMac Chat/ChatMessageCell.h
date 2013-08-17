//
//  ChatMessageCell.h
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface ChatMessageCell : NSTableCellView

@property (unsafe_unretained) NSTextView *textViewTemp;
@property (unsafe_unretained) IBOutlet NSScrollView *scrollView;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak, nonatomic) IBOutlet NSTextField *time;
@property (weak, nonatomic) IBOutlet NSButton *removeButton;
@property (weak, nonatomic) IBOutlet NSImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet NSButton *avatarButton;

-(void)setDate:(NSString*)date;

@end
