//
//  PRIPlugIn.h
//  Prism
//
//  Created by Tzu-ping Chung on 31/12.
//  Copyright (c) 2014 uranusjr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRIPlugIn : NSObject

// Designated initializer.
- (instancetype)initWithName:(NSString *)name javaScript:(NSURL *)js
                         CSS:(NSURL *)css;


@property (copy) NSString *name;
@property (copy) NSURL *javaScript;
@property (copy) NSURL *CSS;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

- (BOOL)isEqualToPlugIn:(PRIPlugIn *)other;

@end
