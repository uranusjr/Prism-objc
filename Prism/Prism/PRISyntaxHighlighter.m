//
//  PRISyntaxHighlighter.m
//  Prism
//
//  Created by Tzu-ping Chung on 29/12.
//  Copyright (c) 2014 uranusjr. All rights reserved.
//

#import "PRISyntaxHighlighter.h"


NS_INLINE NSURL *PRIGetResourceURL(NSString *name)
{
    NSBundle *bundle = [NSBundle bundleForClass:[PRISyntaxHighlighter class]];
    bundle = [NSBundle bundleWithURL:[bundle URLForResource:@"Prism"
                                              withExtension:@"bundle"]];
    NSURL *URL = [bundle URLForResource:name withExtension:@""];
    return URL;
}

NS_INLINE NSData *PRIDataWithJavaScriptString(JSStringRef jsstr)
{
    if (!jsstr)
        return nil;

    size_t sz = JSStringGetLength(jsstr) + 1;   // NULL terminated.

    char *buffer = (char *)malloc(sz * sizeof(char));
    JSStringGetUTF8CString(jsstr, buffer, sz);
    NSData *data = [[NSData alloc] initWithBytesNoCopy:buffer length:sz - 1
                                          freeWhenDone:YES];
    return data;
}

NS_INLINE NSString *PRIStringWithJavaScriptString(JSStringRef jsstr)
{
    NSData *data = PRIDataWithJavaScriptString(jsstr);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

NS_INLINE id PRIObjectWithJavaScriptValue(JSContextRef ctx, JSValueRef value)
{
    if (!value)
        return nil;

    JSStringRef json = JSValueCreateJSONString(ctx, value, 0, NULL);
    NSData *data = PRIDataWithJavaScriptString(json);
    id object = [NSJSONSerialization JSONObjectWithData:data options:0
                                                  error:NULL];
    JSStringRelease(json);

    return object;
}

NS_INLINE NSString *PRIStringWithJavaScriptValue(JSContextRef ctx, JSValueRef v)
{
    if (!v)
        return nil;
    JSStringRef jsstr = JSValueToStringCopy(ctx, v, NULL);

    NSString *string = PRIStringWithJavaScriptString(jsstr);

    JSStringRelease(jsstr);
    return string;
}

NS_INLINE JSValueRef PRIJSObjectGetProperty(
    JSContextRef ctx, JSObjectRef object, const char *name)
{
    JSStringRef propertyName = JSStringCreateWithUTF8CString(name);
    JSValueRef value = JSObjectGetProperty(ctx, object, propertyName, NULL);
    JSStringRelease(propertyName);

    return value;
}

NS_INLINE void PRIJSObjectSetProperty(
    JSContextRef ctx, JSObjectRef object, const char *name, JSValueRef value)
{
    JSStringRef propertyName = JSStringCreateWithUTF8CString(name);
    JSObjectSetProperty(ctx, object, propertyName, value, 0, NULL);
    JSStringRelease(propertyName);
}

NS_INLINE void PRIJSObjectSetPropertyString(
    JSContextRef ctx, JSObjectRef object, const char *name, NSString *str)
{
    JSStringRef string = NULL;
    if (str)
        string = JSStringCreateWithCFString((__bridge CFStringRef)str);
    PRIJSObjectSetProperty(ctx, object, name, JSValueMakeString(ctx, string));
    if (string)
        JSStringRelease(string);
}


@implementation PRISyntaxHighlighter
{
    NSMutableDictionary *_aliases;
    JSGlobalContextRef _context;
}

@synthesize languages = _languages;
@synthesize themes = _themes;

+ (NSDictionary *)defaultAliases
{
    static NSDictionary *aliasMap = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        aliasMap = @{@"c++": @"cpp",
                     @"coffee": @"coffeescript",
                     @"coffee-script": @"coffeescript",
                     @"cs": @"csharp",
                     @"html": @"markup",
                     @"js": @"javascript",
                     @"json": @"javascript",
                     @"objective-c": @"objectivec",
                     @"obj-c": @"objectivec",
                     @"objc": @"objectivec",
                     @"py": @"python",
                     @"rb": @"ruby",
                     @"sh": @"bash",
                     @"xml": @"markup"};
    });
    return aliasMap;
}

- (instancetype)initWithDefaultAliases:(BOOL)loadDefaultAliases
{
    self = [super init];
    if (!self)
        return nil;

    _aliases = [[NSMutableDictionary alloc] init];
    if (loadDefaultAliases)
        [self addAliasesFromDictionary:[[self class] defaultAliases]];
    _context = JSGlobalContextCreate(NULL);
    [self runFile:PRIGetResourceURL(@"components.js") error:NULL];
    [self initializePrism];

    return self;
}

- (instancetype)init
{
    return [self initWithDefaultAliases:NO];
}

- (void)dealloc
{
    if (_context)
        JSGlobalContextRelease(_context);
    _context = NULL;
}

- (void)addAlias:(NSString *)alias forName:(NSString *)target
{
    _aliases[alias] = target;
}

- (void)addAliasesFromDictionary:(NSDictionary *)aliases
{
    [_aliases addEntriesFromDictionary:aliases];
}

- (void)removeAlias:(NSString *)alias
{
    _aliases[alias] = nil;
}

