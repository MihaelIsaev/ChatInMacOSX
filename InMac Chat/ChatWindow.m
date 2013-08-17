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
#import "NSAttributedString+Magic.h"
#import "NSString+Magic.h"
#import "NSString+HTML.h"
#import "AppDelegate.h"
#import "HTMLParser.h"
#import "EntityMessages.h"

@implementation ChatWindow

-(id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:@"newMessages" object:nil];
    return [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
    NSRange visibleRows = [self.messagesTable rowsInRect:[[Chat shared] chatScrollView].contentView.bounds];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [self.messagesTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:visibleRows]];
    [NSAnimationContext endGrouping];
}

-(void)reloadData
{
    [self.messagesTable reloadData];
    if ([self.messagesTable numberOfRows] > 0)
        [self.messagesTable scrollRowToVisible:[self.messagesTable numberOfRows] - 1];
}

-(NSAttributedString*)attributedMessageTextForRow:(NSInteger)row
{
    EntityMessages *message = [[[Chat shared] messages] objectAtIndex:row];
    HTMLParser *parserTextBeforeSmiles = [[HTMLParser alloc] initWithString:[NSString stringWithFormat:@"<html><head><meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"></head><body>%@</body></html>", message.text] error:nil];
    HTMLNode *docTextBeforeSmiles = [parserTextBeforeSmiles doc];
    NSString *rawText = [docTextBeforeSmiles rawContents];

    for(HTMLNode *imgNode in [docTextBeforeSmiles findChildTags:@"img"])
        if([[imgNode getAttributeNamed:@"class"] isEqualToString:@"smile"])
        {
            NSString *smileName = [[[imgNode getAttributeNamed:@"src"] replace:@"http://static.inmac.org/smiles/" to:@""] replace:@".gif" to:@""];
            rawText = [rawText replace:[imgNode rawContents] to:[NSString stringWithFormat:@":%@:", smileName]];
        }
    
    HTMLParser *parserUser = [[HTMLParser alloc] initWithString:[NSString stringWithFormat:@"<html><head><meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"></head><body>%@</body></html>", message.user] error:nil];
    HTMLParser *parserText = [[HTMLParser alloc] initWithString:rawText error:nil];
    HTMLNode *userBodyNode = [parserUser doc];
    HTMLNode *textBodyNode = [parserText doc];
    NSString *text = [[textBodyNode allContents] trim];
    NSString *user = [NSString stringWithFormat:@"%@:", [userBodyNode allContents]];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    [attributedString appendAttributedString: [[NSAttributedString alloc] initWithString:user]];
    [attributedString appendAttributedString: [[NSAttributedString alloc] initWithString:@"  "]];
    [attributedString appendAttributedString: [[NSAttributedString alloc] initWithString:text]];
    [attributedString replaceSmilies];
    
    [attributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Verdana-Bold" size:12.0f] range:[attributedString.string rangeOfString:user]];
    //[attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:[attributedString.string rangeOfString:user]];
    [attributedString addAttribute:NSLinkAttributeName
                             value:[NSString stringWithFormat:@"inmac://clickOnUser~%@", user]
                             range:[attributedString.string rangeOfString:user]];
    [attributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Verdana" size:12.0f] range:[attributedString.string rangeOfString:text]];
    for(HTMLNode *aTextNode in [textBodyNode findChildTags:@"a"])
    {
        [attributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Verdana" size:11.0f] range:[attributedString.string rangeOfString:[aTextNode contents]]];
        [attributedString addAttribute:NSLinkAttributeName
                                 value:[NSString stringWithFormat:@"inmac://openURL~%@", [aTextNode getAttributeNamed:@"href"]]
                                 range:[attributedString.string rangeOfString:[aTextNode allContents]]];
    }
    for(HTMLNode *bTextNode in [textBodyNode findChildrenOfClass:@"post-b"])
    {
        [attributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Verdana-Bold" size:11.0f] range:[attributedString.string rangeOfString:[bTextNode allContents]]];
        /*[attributedString addAttribute:NSLinkAttributeName
                                 value:[NSString stringWithFormat:@"inmac://clickOnUser~%@", [bTextNode allContents]]
                                 range:[attributedString.string rangeOfString:[bTextNode allContents]]];*/
    }
    //NSLog(@"text: %@", attributedString.string);
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
    NSRect stringRect = [attributedString boundingRectWithSize:CGSizeMake([tableColoumn width]-139, CGFLOAT_MAX)
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
    EntityMessages *message = [[[Chat shared] messages] objectAtIndex:row];
    //аватар
    if(message.avatar.length>0)
    {
        NSString *imageURLString = [NSString stringWithFormat:@"http://static.inmac.org/avatars/%@", message.avatar];
        if(![AppDelegate getObject:imageURLString])
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSURL *imageURL = [NSURL URLWithString:imageURLString];
                [AppDelegate saveObject:[NSData dataWithContentsOfURL:imageURL] forKey:imageURLString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    cellView.avatarImageView.image = [[NSImage alloc] initWithData:[AppDelegate getObject:imageURLString]];
                });
            });
        else
            cellView.avatarImageView.image = [[NSImage alloc] initWithData:[AppDelegate getObject:imageURLString]];
    }
    else
        cellView.avatarImageView.image = [NSImage imageNamed:@"no-avatar"];
    [cellView setDate:message.time.stringValue];
    [cellView.textView.textStorage setAttributedString:[self attributedMessageTextForRow:row]];
    [cellView.textView setLinkTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  [self userColorByClass:message.userClass], NSForegroundColorAttributeName,
                                                  [self userColorByClass:message.userClass], NSStrokeColorAttributeName,
                                                  [NSCursor pointingHandCursor], NSCursorAttributeName,
                                                  nil] ];
    [cellView.removeButton setHidden:!(message.my.boolValue || [[Chat shared] moderatorMode])];
    [cellView.avatarButton setAction:@selector(openUserProfile:)];
    return cellView;
}

-(void)openUserProfile:(NSButton*)sender
{
    NSInteger row = [self.messagesTable rowForView:sender.superview];
    EntityMessages *message = [[[Chat shared] messages] objectAtIndex:row];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://inmac.org/profile.php?mode=viewprofile&u=%@", message.uid]]];
}

- (IBAction)showSmiles:(id)sender
{
    if([self.smilesPopover isShown])
        [self.smilesPopover close];
    else
        [self.smilesPopover showRelativeToRect:self.smilesButton.bounds ofView:self.smilesButton preferredEdge:NSMaxYEdge];
}

- (IBAction)removeMessage:(NSButton*)sender
{
    [[Chat shared] didDeleteMessageRequestFromRow:[self.messagesTable rowForView:sender.superview]];
}

- (IBAction)clickSmile:(NSButton*)sender
{
    self.messageTextField.stringValue = [NSString stringWithFormat:@"%@ :%@: ", self.messageTextField.stringValue, sender.identifier];
    [self.messageTextField becomeFirstResponder];
    [[self.messageTextField currentEditor] moveToEndOfLine:nil];
}

-(NSColor*)userColorByClass:(NSString*)userClass
{
    NSString *userHexColor = @"1E7676";
    if([userClass contains:@"colorAdmin"])
        userHexColor = @"F80000";
    else if([userClass contains:@"colorMod"])
        userHexColor = @"008000";
    else if([userClass contains:@"colorGroup"])
        userHexColor = @"CC6633";
    else if([userClass contains:@"colorCPH"])
        userHexColor = @"0080FF";
    return [AppDelegate colorWithHexColorString:userHexColor];
}

#pragma mark - NSTextField Delegate
-(void)controlTextDidEndEditing:(NSNotification *)notification
{
    if([[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
    {
        [[Chat shared] didSendMessageRequest];
    }
}

- (IBAction)changeView:(NSSegmentedControl*)sender
{
    [self.chatView setHidden:(sender.selectedSegment!=0)];
    [self.newsView setHidden:(sender.selectedSegment!=1)];
    [self.radioView setHidden:(sender.selectedSegment!=2)];
    if(sender.selectedSegment==1)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshNews" object:nil];
}

@end
