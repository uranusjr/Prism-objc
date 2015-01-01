//
//  PRIPlugIn.m
//  Prism
//
//  Created by Tzu-ping Chung on 31/12.
//  Copyright (c) 2014 uranusjr. All rights reserved.
//

#import "PRIPlugIn.h"

@implementation PRIPlugIn

- (instancetype)initWithName:(NSString *)name javaScript:(NSURL *)js
                         CSS:(NSURL *)css
{
    self = [super init];
    if (!self)
        return nil;

    self.name = name;
    self.javaScript = js;
    self.CSS = css;

    return self;
}

- (instancetype)init
{
    return [self initWithName:@"" javaScript:nil CSS:nil];
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (![object isKindOfClass:[PRIPlugIn class]])
        return NO;
    return [self isEqualToPlugIn:object];
}

- (NSUInteger)hash
{
    return self.name.hash ^ self.javaScript.hash ^ self.CSS.hash;
}

- (BOOL)isEqualToPlugIn:(PRIPlugIn *)other
{
    if (self == other)
        return YES;
    if (![self.name isEqualToString:other.name])
        return NO;
    if (![self.javaScript isEqual:other.javaScript])
        return NO;
    if (![self.CSS isEqual:other.CSS])
        return NO;
    return YES;
}

@end