- (NSString *)resolve:(NSString *)aliasOrName
{
    NSString *name = aliasOrName;
    while (self.aliases[name])
        name = self.aliases[name];
    return name ? name : aliasOrName;
}

- (NSString *)highlight:(NSString *)input asLanguage:(NSString *)lang
                  error:(NSError *__autoreleasing *)error
{
    JSContextRef ctx = _context;
    JSObjectRef globalObject = JSContextGetGlobalObject(ctx);

    // Inject the current language to use.
    PRIJSObjectSetPropertyString(
        ctx, globalObject, "lang", [self resolve:lang]);

    // Inject the current code to highlight.
    PRIJSObjectSetPropertyString(ctx, globalObject, "input", input);

    // Run!
    JSValueRef exc = NULL;
    JSStringRef js = JSStringCreateWithUTF8CString(
        "Prism.highlight(input, Prism.languages[lang]);");
    JSValueRef returnValue = JSEvaluateScript(ctx, js, NULL, NULL, 0, &exc);
    JSStringRelease(js);

    // FAIL.
    if (!returnValue)
    {
        if (error)
        {
            NSDictionary *exception = PRIObjectWithJavaScriptValue(ctx, exc);
            *error = [NSError errorWithDomain:@"JavaScript" code:1
                                     userInfo:exception];
        }
        return nil;
    }

    // Success! Convert to string and report.
    if (error)
        *error = nil;

    NSString *str = PRIStringWithJavaScriptValue(ctx, returnValue);
    return str;
}


#pragma mark - Private

- (void)runFile:(NSURL *)URL error:(NSError *__autoreleasing *)error
{
    NSString *code = [NSString stringWithContentsOfURL:URL
                                              encoding:NSUTF8StringEncoding
                                                 error:error];
    if (!code)
        return;
    if (!code.length)
        return;

    JSStringRef js = JSStringCreateWithCFString((__bridge CFStringRef)code);
    JSEvaluateScript(_context, js, NULL, NULL, 0, NULL);
    JSStringRelease(js);
}

- (void)initializePrism
{
    JSContextRef ctx = _context;
    JSObjectRef globalObject = JSContextGetGlobalObject(ctx);
    JSValueRef value = PRIJSObjectGetProperty(ctx, globalObject, "components");
    NSDictionary *components = PRIObjectWithJavaScriptValue(ctx, value);

    // Load prism-core.
    NSString *corePath = components[@"core"][@"meta"][@"path"];
    [self runFile:PRIGetResourceURL(corePath) error:NULL];

    // Load languages into global context.
    NSDictionary *languages = components[@"languages"];
    NSMutableDictionary *loadedLanguages =
        [NSMutableDictionary dictionaryWithObject:[NSNull null] forKey:@"meta"];
    for (NSString *name in languages)
    {
        [self loadLanguageWithName:name inDictionary:languages
                        dependency:loadedLanguages];
    }
    [loadedLanguages removeObjectForKey:@"meta"];
    _languages = [loadedLanguages copy];

    // Load theme information.
    NSDictionary *themeInfos = components[@"themes"];
    NSMutableDictionary *themes =
        [NSMutableDictionary dictionaryWithCapacity:themeInfos.count];
    NSString *pathMeta = themeInfos[@"meta"][@"path"];
    for (NSString *key in themeInfos)
    {
        NSString *name;
        id themeInfo = themeInfos[key];
        NSString *path = [pathMeta stringByReplacingOccurrencesOfString:@"{id}"
                                                             withString:key];

        // Theme key-name mapping. Example: "prism-funky": "Funky".
        if ([themeInfo isKindOfClass:[NSString class]])
            name = themeInfo;
        // Theme key-info mapping. Example:
        // "prism": {"title": "Default", "option": "default"}
        else if (themeInfo[@"title"])
            name = themeInfo[@"title"];
        // This shouldn't really happen, but if it does we just ignore it.
        else
            continue;

        NSAssert(name.length, @"This should be a valid string");
        NSURL *url = PRIGetResourceURL(path);
        themes[name] = url;
    }
    _themes = [themes copy];
}

- (void)loadLanguageWithName:(NSString *)name inDictionary:(NSDictionary *)langs
                  dependency:(NSMutableDictionary *)loaded
{
    if (loaded[name])
        return;

    // Load dependencies first.
    NSDictionary *lang = langs[name];
    if (lang[@"require"])
    {
        [self loadLanguageWithName:lang[@"require"] inDictionary:langs
                        dependency:loaded];
    }

    NSString *pathMeta = langs[@"meta"][@"path"];
    NSError *error = nil;

    // Try minified version first.
    NSString *filename = [name stringByAppendingString:@".min.js"];
    NSString *path = [pathMeta stringByReplacingOccurrencesOfString:@"{id}"
                                                         withString:filename];
    [self runFile:PRIGetResourceURL(path) error:&error];
    if (error)
    {
        // Try development version. Give up if this fails too.
        filename = [name stringByAppendingString:@".js"];
        path = [pathMeta stringByReplacingOccurrencesOfString:@"{id}"
                                                   withString:filename];
        [self runFile:PRIGetResourceURL(path) error:NULL];
    }
    loaded[name] = lang[@"title"];
}

@end
