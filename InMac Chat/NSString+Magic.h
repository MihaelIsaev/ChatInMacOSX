#import <CommonCrypto/CommonDigest.h>

@interface NSString (reverse)

-(NSString*)stringByStrippingHTML;
-(NSString*)replace:(NSString*)what to:(NSString*)to;
-(NSString*)trim;
-(BOOL)contains:(NSString*)contains;
-(id)json;

@end