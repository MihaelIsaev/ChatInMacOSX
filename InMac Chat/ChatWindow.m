//
//  ChatWindow.m
//  InMac Chat
//
//  Created by mihael on 15.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "ChatWindow.h"
#import "Chat.h"
#import "ChatMessageCell.h"
#import "NSString+Magic.h"
#import "NSString+HTML.h"
#import "AppDelegate.h"
#import "HTMLParser.h"

@implementation ChatWindow

-(id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:@"newMessages" object:nil];
    return [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
}

-(void)reloadData
{
    [self.messagesTable reloadData];
}

-(NSAttributedString*)attributedMessageTextForRow:(NSInteger)row
{
    NSDictionary *message = [[[Chat shared] messages] objectAtIndex:row];
    HTMLParser *parser = [[HTMLParser alloc] initWithString:[message objectForKey:@"text"] error:nil];
    HTMLNode *textBodyNode = [parser doc];
    NSString *text = [[message objectForKey:@"text"] stringByConvertingHTMLToPlainText];
    NSString *user = [[NSString stringWithFormat:@"%@:", [message objectForKey:@"user"]] stringByStrippingHTML];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    [attributedString appendAttributedString: [[NSAttributedString alloc] initWithString:user]];
    [attributedString appendAttributedString: [[NSAttributedString alloc] initWithString:@"  "]];
    [attributedString appendAttributedString: [[NSAttributedString alloc] initWithString:text]];
    [attributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Verdana-Bold" size:12.0f] range:[attributedString.string rangeOfString:user]];
    [attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:[attributedString.string rangeOfString:user]];
    [attributedString addAttribute:NSLinkAttributeName
                             value:[NSString stringWithFormat:@"inmac://clickOnUser~%@", [[message objectForKey:@"user"] stringByStrippingHTML]]
                             range:[attributedString.string rangeOfString:user]];
    [attributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Verdana" size:12.0f] range:[attributedString.string rangeOfString:text]];
    for(HTMLNode *aTextNode in [textBodyNode findChildTags:@"a"])
    {
        [attributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Verdana" size:11.0f] range:[attributedString.string rangeOfString:[aTextNode contents]]];
        [attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:[attributedString.string rangeOfString:[aTextNode contents]]];
        [attributedString addAttribute:NSLinkAttributeName
                                 value:[NSString stringWithFormat:@"inmac://openURL~%@", [aTextNode getAttributeNamed:@"href"]]
                                 range:[attributedString.string rangeOfString:[aTextNode contents]]];
    }
    
    return attributedString;
}

#pragma mark - Mesasges TableView Delegate
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[[Chat shared] messages] count];
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSAttributedString *attributedString = [self attributedMessageTextForRow:row];
    NSTableColumn *tableColoumn = [self.messagesTable tableColumnWithIdentifier:@"MessageColumn"];
    NSRect stringRect = [attributedString boundingRectWithSize:CGSizeMake([tableColoumn width], CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading];
    CGFloat heightOfRow = stringRect.size.height+10.0f;
    return (heightOfRow<46.0f)?50.0f:heightOfRow;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    ChatMessageCell *cellView = [tableView makeViewWithIdentifier:@"MessageCell" owner:self];
    NSDictionary *message = [[[Chat shared] messages] objectAtIndex:row];
    HTMLParser *parser = [[HTMLParser alloc] initWithString:[message objectForKey:@"user"] error:nil];
    HTMLNode *userBodyNode = [parser doc];
    HTMLNode *userSpanNode = [userBodyNode findChildTag:@"span"];
    NSString *userClass = [userSpanNode getAttributeNamed:@"class"];
    NSString *userHexColor = @"000000";
    if([userClass contains:@"colorAdmin"])
        userHexColor = @"F80000";
    else if([userClass contains:@"colorMod"])
        userHexColor = @"008000";
    else if([userClass contains:@"colorGroup"])
        userHexColor = @"CC6633";
    else if([userClass contains:@"colorCPH"])
        userHexColor = @"0080FF";
    //аватар
    NSString *avatarLink = [message objectForKey:@"avatar"];
    NSString *imageURLString = [NSString stringWithFormat:@"http://static.inmac.org/avatars/%@", (avatarLink.length>0)?avatarLink:@"guest.png"];
    if(![AppDelegate getObject:imageURLString])
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSURL *imageURL = [NSURL URLWithString:imageURLString];
            [AppDelegate saveObject:[NSData dataWithContentsOfURL:imageURL] forKey:imageURLString];
            dispatch_async(dispatch_get_main_queue(), ^{
                cellView.avatarButton.image = [[NSImage alloc] initWithData:[AppDelegate getObject:imageURLString]];
            });
        });
    else
        cellView.avatarButton.image = [[NSImage alloc] initWithData:[AppDelegate getObject:imageURLString]];
    [cellView setDate:[message objectForKey:@"time"]];
    if(!cellView.textViewTemp)
    {
        cellView.textViewTemp = cellView.textView;
        [cellView.textViewTemp setLinkTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      [AppDelegate colorWithHexColorString:userHexColor], NSForegroundColorAttributeName,
                                                      [AppDelegate colorWithHexColorString:userHexColor], NSStrokeColorAttributeName,
                                                      [NSCursor pointingHandCursor], NSCursorAttributeName,
                                                      nil] ];
        [cellView.textViewTemp setFrame:cellView.scrollView.frame];
        [cellView addSubview:cellView.textViewTemp];
        [cellView.scrollView removeFromSuperview];
    }
    [cellView.textViewTemp.textStorage setAttributedString:[self attributedMessageTextForRow:row]];
    [cellView.removeButton setHidden:![[message objectForKey:@"my"] boolValue]];
    [cellView.avatarButton setAction:@selector(openUserProfile:)];
    return cellView;
}

-(void)openUserProfile:(NSButton*)sender
{
    NSInteger row = [self.messagesTable rowForView:sender.superview];
    NSDictionary *message = [[[Chat shared] messages] objectAtIndex:row];
    NSString *messageUID = [message objectForKey:@"uid"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://inmac.org/profile.php?mode=viewprofile&u=%@", messageUID]]];
}

- (IBAction)removeMessage:(NSButton*)sender
{
    [[Chat shared] didDeleteMessageRequestFromRow:[self.messagesTable rowForView:sender.superview]];
}

@end
