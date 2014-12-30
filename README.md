# Prism-objc

Objective-C Wrapper for Prism (the JavaScript syntax highlighter) using JavaScriptCore.

## What?

[Prism] is a “lightweight, robust, elegant syntax highlighting library” that renders code snippets into syntax highlighted HTML. It is created by [Lea Verou], written in JavaScript, and is based on regular expression.

This library/framework uses [JavaScriptCore] to perform so-called “server-side rendering” with Prism. It supports most modern OS X versions (I’m not very sure how far back this goes, but at least 10.7+ should be fine) and iOS 7 or later.

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

1. A built-in definition that is a key of `-languages`.
2. One of the language aliases that is a key of `-aliases`.

You can add/remove aliases using `-addAlias:forName:`, `-addAliasesFromDictionary:`, and `-removeAlias:`. An alias should point to a built-in language name, or another alias.

A set of recommended aliases is provided via `+defaultAliases`. Note that they are *not* loaded if you use `init` to initialise `PRISyntaxHighlighter`.

Prism provides some built-in styling. You can get a set of themes and URLs pointing to their respective CSS files via `-themes`.

## Demo

There’s a demo project in the `PrismDemo` directory showing what this library can do. You can build it on OS X in Xcode by opening `Prism.xcworkspace` and run the *PrismDemo* scheme.

![Choose “PrismDemo” before you hit “Run”](http://d.pr/i/1gBPZ+)

![PrismDemo highlighting PRISyntaxHighlighter API](http://d.pr/i/15v8Z+)

## Installing

This repository can build as an OS X framework that you can use directly. Alternatively you can also install via [CocoaPods]:

    pod install Prism

Since the original Prism needs to be bundled with the main application, I don’t recommend you just try to include this as a submodule or even copy-paste the code. You will need to structure your project very carefully so that resources can be found correctly. It can work, but you’ll waste a lot of time to this.

## TODO

* Support built-in Prism plugins.
* Support external Prism plugins.
* Travis CI.
* Test Coverage.
* Proper documentation.


[Prism]: http://prismjs.com/
[Lea Verou]: http://lea.verou.me/
[JavaScriptCore]: https://www.webkit.org/projects/javascript/
[CocoaPods]: http://cocoapods.org/
