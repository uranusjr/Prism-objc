//
//  PrismTests.m
//  PrismTests
//
//  Created by Tzu-ping Chung on 29/12.
//  Copyright (c) 2014 uranusjr. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PRIPlugIn.h"
#import "PRISyntaxHighlighter.h"

@interface PrismTests : XCTestCase

@property (strong) PRISyntaxHighlighter *highlighter;

@end


@implementation PrismTests

- (void)setUp
{
    [super setUp];
    self.highlighter = [[PRISyntaxHighlighter alloc] init];
}

- (void)tearDown
{
    self.highlighter = nil;
    [super tearDown];
}

- (void)testHighlight
{
    NSError *error;
    NSString *output = [self.highlighter highlight:@"int main" asLanguage:@"c"
                                             error:&error];
    XCTAssertNotEqualObjects(@"<span class=\"token keyword\">int</span> main",
                             output);
    XCTAssertNil(error);
}

- (void)testBuiltInPlugIns
{
    NSDictionary *plugins = [PRISyntaxHighlighter builtInPlugIns];
    for (PRIPlugIn *plugin in plugins.allValues)
    {
        XCTAssertNotNil(plugin.name);
        XCTAssertNotNil(plugin.javaScript);
        XCTAssertNotNil(plugin.CSS);
    }
}

@end
