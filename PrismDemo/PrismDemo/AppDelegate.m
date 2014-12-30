//
//  AppDelegate.m
//  PrismDemo
//
//  Created by Tzu-ping Chung on 30/12.
//  Copyright (c) 2014 uranusjr. All rights reserved.
//

#import "AppDelegate.h"
#import <WebKit/WebKit.h>
#import <Prism/Prism.h>

@interface AppDelegate () <NSTextViewDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *editor;
@property (weak) IBOutlet WebView *webView;
@property (strong) PRISyntaxHighlighter *highlighter;

@end

@implementation AppDelegate

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    self.highlighter =
        [[PRISyntaxHighlighter alloc] initWithDefaultAliases:YES];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.selectedLanguage = [defaults objectForKey:@"selectedLanguage"];
    self.selectedTheme = [defaults objectForKey:@"selectedTheme"];
    if (!self.selectedLanguage)
        self.selectedLanguage = @"c";
    if (!self.selectedTheme)
        self.selectedTheme = @"Default";

    [self addObserver:self forKeyPath:@"selectedLanguage"
              options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"selectedTheme"
              options:NSKeyValueObservingOptionNew context:NULL];

    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"selectedLanguage"];
    [self removeObserver:self forKeyPath:@"selectedTheme"];
}

- (NSArray *)availableLanguages
{
    NSMutableSet *names = [self.highlighter.syntaxNames mutableCopy];
    [names addObjectsFromArray:self.highlighter.aliases.allKeys];

    NSSortDescriptor *sorter =
        [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES];
    NSArray *allNames = [names sortedArrayUsingDescriptors:@[sorter]];
    return allNames;
}

- (NSArray *)themeNames
{
    NSArray *names = self.highlighter.themes.allKeys;
    names = [names sortedArrayUsingSelector:@selector(description)];
    return names;
}

- (void)render
{
    NSError *error = nil;
    NSString *rendered = [self.highlighter highlight:self.editor.string
                                          asLanguage:self.selectedLanguage
                                               error:&error];
    NSAssert(!error, @"This shall not fail!");

    NSURL *baseURL = [[NSBundle mainBundle] resourceURL];
    NSURL *CSSURL = self.highlighter.themes[self.selectedTheme];
    NSString *lang = [self.highlighter resolve:self.selectedLanguage];
    NSString *html = (@"<!DOCTYPE html><html><head><meta charset=\"utf-8\">"
                      @"<link rel=\"stylesheet\" href=\"%@\"></head><body>"
                      @"<pre class=\"language-%@\"><code class=\"language-%@\">"
                      @"%@</code></pre></body></html>");
    html = [NSString stringWithFormat:html, CSSURL.absoluteString,
                                      lang, lang, rendered];
    [self.webView.mainFrame loadHTMLString:html baseURL:baseURL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    // We listen to key-value changes for selectedLanguage and selectedTheme,
    // and re-render on change (not the most efficient way, but this is just a
    // demo and it works so whatever).
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:change[NSKeyValueChangeNewKey] forKey:keyPath];
    [self render];
}


#pragma mark - NSTextViewDelegate

- (void)textDidChange:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] setObject:self.editor.string
                                              forKey:@"content"];
    [self render];
}


#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSMutableParagraphStyle *paragraphStyle =
        [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 3.0;
    paragraphStyle.minimumLineHeight = 21.0;
    paragraphStyle.maximumLineHeight = 21.0;
    paragraphStyle.defaultTabInterval = 56.0;   // 4 characters.
    NSDictionary *typingAttributes =
        [NSDictionary dictionaryWithObject:paragraphStyle
                                    forKey:NSParagraphStyleAttributeName];
    self.editor.defaultParagraphStyle = paragraphStyle;
    self.editor.typingAttributes = typingAttributes;
    self.editor.font = [NSFont fontWithName:@"Menlo Regular" size:14.0];
    self.editor.textContainerInset = NSMakeSize(20.0, 20.0);
    self.editor.automaticDashSubstitutionEnabled = NO;
    self.editor.automaticQuoteSubstitutionEnabled = NO;

    NSString *content =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"content"];
    if (content)
        self.editor.string = content;
    [self render];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
