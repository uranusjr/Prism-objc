//
//  AppDelegate.h
//  PrismDemo
//
//  Created by Tzu-ping Chung on 30/12.
//  Copyright (c) 2014 uranusjr. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PRISyntaxHighlighter;


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, readonly) NSArray *availableLanguages;
@property (nonatomic, readonly) NSArray *themeNames;

@property (nonatomic, copy) NSString *selectedLanguage;
@property (nonatomic, copy) NSString *selectedTheme;

@end

