//
//  PRISyntaxHighlighter.m
//  Prism
//
//  Created by Tzu-ping Chung on 29/12.
//  Copyright (c) 2014 uranusjr. All rights reserved.
//

#import "PRISyntaxHighlighter.h"
#import "PRIPlugIn.h"


#pragma mark - Cocoa Extensions

NS_INLINE NSURL *PRIGetResourceURL(NSString *name)
{
    NSBundle *bundle = [NSBundle bundleForClass:[PRISyntaxHighlighter class]];
    bundle = [NSBundle bundleWithURL:[bundle URLForResource:@"Prism"
                                              withExtension:@"bundle"]];
    NSURL *URL = [bundle URLForResource:name withExtension:@""];
    return URL;
}


#pragma mark - JavaScriptCore Extensions

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


#pragma mark - Helpers

NS_INLINE void PRIRunFile(
    JSContextRef ctx, NSURL *URL, NSError *__autoreleasing *error)
{
    NSString *code = [NSString stringWithContentsOfURL:URL
                                              encoding:NSUTF8StringEncoding
                                                 error:error];
    if (!code)
        return;
    if (!code.length)
        return;

    JSStringRef js = JSStringCreateWithCFString((__bridge CFStringRef)code);
    JSEvaluateScript(ctx, js, NULL, NULL, 0, NULL);
    JSStringRelease(js);
}

NS_INLINE NSDictionary *PRIGetComponents()
{
    static NSDictionary *components = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JSGlobalContextRef ctx = JSGlobalContextCreate(NULL);
        PRIRunFile(ctx, PRIGetResourceURL(@"components.js"), NULL);

        JSObjectRef global = JSContextGetGlobalObject(ctx);
        JSValueRef value = PRIJSObjectGetProperty(ctx, global, "components");
        components = PRIObjectWithJavaScriptValue(ctx, value);

        JSGlobalContextRelease(ctx);
    });

    return components;
}


NS_INLINE void PRILoadLanguage(
    JSContextRef ctx, NSString *name, NSDictionary *langs,
    NSMutableDictionary *loaded)
{
    if (loaded[name])
        return;

    // Load dependencies first.
    NSDictionary *lang = langs[name];
    if (lang[@"require"])
        PRILoadLanguage(ctx, lang[@"require"], langs, loaded);

    NSString *pathMeta = langs[@"meta"][@"path"];
    NSError *error = nil;

    // Try minified version first.
    NSString *filename = [name stringByAppendingString:@".min.js"];
    NSString *path = [pathMeta stringByReplacingOccurrencesOfString:@"{id}"
                                                         withString:filename];
    PRIRunFile(ctx, PRIGetResourceURL(path), &error);
    if (error)
    {
        // Try development version. Give up if this fails too.
        filename = [name stringByAppendingString:@".js"];
        path = [pathMeta stringByReplacingOccurrencesOfString:@"{id}"
                                                   withString:filename];
        PRIRunFile(ctx, PRIGetResourceURL(path), NULL);
    }
    loaded[name] = lang[@"title"];
}

NS_INLINE NSDictionary *PRIInitializeLanguages(
    JSContextRef ctx, NSDictionary *components)
{
    // Load prism-core.
    NSString *corePath = components[@"core"][@"meta"][@"path"];
    PRIRunFile(ctx, PRIGetResourceURL(corePath), NULL);

    // Load languages into global context.
    NSDictionary *languages = components[@"languages"];
    NSMutableDictionary *loadedLanguages = [[NSMutableDictionary alloc] init];

    loadedLanguages[@"meta"] = [NSNull null];
    for (NSString *name in languages)
        PRILoadLanguage(ctx, name, languages, loadedLanguages);
    [loadedLanguages removeObjectForKey:@"meta"];

    return [loadedLanguages copy];
}

NS_INLINE NSDictionary *PRIInitializeThemes(
    JSContextRef ctx, NSDictionary *components)
{
    NSDictionary *themeInfos = components[@"themes"];
    NSMutableDictionary *themes =
        [[NSMutableDictionary alloc] initWithCapacity:themeInfos.count];
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

        NSCAssert(name.length, @"This should be a valid string");
        NSURL *url = PRIGetResourceURL(path);
        themes[name] = url;
    }
    return [themes copy];
}

NS_INLINE NSSet *PRIAllowedPlugins()
{
    return [NSSet setWithObjects:
            @"line-highlight", @"line-numbers", @"show-invisibles", nil];
}


@implementation PRISyntaxHighlighter
{
    NSMutableArray *_plugIns;
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

+ (NSDictionary *)builtInPlugIns
{
    static NSDictionary *plugInMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *plugInInfos = PRIGetComponents()[@"plugins"];
        NSString *pathMeta = plugInInfos[@"meta"][@"path"];
        NSMutableDictionary *plugins = [[NSMutableDictionary alloc] init];
        for (NSString *key in PRIAllowedPlugins())
        {
            id info = plugInInfos[key];
            NSString *name = info;
            if ([info isKindOfClass:[NSDictionary class]])
                name = info[@"title"];
            NSString *path =
                [pathMeta stringByReplacingOccurrencesOfString:@"{id}"
                                                    withString:key];
            NSURL *js =
                PRIGetResourceURL([path stringByAppendingString:@".js"]);
            NSURL *css = nil;
            if (![info isKindOfClass:[NSDictionary class]]
                    || ![info[@"noCSS"] booleanValue])
                css = PRIGetResourceURL([path stringByAppendingString:@".css"]);
            PRIPlugIn *plugIn = [[PRIPlugIn alloc] initWithName:name
                                                     javaScript:js CSS:css];
            plugins[key] = plugIn;
        }
        plugInMap = [plugins copy];
    });
    return plugInMap;
}

- (instancetype)initWithDefaultAliases:(BOOL)loadDefaultAliases
{
    self = [super init];
    if (!self)
        return nil;

    _plugIns = [[NSMutableArray alloc] init];
    _aliases = [[NSMutableDictionary alloc] init];
    if (loadDefaultAliases)
        [self addAliasesFromDictionary:[[self class] defaultAliases]];
    _context = JSGlobalContextCreate(NULL);

    NSDictionary *components = PRIGetComponents();
    _languages = PRIInitializeLanguages(_context, components);
    _themes = PRIInitializeThemes(_context, components);

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

- (instancetype)copyWithZone:(NSZone *)zone
{
    PRISyntaxHighlighter *copied =
        [[PRISyntaxHighlighter allocWithZone:zone] init];

    // _context can't be copied; we'll need to find a way to re-run external
    // plugins when we implement this.
    // _languages and _themes work similarly: if we add functionality to allow
    // user load external definitions we'll need to find a way to inject them
    // here (and obviously we also need to update _context).
    copied->_aliases = _aliases;

    return copied;
}

- (BOOL)loadPlugIn:(PRIPlugIn *)plugin error:(NSError *__autoreleasing *)error
{
    NSError *e = nil;
    NSURL *js = plugin.javaScript;
    if (js)
        PRIRunFile(_context, js, &e);
    if (!e)
        [_plugIns addObject:plugin];

    if (error)
        *error = e;
    return !e;  // Return YES (success) if there's no error.
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

@end
