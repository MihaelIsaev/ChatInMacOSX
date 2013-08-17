//
//  NSAttributedString+Magic.m
//  InMac Chat
//
//  Created by mihael on 17.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "NSAttributedString+Magic.h"

@implementation NSMutableAttributedString (SmileyAdditions)

- (void)replaceSmilies
{
    static NSDictionary *smilies = nil;
    
    if (smilies == nil) {
        smilies = [[NSDictionary alloc] initWithObjectsAndKeys:
                   @"mail.gif", @":mail:",
                   @"lock.gif", @":lock:)",
                   @"likeff.gif", @":likeff:",
                   @"lamo.gif", @":lamo:",
                   @"kiss3.gif", @":kiss3:",
                   @"kiss.gif", @":kiss:",
                   @"jumper.gif", @":jumper:",
                   @"ireful.gif", @":ireful:",
                   @"in_love2.gif", @":in_love2:",
                   @"icon_yawn.gif", @":icon_yawn:",
                   @"icon_wink.gif", @":icon_wink:",
                   @"icon_weep.gif", @":icon_weep:",
                   @"icon_weep.gif", @":'(",
                   @"icon_wall.gif", @":icon_wall:",
                   @"icon_twisted.gif", @":icon_twisted:",
                   @"icon_surprised.gif", @":icon_surprised:",
                   @"icon_smile.gif", @":icon_smile:",
                   @"icon_smile.gif", @":)",
                   @"icon_smile.gif", @":-)",
                   @"icon_sick.gif", @":icon_sick:",
                   @"icon_sad.gif", @":icon_sad:",
                   @"icon_sad.gif", @":(",
                   @"icon_sad.gif", @":-(",
                   @"icon_rolleys.gif", @":icon_rolleys:",
                   @"icon_redface.gif", @":icon_redface:",
                   @"icon_razz.gif", @":icon_razz:",
                   @"icon_rant.gif", @":icon_rant:",
                   @"icon_question.gif", @":icon_question:",
                   @"icon_neutral.gif", @":icon_neutral:",
                   @"icon_mrgreen.gif", @":icon_mrgreen:",
                   @"icon_mad.gif", @":icon_mad:",
                   @"icon_lol.gif", @":icon_lol:",
                   @"icon_lol.gif", @":D",
                   @"icon_lol.gif", @":-D",
                   @"icon_in_love.gif", @":icon_in_love:",
                   nil];
    }
    
    BOOL found;
    do {
        found = NO;
        NSEnumerator *e = [smilies keyEnumerator];
        NSString *smiley;
        while ((smiley = [e nextObject])) {
            NSRange smileyRange = [[self mutableString] rangeOfString:smiley];
            if (smileyRange.location != NSNotFound) {
                NSString *filename = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[smilies objectForKey:smiley]];
                NSFileWrapper *myFileWrapper = [[NSFileWrapper alloc] initWithPath:filename];
                NSTextAttachment *myTextAtt = [[NSTextAttachment alloc] initWithFileWrapper:myFileWrapper];
                NSAttributedString *myAttStr = [NSAttributedString attributedStringWithAttachment:myTextAtt];
                
                [self replaceCharactersInRange:smileyRange withAttributedString:myAttStr];
                found = YES;
            }
        }
    } while (found);
}

@end
