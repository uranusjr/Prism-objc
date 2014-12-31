//
//  PRISyntaxHighlighter.h
//  Prism
//
//  Created by Tzu-ping Chung on 29/12.
//  Copyright (c) 2014 uranusjr. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>


@interface PRISyntaxHighlighter : NSObject <NSCopying>

+ (NSDictionary *)defaultAliases;

// Designated initializer.
- (instancetype)initWithDefaultAliases:(BOOL)loadDefaultAliases;

- (instancetype)init;
- (void)dealloc;

@property (copy, readonly) NSDictionary *languages;
@property (copy, readonly) NSDictionary *themes;
@property (copy, readonly) NSDictionary *aliases;

- (void)addAlias:(NSString *)alias forName:(NSString *)target;
- (void)addAliasesFromDictionary:(NSDictionary *)aliases;
- (void)removeAlias:(NSString *)alias;

- (NSString *)resolve:(NSString *)aliasOrName;
- (NSString *)highlight:(NSString *)input asLanguage:(NSString *)lang
                  error:(NSError *__autoreleasing *)error;

@end
