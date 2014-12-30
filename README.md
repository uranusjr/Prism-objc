# Prism-objc

Objective-C Wrapper for Prism (the JavaScript syntax highlighter) using JavaScriptCore.

## What?

[Prism] is a “lightweight, robust, elegant syntax highlighting library” that renders code snippets into syntax highlighted HTML. It is created by [Lea Verou], written in JavaScript, and is based on regular expression.

This library/framework uses JavaScriptCore to perform so-called “server-side rendering” with Prism. It supports most modern OS X versions (I’m not very sure how far back this goes, but at least 10.7+ should be fine) and iOS 7 or later.

## How?

Quick example:

```obj-c
#import <Prism/Prism.h>

// ...

PRISyntaxHighlighter *highlighter = [[PRISyntaxhighlighter alloc] initWithDefaultAliases:YES];
NSString *output = [highlighter highlight:@"int" asLanguage:@"objc" error:NULL];
NSLog(@"%@", output);   // <span class="token keyword">int</span>
```

The main class is `PRISyntaxHighlighter`. It constructs Prism internally when `init` it. After that, you can use `-highlight:asLanguage:error:` to highlight code snippets.

The language names you pass into when you perform highlighting need to be one of the followings:

1. A built-in definition returned by `-syntaxNames`.
2. One of the language aliases returned by `-aliases`.

You can add/remove aliases using `-addAlias:forName:`, `-addAliases:`, and `-removeAlias:`. An alias should point to a built-in language name, or another alias.

A set of recommended aliases is provided via `+defaultAliases`. Note that they are *not* loaded if you use `init` to initialise `PRISyntaxHighlighter`.

Prism provides some built-in styling. You can get a set of themes and URLs pointing to their respective CSS files via `-themes`.

## Demo

There’s a demo project in the `PrismDemo` directory showing what this library can do. You can build it on OS X in Xcode by opening `Prism.xcworkspace` and run the *PrismDemo* scheme.

![Choose “PrismDemo” before you hit “Run”](http://d.pr/i/1gBPZ+)

![PrismDemo highlighting PRISyntaxHighlighter API](http://d.pr/i/15v8Z+)

## TODO

* Support built-in Prism plugins.
* Support external Prism plugins.


[Prism]: http://prismjs.com/
[Lea Verou]: http://lea.verou.me/