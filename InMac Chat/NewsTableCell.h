//
//  NewsTableCell.h
//  InMac Chat
//
//  Created by mihael on 17.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NewsTableCell : NSTableCellView

@property (weak, nonatomic) IBOutlet NSButton *topicButton;
@property (weak, nonatomic) IBOutlet NSButton *parentButton;
@property (weak, nonatomic) IBOutlet NSButton *authorButton;

@end
