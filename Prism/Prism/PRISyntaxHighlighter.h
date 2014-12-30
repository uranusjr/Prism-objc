//
//  PRISyntaxHighlighter.h
//  Prism
//
//  Created by Tzu-ping Chung on 29/12.
//  Copyright (c) 2014 uranusjr. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>

@interface PRISyntaxHighlighter : NSObject

+ (NSDictionary *)defaultAliases;

- (instancetype)init;
- (void)dealloc;

@property (copy, readonly) NSSet *syntaxNames;
@property (copy, readonly) NSDictionary *themes;
@property (copy, readonly) NSDictionary *aliases;

@property (assign, readonly) JSGlobalContextRef context;

- (void)addAlias:(NSString *)alias forName:(NSString *)target;
- (void)addAliases:(NSDictionary *)aliases;
- (void)removeAlias:(NSString *)alias;

- (NSString *)resolve:(NSString *)aliasOrName;
- (NSString *)highlight:(NSString *)input asLanguage:(NSString *)lang
                  error:(NSError *__autoreleasing *)error;

@end
