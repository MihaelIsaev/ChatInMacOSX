#import <CommonCrypto/CommonDigest.h>

@interface NSString (reverse)

-(NSString*)stringByStrippingHTML;
-(NSString*)replace:(NSString*)what to:(NSString*)to;
-(NSString*)trim;
-(id)json;

@end