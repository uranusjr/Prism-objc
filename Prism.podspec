#
#  Be sure to run `pod spec lint Prism-objc.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.

Pod::Spec.new do |s|
  s.name = "Prism"
  s.version = "0.1"
  s.summary = "Objective-C Wrapper for Prism using JavaScriptCore"

  s.description  = <<-DESC
    Prism is a “lightweight, robust, elegant syntax highlighting library” that
    renders code snippets into syntax highlighted HTML. It is created by Lea
    Verou, written in JavaScript, and is based on regular expression.

    This library/framework uses JavaScriptCore to perform so-called “server-
    side rendering” with Prism. It supports most modern OS X versions (I’m not 
    very sure how far back this goes, but at least 10.7+ should be fine) and 
    iOS 7 or later.
    DESC

  s.homepage = "https://github.com/uranusjr/Prism-objc"
  s.license = "MIT"

  s.author = { "Tzu-ping Chung" => "uranusjr@gmail.com" }
  s.social_media_url = "https://twitter.com/uranusjr"

  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.7"

  s.source = {
    :git => "https://github.com/uranusjr/Prism-objc.git",
    :tag => "v#{s.version}",
  }

  s.source_files  = "Prism/Prism/*.{h,m}"
  s.public_header_files = "Prism/Prism/*.h"

  s.resource_bundles = {
    "prism" => [
      "Prism/Dependency/prism/components.js",
      "Prism/Dependency/prism/components",
      "Prism/Dependency/prism/",
    ]
  }

  s.framework = "JavaScriptCore"
  s.requires_arc = true
end
