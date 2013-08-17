//
//  News.m
//  InMac Chat
//
//  Created by mihael on 17.08.13.
//  Copyright (c) 2013 Mihael Isaev. All rights reserved.
//

#import "News.h"
#import "NewsTableCell.h"
#import "HTMLParser.h"
#import "NSString+Magic.h"

#define kParentTitle @"parentTitle"
#define kParentLink @"parentLink"
#define kNewsTitle @"newsTitle"
#define kNewsLink @"newsLink"
#define kAuthorTitle @"authorTitle"
#define kAuthorLink @"authorLink"
#define kAnswers @"answers"

@implementation News

-(id)init
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getNews) name:@"refreshNews" object:nil];
    return [super init];
}

-(void)getNews
{
    [self.progressBar startAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://inmac.org/search.php?lsp=1"];
        NSData *responseData = [NSData data];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setCachePolicy:NSURLRequestReloadRevalidatingCacheData];
        [request setTimeoutInterval:10];
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSString *html = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        html = [html replace:@"<meta charset=\"utf-8\">" to:@"<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">"];
        HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];
        if(!error)
        {
            NSMutableArray *newsArray = [[NSMutableArray alloc] init];
            HTMLNode *bodyNode = [parser doc];
            HTMLNode *forumsTable = [bodyNode findChildOfClass:@"forumline forum"];
            for(HTMLNode *trNode in [forumsTable findChildTags:@"tr"])
            {
                if([[trNode getAttributeNamed:@"class"] isEqualToString:@"tCenter"])
                {
                    NSMutableDictionary *newsDict = [[NSMutableDictionary alloc] init];
                    HTMLNode *topicNode = [trNode findChildOfClass:@"topictitle"];
                    HTMLNode *topicANode = [topicNode findChildOfClass:@"topictitle"];
                    [newsDict setObject:[NSString stringWithFormat:@"http://inmac.org/%@", [topicANode getAttributeNamed:@"href"]] forKey:kNewsLink];
                    [newsDict setObject:[topicANode allContents] forKey:kNewsTitle];
                    HTMLNode *parentNode = [trNode findChildOfClass:@"gen f"];
                    [newsDict setObject:[NSString stringWithFormat:@"http://inmac.org/%@", [parentNode getAttributeNamed:@"href"]] forKey:kParentLink];
                    [newsDict setObject:[parentNode allContents] forKey:kParentTitle];
                    HTMLNode *authorNode = [trNode findChildOfClass:@"med"];
                    HTMLNode *authorANode = [authorNode findChildTag:@"a"];
                    [newsDict setObject:[[authorANode getAttributeNamed:@"href"] replace:@"./" to:@"http://inmac.org/"] forKey:kAuthorLink];
                    [newsDict setObject:[authorANode allContents] forKey:kAuthorTitle];
                    HTMLNode *answersNode = [trNode findChildOfClass:@"small"];
                    [newsDict setObject:[answersNode allContents] forKey:kAnswers];
                    [newsArray addObject:newsDict];
                }
            }
            self.news = [newsArray copy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else
            NSLog(@"parse error: %@", [error localizedDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressBar stopAnimation:self];
        });
    });
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
    NSRange visibleRows = [self.tableView rowsInRect:self.scrollView.contentView.bounds];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [self.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:visibleRows]];
    [NSAnimationContext endGrouping];
}

#pragma mark - Mesasges TableView Delegate
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.news.count;
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 40.0f;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NewsTableCell *cellView = [tableView makeViewWithIdentifier:@"NewsCell" owner:self];
    NSDictionary *news = [self.news objectAtIndex:row];
    [cellView.topicButton setTitle:[news objectForKey:kNewsTitle]];
    [cellView.topicButton setIdentifier:[news objectForKey:kNewsLink]];
    [cellView.parentButton setTitle:[news objectForKey:kParentTitle]];
    [cellView.parentButton setIdentifier:[news objectForKey:kParentLink]];
    [cellView.authorButton setTitle:[news objectForKey:kAuthorTitle]];
    [cellView.authorButton setIdentifier:[news objectForKey:kAuthorLink]];
    return cellView;
}

- (IBAction)clickButton:(NSButton*)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:sender.identifier]];
}

@end
