//
//  NSString+Magic.m
//  ShopKeeper
//
//  Created by mihael on 02.06.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "NSString+Magic.h"
#include <sys/xattr.h>

@implementation NSString (reverse)

-(NSString *) stringByStrippingHTML
{
    NSRange r;
    NSString *s = [self copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

-(NSString*)replace:(NSString*)what to:(NSString*)to
{
    return [self stringByReplacingOccurrencesOfString:what withString:to];
}

-(NSString*)trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+(BOOL)contains:(NSString*)contains
{
    return ([[self copy] rangeOfString:contains].location == NSNotFound) ? NO : YES;
}

-(NSString*)capitalizeFirstLetter
{
    if(self.length==0)
        return self;
    return [self stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                           withString:[[self  substringToIndex:1] capitalizedString]];
}

-(BOOL)isEmailValid
{
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

-(NSString*)reverse
{
    NSMutableString *reversedString = [NSMutableString string];
    NSInteger charIndex = [self length];
    while (charIndex > 0) {
        charIndex--;
        NSRange subStrRange = NSMakeRange(charIndex, 1);
        [reversedString appendString:[self substringWithRange:subStrRange]];
    }
    return reversedString;
}

-(id)json
{
    return [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
}

@end
