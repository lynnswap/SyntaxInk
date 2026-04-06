#import "ObjCXcodeBridge.h"

#import <objc/message.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

NSErrorDomain const SIXObjCXcodeBridgeErrorDomain = @"SIXObjCXcodeBridgeErrorDomain";

typedef BOOL (*SIXIDEInitializeFn)(NSUInteger options, NSError **error);
typedef void (*SIXIDESetSafeFn)(BOOL safeToLoad);

static NSArray<NSDictionary<NSString *, id> *> *SIXRuntimeManifestFrameworks = nil;
static BOOL SIXIDEIsInitialized = NO;
static NSURL *SIXMirrorRootURL = nil;
static NSMutableDictionary<NSString *, NSString *> *SIXDependencyPathCache = nil;

static NSString * const SIXXcodeContentsPath = @"/Applications/Xcode.app/Contents";

static NSError *SIXMakeError(SIXObjCXcodeBridgeErrorCode code, NSString *message) {
    return [NSError errorWithDomain:SIXObjCXcodeBridgeErrorDomain code:code userInfo:@{
        NSLocalizedDescriptionKey: message,
    }];
}

static id SIXSend(id target, SEL selector) {
    return ((id (*)(id, SEL))objc_msgSend)(target, selector);
}

static void SIXSendVoid(id target, SEL selector) {
    ((void (*)(id, SEL))objc_msgSend)(target, selector);
}

static void SIXSendVoidObj(id target, SEL selector, id argument) {
    ((void (*)(id, SEL, id))objc_msgSend)(target, selector, argument);
}

static NSColor *SIXSendColor(id target, SEL selector) {
    return ((NSColor *(*)(id, SEL))objc_msgSend)(target, selector);
}

static id SIXValueForIvarMatchingKey(id target, NSString *key) {
    if (target == nil || key.length == 0) {
        return nil;
    }

    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([target class], &count);
    if (ivars == NULL) {
        return nil;
    }

    id matchedValue = nil;
    NSString *underscoredKey = [@"_" stringByAppendingString:key];
    for (unsigned int index = 0; index < count; index++) {
        Ivar ivar = ivars[index];
        const char *nameCString = ivar_getName(ivar);
        const char *typeEncoding = ivar_getTypeEncoding(ivar);
        if (nameCString == NULL || typeEncoding == NULL || typeEncoding[0] != '@') {
            continue;
        }

        NSString *name = [NSString stringWithUTF8String:nameCString];
        if (![name isEqualToString:key] &&
            ![name isEqualToString:underscoredKey] &&
            ![name containsString:key]) {
            continue;
        }

        matchedValue = object_getIvar(target, ivar);
        if (matchedValue != nil) {
            break;
        }
    }

    free(ivars);
    return matchedValue;
}

static id SIXValueForKeyIfAccessible(id target, NSString *key) {
    if (target == nil || key.length == 0) {
        return nil;
    }

    @try {
        id value = [target valueForKey:key];
        if (value != nil) {
            return value;
        }
    } @catch (__unused NSException *exception) {
    }

    return SIXValueForIvarMatchingKey(target, key);
}

static id SIXResolvedFontAndColorThemeForDisplayName(NSString *themeDisplayName) {
    Class themeClass = NSClassFromString(@"DVTFontAndColorTheme");
    if (themeClass == Nil) {
        return nil;
    }

    SEL selector = NULL;
    if ([themeDisplayName isEqualToString:@"Default (Light)"]) {
        selector = @selector(ideDefaultLightTheme);
    } else if ([themeDisplayName isEqualToString:@"Default (Dark)"]) {
        selector = @selector(ideDefaultDarkTheme);
    } else if ([themeDisplayName containsString:@"(Dark)"]) {
        selector = @selector(currentDarkTheme);
    } else if ([themeDisplayName containsString:@"(Light)"]) {
        selector = @selector(currentLightTheme);
    } else {
        selector = @selector(currentTheme);
    }

    if (![themeClass respondsToSelector:selector]) {
        return nil;
    }

    return SIXSend(themeClass, selector);
}

static void SIXApplyThemeToTextViewIfNeeded(NSView *view, id theme) {
    if (view == nil || theme == nil) {
        return;
    }

    NSString *className = NSStringFromClass(view.class);
    if (![className containsString:@"DVTCompletingTextView"]) {
        return;
    }

    if ([theme respondsToSelector:@selector(sourceTextBackgroundColor)] &&
        [view respondsToSelector:@selector(setBackgroundColor:)]) {
        SIXSendVoidObj(view, @selector(setBackgroundColor:), SIXSendColor(theme, @selector(sourceTextBackgroundColor)));
    }

    if ([theme respondsToSelector:@selector(sourceTextCurrentLineHighlightColor)] &&
        [view respondsToSelector:@selector(setCurrentLineHighlightColor:)]) {
        SIXSendVoidObj(view, @selector(setCurrentLineHighlightColor:), SIXSendColor(theme, @selector(sourceTextCurrentLineHighlightColor)));
    }

    if ([theme respondsToSelector:@selector(sourceTextSecondarySelectionColor)] &&
        [view respondsToSelector:@selector(setSecondarySelectedTextBackgroundColor:)]) {
        SIXSendVoidObj(view, @selector(setSecondarySelectedTextBackgroundColor:), SIXSendColor(theme, @selector(sourceTextSecondarySelectionColor)));
    }

    if ([theme respondsToSelector:@selector(sourceTextInsertionPointColor)] &&
        [view respondsToSelector:@selector(setInsertionPointColor:)]) {
        SIXSendVoidObj(view, @selector(setInsertionPointColor:), SIXSendColor(theme, @selector(sourceTextInsertionPointColor)));
    }
}

static NSArray<NSString *> *SIXThemeGraphChildSelectorNames(void) {
    static NSArray<NSString *> *selectorNames = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        selectorNames = @[
            @"contentView",
            @"containerView",
            @"documentView",
            @"document",
            @"editorView",
            @"editor",
            @"gutter",
            @"minimapView",
            @"scrollView",
            @"sourceEditorView",
            @"sourceTextView",
            @"textView",
        ];
    });
    return selectorNames;
}

static BOOL SIXVisitObjectGraph(id object, NSMutableSet<NSString *> *visited, BOOL (^visitor)(id candidate)) {
    if (object == nil) {
        return NO;
    }

    NSString *identifier = [NSString stringWithFormat:@"%p", object];
    if ([visited containsObject:identifier]) {
        return NO;
    }
    [visited addObject:identifier];

    if (visitor(object)) {
        return YES;
    }

    if ([object isKindOfClass:[NSView class]]) {
        for (NSView *subview in ((NSView *)object).subviews) {
            if (SIXVisitObjectGraph(subview, visited, visitor)) {
                return YES;
            }
        }
    }

    for (NSString *selectorName in SIXThemeGraphChildSelectorNames()) {
        SEL selector = NSSelectorFromString(selectorName);
        id child = [object respondsToSelector:selector] ? SIXSend(object, selector) : nil;
        if (child == nil) {
            child = SIXValueForKeyIfAccessible(object, selectorName);
        }
        if (child != nil && SIXVisitObjectGraph(child, visited, visitor)) {
            return YES;
        }
    }

    return NO;
}

static id SIXFirstTextStorageInObjectGraph(id object) {
    __block id textStorage = nil;
    NSMutableSet<NSString *> *visited = [NSMutableSet set];
    SIXVisitObjectGraph(object, visited, ^BOOL(id candidate) {
        id resolvedTextStorage = [candidate respondsToSelector:@selector(textStorage)]
            ? SIXSend(candidate, @selector(textStorage))
            : nil;
        if (resolvedTextStorage == nil) {
            resolvedTextStorage = SIXValueForKeyIfAccessible(candidate, @"textStorage");
        }
        if (resolvedTextStorage != nil) {
            textStorage = resolvedTextStorage;
            return YES;
        }

        if ([candidate respondsToSelector:@selector(setFontAndColorTheme:)] &&
            [candidate respondsToSelector:@selector(fontAndColorTheme)]) {
            textStorage = candidate;
            return YES;
        }

        return NO;
    });
    return textStorage;
}

static void SIXApplyFontAndColorThemeToObjectGraph(id object, id theme) {
    NSMutableSet<NSString *> *visited = [NSMutableSet set];
    SIXVisitObjectGraph(object, visited, ^BOOL(id candidate) {
        id textStorage = [candidate respondsToSelector:@selector(textStorage)]
            ? SIXSend(candidate, @selector(textStorage))
            : nil;
        if (textStorage == nil) {
            textStorage = SIXValueForKeyIfAccessible(candidate, @"textStorage");
        }
        if (textStorage != nil && [textStorage respondsToSelector:@selector(setFontAndColorTheme:)]) {
            SIXSendVoidObj(textStorage, @selector(setFontAndColorTheme:), theme);
        }

        if ([candidate respondsToSelector:@selector(setFontAndColorTheme:)] &&
            [candidate respondsToSelector:@selector(fontAndColorTheme)]) {
            SIXSendVoidObj(candidate, @selector(setFontAndColorTheme:), theme);
        }

        if ([candidate respondsToSelector:@selector(_loadFontsAndColorsFromTheme:)]) {
            SIXSendVoidObj(candidate, @selector(_loadFontsAndColorsFromTheme:), theme);
        }

        if ([candidate respondsToSelector:@selector(currentTheme)] &&
            [candidate respondsToSelector:@selector(setTheme:)]) {
            id currentTheme = SIXSend(candidate, @selector(currentTheme));
            if (currentTheme != nil) {
                SIXSendVoidObj(candidate, @selector(setTheme:), currentTheme);
            }
        }

        id sourceEditorView = [candidate respondsToSelector:NSSelectorFromString(@"sourceEditorView")]
            ? SIXSend(candidate, NSSelectorFromString(@"sourceEditorView"))
            : nil;
        if (sourceEditorView == nil) {
            sourceEditorView = SIXValueForKeyIfAccessible(candidate, @"sourceEditorView");
        }
        if (sourceEditorView != nil &&
            [candidate respondsToSelector:@selector(currentTheme)] &&
            [sourceEditorView respondsToSelector:@selector(setTheme:)]) {
            id currentTheme = SIXSend(candidate, @selector(currentTheme));
            if (currentTheme != nil) {
                SIXSendVoidObj(sourceEditorView, @selector(setTheme:), currentTheme);
            }
        }

        if ([candidate respondsToSelector:@selector(fontAndColorSettingsChanged:)]) {
            SIXSendVoidObj(candidate, @selector(fontAndColorSettingsChanged:), nil);
        }

        if ([candidate isKindOfClass:[NSView class]]) {
            SIXApplyThemeToTextViewIfNeeded(candidate, theme);
        }

        return NO;
    });
}

static void SIXRefreshSyntaxColoringInViewTree(NSView *view) {
    id textStorage = SIXFirstTextStorageInObjectGraph(view);
    if (textStorage == nil ||
        ![textStorage respondsToSelector:@selector(string)] ||
        ![textStorage respondsToSelector:@selector(fixSyntaxColoringInRange:)]) {
        return;
    }

    NSString *string = SIXSend(textStorage, @selector(string));
    NSRange fullRange = NSMakeRange(0, string.length);
    ((void (*)(id, SEL, NSRange))objc_msgSend)(textStorage, @selector(fixSyntaxColoringInRange:), fullRange);
}

static id SIXContainerViewForEditor(id editor) {
    id containerView = SIXValueForKeyIfAccessible(editor, @"containerView");
    if (containerView != nil) {
        return containerView;
    }
    return SIXValueForIvarMatchingKey(editor, @"containerView");
}

static id SIXSourceEditorCoreViewForContainerView(id containerView) {
    id sourceEditorView = SIXValueForKeyIfAccessible(containerView, @"sourceEditorView");
    if (sourceEditorView != nil) {
        return sourceEditorView;
    }
    return SIXValueForIvarMatchingKey(containerView, @"sourceEditorView");
}

static id SIXCurrentThemeForEditor(id editor) {
    id containerView = SIXContainerViewForEditor(editor);
    if (containerView != nil && [containerView respondsToSelector:@selector(currentTheme)]) {
        id theme = SIXSend(containerView, @selector(currentTheme));
        if (theme != nil) {
            return theme;
        }
    }
    return nil;
}

static void SIXRefreshEditorThemeInternals(id editor) {
    if (editor == nil) {
        return;
    }

    id containerView = SIXContainerViewForEditor(editor);
    id sourceEditorView = SIXSourceEditorCoreViewForContainerView(containerView);
    id currentTheme = SIXCurrentThemeForEditor(editor);

    if (currentTheme != nil && sourceEditorView != nil && [sourceEditorView respondsToSelector:@selector(setTheme:)]) {
        SIXSendVoidObj(sourceEditorView, @selector(setTheme:), currentTheme);
    }

    if (containerView != nil && [containerView respondsToSelector:@selector(fontAndColorSettingsChanged:)]) {
        SIXSendVoidObj(containerView, @selector(fontAndColorSettingsChanged:), nil);
    }
}

static NSURL *SIXMirrorRootDirectory(void) {
    if (SIXMirrorRootURL != nil) {
        return SIXMirrorRootURL;
    }

    NSURL *rootURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"syntaxink-xcode-mirror"] isDirectory:YES];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    [fileManager removeItemAtURL:rootURL error:nil];
    [fileManager createDirectoryAtURL:rootURL withIntermediateDirectories:YES attributes:nil error:nil];

    NSURL *contentsURL = [rootURL URLByAppendingPathComponent:@"Contents" isDirectory:YES];
    [fileManager createDirectoryAtURL:contentsURL withIntermediateDirectories:YES attributes:nil error:nil];

    NSURL *contentsVersionPlistLinkURL = [rootURL URLByAppendingPathComponent:@"Contents/version.plist"];
    NSURL *contentsVersionPlistURL = [NSURL fileURLWithPath:[SIXXcodeContentsPath stringByAppendingPathComponent:@"version.plist"]];
    if (![fileManager fileExistsAtPath:contentsVersionPlistLinkURL.path]) {
        [fileManager createSymbolicLinkAtURL:contentsVersionPlistLinkURL withDestinationURL:contentsVersionPlistURL error:nil];
    }

    NSURL *contentsInfoPlistLinkURL = [rootURL URLByAppendingPathComponent:@"Contents/Info.plist"];
    NSURL *contentsInfoPlistURL = [NSURL fileURLWithPath:[SIXXcodeContentsPath stringByAppendingPathComponent:@"Info.plist"]];
    if (![fileManager fileExistsAtPath:contentsInfoPlistLinkURL.path]) {
        [fileManager createSymbolicLinkAtURL:contentsInfoPlistLinkURL withDestinationURL:contentsInfoPlistURL error:nil];
    }

    NSURL *developerPlatformsURL = [rootURL URLByAppendingPathComponent:@"Contents/Developer/Platforms" isDirectory:YES];
    [fileManager createDirectoryAtURL:developerPlatformsURL withIntermediateDirectories:YES attributes:nil error:nil];

    NSURL *macOSPlatformLinkURL = [developerPlatformsURL URLByAppendingPathComponent:@"MacOSX.platform" isDirectory:YES];
    NSURL *macOSPlatformURL = [NSURL fileURLWithPath:[SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform"] isDirectory:YES];
    if (![fileManager fileExistsAtPath:macOSPlatformLinkURL.path]) {
        [fileManager createSymbolicLinkAtURL:macOSPlatformLinkURL withDestinationURL:macOSPlatformURL error:nil];
    }

    SIXMirrorRootURL = rootURL;
    return rootURL;
}

static BOOL SIXPathHasSuffix(NSString *path, NSString *suffix) {
    return path != nil && suffix != nil && [path hasSuffix:suffix];
}

static BOOL SIXIsTestFamilyReference(NSString *reference) {
    if (reference.length == 0) {
        return NO;
    }

    NSArray<NSString *> *suffixes = @[
        @"XCTest.framework/Versions/A/XCTest",
        @"XCUIAutomation.framework/Versions/A/XCUIAutomation",
        @"XCTestCore.framework/Versions/A/XCTestCore",
        @"XCTestSupport.framework/Versions/A/XCTestSupport",
        @"XCTAutomationSupport.framework/Versions/A/XCTAutomationSupport",
        @"XCTHarness.framework/Versions/A/XCTHarness",
        @"XCTDaemonControl.framework/Versions/A/XCTDaemonControl",
        @"Testing.framework/Versions/A/Testing",
        @"_Testing_Foundation.framework/Versions/A/_Testing_Foundation",
        @"XCUnit.framework/Versions/A/XCUnit",
        @"libXCTestSwiftSupport.dylib",
        @"libXCTestBundleInject.dylib",
        @"lib_TestingInterop.dylib",
    ];

    for (NSString *suffix in suffixes) {
        if (SIXPathHasSuffix(reference, suffix)) {
            return YES;
        }
    }
    return NO;
}

static NSString *SIXCanonicalTestFamilyPath(NSString *reference) {
    if (reference.length == 0) {
        return nil;
    }

    NSDictionary<NSString *, NSString *> *mapping = @{
        @"XCTest.framework/Versions/A/XCTest": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/XCTest.framework/Versions/A/XCTest"],
        @"XCUIAutomation.framework/Versions/A/XCUIAutomation": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Versions/A/XCUIAutomation"],
        @"XCTestCore.framework/Versions/A/XCTestCore": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks/XCTestCore.framework/Versions/A/XCTestCore"],
        @"XCTestSupport.framework/Versions/A/XCTestSupport": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks/XCTestSupport.framework/Versions/A/XCTestSupport"],
        @"XCTAutomationSupport.framework/Versions/A/XCTAutomationSupport": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks/XCTAutomationSupport.framework/Versions/A/XCTAutomationSupport"],
        @"XCTHarness.framework/Versions/A/XCTHarness": [SIXXcodeContentsPath stringByAppendingPathComponent:@"SharedFrameworks/XCTHarness.framework/Versions/A/XCTHarness"],
        @"XCTDaemonControl.framework/Versions/A/XCTDaemonControl": [SIXXcodeContentsPath stringByAppendingPathComponent:@"SharedFrameworks/XCTDaemonControl.framework/Versions/A/XCTDaemonControl"],
        @"Testing.framework/Versions/A/Testing": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/Testing.framework/Versions/A/Testing"],
        @"_Testing_Foundation.framework/Versions/A/_Testing_Foundation": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/_Testing_Foundation.framework/Versions/A/_Testing_Foundation"],
        @"XCUnit.framework/Versions/A/XCUnit": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks/XCUnit.framework/Versions/A/XCUnit"],
        @"libXCTestSwiftSupport.dylib": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/usr/lib/libXCTestSwiftSupport.dylib"],
        @"libXCTestBundleInject.dylib": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/usr/lib/libXCTestBundleInject.dylib"],
        @"lib_TestingInterop.dylib": [SIXXcodeContentsPath stringByAppendingPathComponent:@"Developer/Platforms/MacOSX.platform/Developer/usr/lib/lib_TestingInterop.dylib"],
    };

    for (NSString *suffix in mapping) {
        if (SIXPathHasSuffix(reference, suffix)) {
            return mapping[suffix];
        }
    }
    return nil;
}

static BOOL SIXProcessIsRunningUnderXCTest(void) {
    NSDictionary<NSString *, NSString *> *environment = NSProcessInfo.processInfo.environment;
    if (environment[@"XCTestConfigurationFilePath"] != nil ||
        environment[@"XCInjectBundleInto"] != nil ||
        environment[@"XCTestSessionIdentifier"] != nil) {
        return YES;
    }

    uint32_t imageCount = _dyld_image_count();
    for (uint32_t index = 0; index < imageCount; index++) {
        const char *imageName = _dyld_get_image_name(index);
        if (imageName == NULL) {
            continue;
        }

        NSString *imagePath = [NSString stringWithUTF8String:imageName];
        if ([imagePath containsString:@"libXCTestBundleInject.dylib"] ||
            [imagePath containsString:@"XCTest.framework/Versions/A/XCTest"] ||
            [imagePath containsString:@"XCUIAutomation.framework/Versions/A/XCUIAutomation"]) {
            return YES;
        }
    }

    return NSClassFromString(@"XCTestCase") != Nil || NSClassFromString(@"XCUIApplication") != Nil;
}

static NSString *SIXMirrorBinaryPathForRealPath(NSString *path, NSError **error) {
    if (SIXIsTestFamilyReference(path)) {
        NSString *canonicalPath = SIXCanonicalTestFamilyPath(path);
        if (canonicalPath.length > 0) {
            return canonicalPath;
        }
    }

    NSRange contentsRange = [path rangeOfString:@"/Contents/"];
    NSRange frameworkRange = [path rangeOfString:@".framework"];
    BOOL isPlainDylib = [[path.pathExtension lowercaseString] isEqualToString:@"dylib"];
    if (contentsRange.location == NSNotFound) {
        return path;
    }

    NSURL *mirrorRootURL = SIXMirrorRootDirectory();
    NSString *relativeBinaryPath = [path substringFromIndex:contentsRange.location + 1];
    NSURL *mirrorBinaryURL = [mirrorRootURL URLByAppendingPathComponent:relativeBinaryPath];
    NSFileManager *fileManager = NSFileManager.defaultManager;

    if (frameworkRange.location == NSNotFound || isPlainDylib) {
        NSURL *parentDirectoryURL = [mirrorBinaryURL URLByDeletingLastPathComponent];
        if (![fileManager fileExistsAtPath:mirrorBinaryURL.path]) {
            if (![fileManager createDirectoryAtURL:parentDirectoryURL withIntermediateDirectories:YES attributes:nil error:error]) {
                return nil;
            }

            NSURL *sourceURL = [[NSURL fileURLWithPath:path] URLByResolvingSymlinksInPath];
            NSError *linkError = nil;
            if (![fileManager linkItemAtURL:sourceURL toURL:mirrorBinaryURL error:&linkError]) {
                if (![fileManager copyItemAtURL:sourceURL toURL:mirrorBinaryURL error:error]) {
                    return nil;
                }
            }
        }

        NSURL *rootAliasURL = [mirrorRootURL URLByAppendingPathComponent:[@"Contents/" stringByAppendingString:path.lastPathComponent]];
        if (![fileManager fileExistsAtPath:rootAliasURL.path]) {
            [fileManager createSymbolicLinkAtURL:rootAliasURL withDestinationURL:mirrorBinaryURL error:nil];
        }

        NSArray<NSURL *> *dylibAliasDirectories = @[
            [mirrorRootURL URLByAppendingPathComponent:@"Contents/SharedFrameworks" isDirectory:YES],
            [mirrorRootURL URLByAppendingPathComponent:@"Contents/Frameworks" isDirectory:YES],
            [mirrorRootURL URLByAppendingPathComponent:@"Contents/Developer/Library/Frameworks" isDirectory:YES],
            [mirrorRootURL URLByAppendingPathComponent:@"Contents/Developer/usr/lib" isDirectory:YES],
            [mirrorRootURL URLByAppendingPathComponent:@"Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib" isDirectory:YES],
            [mirrorRootURL URLByAppendingPathComponent:@"Contents/SharedFrameworks/SourceKit.framework/Versions/A/XPCServices/com.apple.dt.SKAgent.xpc/Contents/Frameworks" isDirectory:YES],
        ];
        NSString *binaryName = path.lastPathComponent;
        for (NSURL *aliasDirectory in dylibAliasDirectories) {
            [fileManager createDirectoryAtURL:aliasDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            NSURL *aliasURL = [aliasDirectory URLByAppendingPathComponent:binaryName];
            if (![fileManager fileExistsAtPath:aliasURL.path]) {
                [fileManager createSymbolicLinkAtURL:aliasURL withDestinationURL:mirrorBinaryURL error:nil];
            }
        }
        return mirrorBinaryURL.path;
    }

    NSString *bundlePath = [path substringToIndex:NSMaxRange(frameworkRange)];
    NSString *relativeBundlePath = [bundlePath substringFromIndex:contentsRange.location + 1];
    NSString *binaryName = path.lastPathComponent;
    NSURL *mirrorBundleURL = [mirrorRootURL URLByAppendingPathComponent:relativeBundlePath];
    NSURL *mirrorVersionsURL = [mirrorBundleURL URLByAppendingPathComponent:@"Versions" isDirectory:YES];
    NSURL *mirrorVersionAURL = [mirrorVersionsURL URLByAppendingPathComponent:@"A" isDirectory:YES];
    mirrorBinaryURL = [mirrorVersionAURL URLByAppendingPathComponent:binaryName];

    if (![fileManager fileExistsAtPath:mirrorBinaryURL.path]) {
        if (![fileManager createDirectoryAtURL:mirrorVersionAURL withIntermediateDirectories:YES attributes:nil error:error]) {
            return nil;
        }

        NSURL *sourceURL = [[NSURL fileURLWithPath:path] URLByResolvingSymlinksInPath];
        NSError *linkError = nil;
        if (![fileManager linkItemAtURL:sourceURL toURL:mirrorBinaryURL error:&linkError]) {
            if (![fileManager copyItemAtURL:sourceURL toURL:mirrorBinaryURL error:error]) {
                return nil;
            }
        }

    }

    NSURL *currentSymlinkURL = [mirrorVersionsURL URLByAppendingPathComponent:@"Current"];
    if (![fileManager fileExistsAtPath:currentSymlinkURL.path]) {
        [fileManager createSymbolicLinkAtURL:currentSymlinkURL withDestinationURL:mirrorVersionAURL error:nil];
    }

    NSURL *topLevelBinaryURL = [mirrorBundleURL URLByAppendingPathComponent:binaryName];
    if (![fileManager fileExistsAtPath:topLevelBinaryURL.path]) {
        [fileManager createSymbolicLinkAtURL:topLevelBinaryURL withDestinationURL:mirrorBinaryURL error:nil];
    }

    NSURL *realResourcesURL = [[NSURL fileURLWithPath:bundlePath] URLByAppendingPathComponent:@"Versions/A/Resources" isDirectory:YES];
    if ([fileManager fileExistsAtPath:realResourcesURL.path]) {
        NSURL *mirrorResourcesURL = [mirrorVersionAURL URLByAppendingPathComponent:@"Resources" isDirectory:YES];
        if (![fileManager fileExistsAtPath:mirrorResourcesURL.path]) {
            [fileManager createSymbolicLinkAtURL:mirrorResourcesURL withDestinationURL:realResourcesURL error:nil];
        }
        NSURL *topLevelResourcesURL = [mirrorBundleURL URLByAppendingPathComponent:@"Resources" isDirectory:YES];
        if (![fileManager fileExistsAtPath:topLevelResourcesURL.path]) {
            [fileManager createSymbolicLinkAtURL:topLevelResourcesURL withDestinationURL:mirrorResourcesURL error:nil];
        }

        NSURL *realInfoPlistURL = [realResourcesURL URLByAppendingPathComponent:@"Info.plist"];
        NSURL *mirrorInfoPlistURL = [mirrorBundleURL URLByAppendingPathComponent:@"Info.plist"];
        if ([fileManager fileExistsAtPath:realInfoPlistURL.path] && ![fileManager fileExistsAtPath:mirrorInfoPlistURL.path]) {
            [fileManager createSymbolicLinkAtURL:mirrorInfoPlistURL withDestinationURL:realInfoPlistURL error:nil];
        }
    }

    NSURL *realNestedFrameworksURL = [[NSURL fileURLWithPath:bundlePath] URLByAppendingPathComponent:@"Versions/A/Frameworks" isDirectory:YES];
    if ([fileManager fileExistsAtPath:realNestedFrameworksURL.path]) {
        NSURL *mirrorNestedFrameworksURL = [mirrorVersionAURL URLByAppendingPathComponent:@"Frameworks" isDirectory:YES];
        if (![fileManager fileExistsAtPath:mirrorNestedFrameworksURL.path]) {
            [fileManager createSymbolicLinkAtURL:mirrorNestedFrameworksURL withDestinationURL:realNestedFrameworksURL error:nil];
        }
    }

    NSURL *realNestedXPCServicesURL = [[NSURL fileURLWithPath:bundlePath] URLByAppendingPathComponent:@"Versions/A/XPCServices" isDirectory:YES];
    if ([fileManager fileExistsAtPath:realNestedXPCServicesURL.path]) {
        NSURL *mirrorNestedXPCServicesURL = [mirrorVersionAURL URLByAppendingPathComponent:@"XPCServices" isDirectory:YES];
        if (![fileManager fileExistsAtPath:mirrorNestedXPCServicesURL.path]) {
            [fileManager createSymbolicLinkAtURL:mirrorNestedXPCServicesURL withDestinationURL:realNestedXPCServicesURL error:nil];
        }

        NSURL *topLevelXPCServicesURL = [mirrorBundleURL URLByAppendingPathComponent:@"XPCServices" isDirectory:YES];
        if (![fileManager fileExistsAtPath:topLevelXPCServicesURL.path]) {
            [fileManager createSymbolicLinkAtURL:topLevelXPCServicesURL withDestinationURL:mirrorNestedXPCServicesURL error:nil];
        }
    }

    NSArray<NSURL *> *aliasDirectories = @[
        [mirrorRootURL URLByAppendingPathComponent:@"Contents/SharedFrameworks" isDirectory:YES],
        [mirrorRootURL URLByAppendingPathComponent:@"Contents/Frameworks" isDirectory:YES],
        [mirrorRootURL URLByAppendingPathComponent:@"Contents/Developer/Library/Frameworks" isDirectory:YES],
        [mirrorRootURL URLByAppendingPathComponent:@"Contents/Developer/Library/PrivateFrameworks" isDirectory:YES],
        [mirrorRootURL URLByAppendingPathComponent:@"Contents" isDirectory:YES],
    ];
    NSString *bundleName = bundlePath.lastPathComponent;
    for (NSURL *aliasDirectory in aliasDirectories) {
        [fileManager createDirectoryAtURL:aliasDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        NSURL *aliasURL = [aliasDirectory URLByAppendingPathComponent:bundleName];
        if (![fileManager fileExistsAtPath:aliasURL.path]) {
            [fileManager createSymbolicLinkAtURL:aliasURL withDestinationURL:mirrorBundleURL error:nil];
        }
    }

    return [mirrorRootURL.path stringByAppendingPathComponent:relativeBinaryPath];
}

static NSString *SIXMissingLoadReference(NSString *errorMessage) {
    NSRange prefixRange = [errorMessage rangeOfString:@"Library not loaded: "];
    if (prefixRange.location == NSNotFound) {
        return nil;
    }

    NSString *suffix = [errorMessage substringFromIndex:NSMaxRange(prefixRange)];
    NSCharacterSet *newlineSet = [NSCharacterSet newlineCharacterSet];
    NSRange newlineRange = [suffix rangeOfCharacterFromSet:newlineSet];
    if (newlineRange.location != NSNotFound) {
        suffix = [suffix substringToIndex:newlineRange.location];
    }
    return [suffix stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

static NSString *SIXResolveDependencyPathFromReference(NSString *reference) {
    if (reference.length == 0) {
        return nil;
    }

    if (SIXIsTestFamilyReference(reference)) {
        return SIXCanonicalTestFamilyPath(reference);
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SIXDependencyPathCache = [NSMutableDictionary dictionary];
    });

    @synchronized (SIXDependencyPathCache) {
        NSString *cachedPath = SIXDependencyPathCache[reference];
        if (cachedPath != nil) {
            return cachedPath;
        }
    }

    NSString *candidateSuffix = reference;
    if ([candidateSuffix hasPrefix:@"@rpath/"]) {
        candidateSuffix = [candidateSuffix substringFromIndex:@"@rpath/".length];
    } else if ([candidateSuffix hasPrefix:@"/Applications/Xcode.app/Contents/"]) {
        candidateSuffix = [candidateSuffix substringFromIndex:@"/Applications/Xcode.app/Contents/".length];
    }

    NSString *xcodeContentsPath = SIXXcodeContentsPath;
    NSString *exactContentsPath = [xcodeContentsPath stringByAppendingPathComponent:candidateSuffix];
    if ([[NSFileManager defaultManager] fileExistsAtPath:exactContentsPath]) {
        @synchronized (SIXDependencyPathCache) {
            SIXDependencyPathCache[reference] = exactContentsPath;
        }
        return exactContentsPath;
    }

    NSArray<NSString *> *searchRoots = @[
        @"SharedFrameworks",
        @"Frameworks",
        @"PlugIns",
        @"Developer/Library/Frameworks",
        @"Developer/Library/PrivateFrameworks",
        @"Developer/usr/lib",
        @"Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks",
        @"Developer/Platforms/MacOSX.platform/Developer/Library/PrivateFrameworks",
        @"Developer/Platforms/MacOSX.platform/Developer/usr/lib",
        @"Developer/Platforms/MacOSX.platform/Developer/iOSSupport/Library/PrivateFrameworks",
        @"Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib",
        @"SharedFrameworks/SourceKit.framework/Versions/A/XPCServices/com.apple.dt.SKAgent.xpc/Contents/Frameworks",
    ];
    for (NSString *searchRoot in searchRoots) {
        NSString *resolvedPath = [[xcodeContentsPath stringByAppendingPathComponent:searchRoot] stringByAppendingPathComponent:candidateSuffix];
        if (![[NSFileManager defaultManager] fileExistsAtPath:resolvedPath]) {
            continue;
        }

        @synchronized (SIXDependencyPathCache) {
            SIXDependencyPathCache[reference] = resolvedPath;
        }
        return resolvedPath;
    }

    return nil;
}

static BOOL SIXLoadFrameworkAtPath(NSString *path, NSError **error) {
    NSString *loadPath = SIXMirrorBinaryPathForRealPath(path, error);
    if (loadPath == nil) {
        return NO;
    }

    void *handle = dlopen(loadPath.fileSystemRepresentation, RTLD_NOW | RTLD_GLOBAL);
    if (handle != NULL) {
        return YES;
    }

    NSString *errorMessage = [NSString stringWithUTF8String:dlerror()];
    NSString *missingReference = SIXMissingLoadReference(errorMessage);
    NSString *resolvedDependencyPath = SIXResolveDependencyPathFromReference(missingReference);
    if (resolvedDependencyPath != nil && ![resolvedDependencyPath isEqualToString:path]) {
        NSError *dependencyError = nil;
        if (SIXLoadFrameworkAtPath(resolvedDependencyPath, &dependencyError)) {
            handle = dlopen(loadPath.fileSystemRepresentation, RTLD_NOW | RTLD_GLOBAL);
            if (handle != NULL) {
                return YES;
            }
            errorMessage = [NSString stringWithUTF8String:dlerror()];
        }
    }

    if (error != NULL) {
        NSString *message = [NSString stringWithFormat:@"Failed to load framework at %@: %@", loadPath, errorMessage ?: @"unknown dlopen error"];
        *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeFrameworkLoadFailed, message);
    }
    return NO;
}

static NSString *SIXContentTypeIdentifierForFileName(NSString *fileName) {
    NSString *extension = fileName.pathExtension.lowercaseString;
    if ([extension isEqualToString:@"h"]) {
        return @"public.objective-c-header";
    }
    return @"public.objective-c-source";
}

@interface SIXObjCXcodeEditorHostView : NSView

@property (nonatomic, strong) id document;
@property (nonatomic, strong) id editor;
@property (nonatomic, strong) NSView *embeddedView;
@property (nonatomic, strong) NSURL *scratchDirectoryURL;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, copy) NSString *themeDisplayName;

- (BOOL)configureWithSource:(NSString *)source
                   fileName:(NSString *)fileName
           themeDisplayName:(NSString *)themeDisplayName
                previewMode:(BOOL)previewMode
                      error:(NSError **)error;

- (void)refreshActive:(BOOL)active;
- (void)applyThemeStyling;
- (void)scheduleDeferredSyntaxColoringRefresh;

@end

@implementation SIXObjCXcodeEditorHostView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self != nil) {
        self.autoresizesSubviews = YES;
    }
    return self;
}

- (void)dealloc {
    @try {
        if (self.document != nil && self.editor != nil && [self.document respondsToSelector:@selector(unregisterDocumentEditor:)]) {
            SIXSendVoidObj(self.document, @selector(unregisterDocumentEditor:), self.editor);
        }
    } @catch (__unused NSException *exception) {
    }

    if (self.scratchDirectoryURL != nil) {
        [[NSFileManager defaultManager] removeItemAtURL:self.scratchDirectoryURL error:nil];
    }
}

- (void)layout {
    [super layout];
    self.embeddedView.frame = self.bounds;
}

- (void)refreshActive:(BOOL)active {
    [self applyThemeStyling];
    [self layoutSubtreeIfNeeded];
    [self.embeddedView layoutSubtreeIfNeeded];
    [self displayIfNeeded];
    [self.embeddedView displayIfNeeded];
    [self scheduleDeferredSyntaxColoringRefresh];

    SEL selector = @selector(scrollView:didChangePresentationOrigin:active:);
    if ([self.embeddedView respondsToSelector:selector]) {
        NSPoint origin = NSZeroPoint;
        ((void (*)(id, SEL, id, NSPoint, BOOL))objc_msgSend)(self.embeddedView, selector, nil, origin, active);
    }
}

- (void)applyThemeAppearance {
    NSString *appearanceName = NSAppearanceNameAqua;
    if ([self.themeDisplayName isEqualToString:@"Default (Dark)"]) {
        appearanceName = NSAppearanceNameDarkAqua;
    }

    NSAppearance *appearance = [NSAppearance appearanceNamed:appearanceName];
    self.appearance = appearance;
    self.embeddedView.appearance = appearance;
}

- (void)applyThemeStyling {
    [self applyThemeAppearance];

    id theme = SIXResolvedFontAndColorThemeForDisplayName(self.themeDisplayName);
    if (theme == nil || self.embeddedView == nil) {
        return;
    }

    SIXApplyFontAndColorThemeToObjectGraph(self.embeddedView, theme);
    SIXRefreshEditorThemeInternals(self.editor);
}

- (void)scheduleDeferredSyntaxColoringRefresh {
    __weak typeof(self) weakSelf = self;
    NSArray<NSNumber *> *delays = @[@0.0, @0.05, @0.2];
    for (NSNumber *delay in delays) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{
                typeof(self) strongSelf = weakSelf;
                if (strongSelf == nil || strongSelf.embeddedView == nil) {
                    return;
                }

                [strongSelf applyThemeStyling];
                [strongSelf layoutSubtreeIfNeeded];
                [strongSelf.embeddedView layoutSubtreeIfNeeded];
                SIXRefreshSyntaxColoringInViewTree(strongSelf.embeddedView);
                [strongSelf.embeddedView setNeedsDisplay:YES];
                [strongSelf.embeddedView displayIfNeeded];
            }
        );
    }
}

- (BOOL)rebuildEditorWithSource:(NSString *)source
                       fileName:(NSString *)fileName
               themeDisplayName:(NSString *)themeDisplayName
                    previewMode:(BOOL)previewMode
                          error:(NSError **)error {
    NSString *resolvedFileName = fileName.length > 0 ? fileName : @"SemanticInput.h";
    NSURL *scratchDirectoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"syntaxink-objc-xcode-%@", NSUUID.UUID.UUIDString]] isDirectory:YES];
    if (![[NSFileManager defaultManager] createDirectoryAtURL:scratchDirectoryURL withIntermediateDirectories:YES attributes:nil error:error]) {
        return NO;
    }

    NSURL *fileURL = [scratchDirectoryURL URLByAppendingPathComponent:resolvedFileName];
    if (![source writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:error]) {
        return NO;
    }

    Class documentClass = NSClassFromString(@"IDESourceEditor.SourceCodeDocument");
    Class editorClass = NSClassFromString(@"IDESourceEditor.SourceCodeEditor");
    if (documentClass == Nil || editorClass == Nil) {
        if (error != NULL) {
            *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeEditorConstructionFailed, @"Failed to resolve IDESourceEditor classes.");
        }
        return NO;
    }

    @try {
        id document = SIXSend(documentClass, @selector(new));
        if (previewMode || [document respondsToSelector:@selector(setLiveIssuesEnabled:)]) {
            [document setValue:@NO forKey:@"liveIssuesEnabled"];
        }
        SIXSendVoidObj(document, @selector(setFileURL:), fileURL);

        NSError *readError = nil;
        BOOL readOK = ((BOOL (*)(id, SEL, NSURL *, NSString *, NSError **))objc_msgSend)(
            document,
            @selector(readFromURL:ofType:error:),
            fileURL,
            SIXContentTypeIdentifierForFileName(resolvedFileName),
            &readError
        );
        if (readOK == NO) {
            if (error != NULL) {
                *error = readError ?: SIXMakeError(SIXObjCXcodeBridgeErrorCodeEditorConstructionFailed, @"SourceCodeDocument.readFromURL failed.");
            }
            return NO;
        }

        id editor = ((id (*)(id, SEL, NSString *, NSBundle *, id))objc_msgSend)(
            SIXSend(editorClass, @selector(alloc)),
            @selector(initWithNibName:bundle:document:),
            nil,
            nil,
            document
        );
        if (editor == nil) {
            if (error != NULL) {
                *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeEditorConstructionFailed, @"SourceCodeEditor.init returned nil.");
            }
            return NO;
        }

        SIXSendVoidObj(document, @selector(registerDocumentEditor:), editor);
        __unused id editorRootView = SIXSend(editor, @selector(view));
        if ([editor respondsToSelector:@selector(prepareForDocument)]) {
            SIXSendVoid(editor, @selector(prepareForDocument));
        }
        if ([editor respondsToSelector:@selector(viewDidInstall)]) {
            SIXSendVoid(editor, @selector(viewDidInstall));
        }

        id sourceEditorView = SIXSend(editor, @selector(sourceEditorView));
        if (sourceEditorView == nil || [sourceEditorView isKindOfClass:[NSView class]] == NO) {
            if (error != NULL) {
                *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeEditorConstructionFailed, @"SourceCodeEditor.sourceEditorView returned nil.");
            }
            return NO;
        }

        if (self.embeddedView != nil) {
            [self.embeddedView removeFromSuperview];
        }

        self.document = document;
        self.editor = editor;
        self.embeddedView = sourceEditorView;
        self.scratchDirectoryURL = scratchDirectoryURL;
        self.fileURL = fileURL;
        self.themeDisplayName = themeDisplayName;

        self.embeddedView.frame = self.bounds;
        self.embeddedView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:self.embeddedView];
        [self applyThemeStyling];
        [self refreshActive:NO];
        return YES;
    } @catch (NSException *exception) {
        if (error != NULL) {
            NSString *message = [NSString stringWithFormat:@"Editor construction raised %@: %@", exception.name, exception.reason];
            *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeEditorConstructionFailed, message);
        }
        return NO;
    }
}

- (BOOL)configureWithSource:(NSString *)source
                   fileName:(NSString *)fileName
           themeDisplayName:(NSString *)themeDisplayName
                previewMode:(BOOL)previewMode
                      error:(NSError **)error {
    NSString *resolvedFileName = fileName.length > 0 ? fileName : @"SemanticInput.h";
    BOOL shouldRebuild = self.document == nil || self.fileURL == nil || ![self.fileURL.lastPathComponent isEqualToString:resolvedFileName];
    if (shouldRebuild) {
        return [self rebuildEditorWithSource:source fileName:resolvedFileName themeDisplayName:themeDisplayName previewMode:previewMode error:error];
    }

    if (![source writeToURL:self.fileURL atomically:YES encoding:NSUTF8StringEncoding error:error]) {
        return NO;
    }

    @try {
        if (themeDisplayName.length > 0 && ![themeDisplayName isEqualToString:self.themeDisplayName]) {
            self.themeDisplayName = themeDisplayName;
        }

        NSError *readError = nil;
        if ([self.document respondsToSelector:@selector(replaceTextWithContentsOfURL:error:)]) {
            BOOL replaceOK = ((BOOL (*)(id, SEL, NSURL *, NSError **))objc_msgSend)(self.document, @selector(replaceTextWithContentsOfURL:error:), self.fileURL, &readError);
            if (replaceOK == NO && error != NULL) {
                *error = readError ?: SIXMakeError(SIXObjCXcodeBridgeErrorCodeUpdateFailed, @"SourceCodeDocument.replaceTextWithContentsOfURL failed.");
                return NO;
            }
        } else {
            BOOL readOK = ((BOOL (*)(id, SEL, NSURL *, NSString *, NSError **))objc_msgSend)(
                self.document,
                @selector(readFromURL:ofType:error:),
                self.fileURL,
                SIXContentTypeIdentifierForFileName(resolvedFileName),
                &readError
            );
            if (readOK == NO && error != NULL) {
                *error = readError ?: SIXMakeError(SIXObjCXcodeBridgeErrorCodeUpdateFailed, @"SourceCodeDocument.readFromURL failed during update.");
                return NO;
            }
        }

        [self applyThemeStyling];
        [self refreshActive:NO];
        return YES;
    } @catch (NSException *exception) {
        if (error != NULL) {
            NSString *message = [NSString stringWithFormat:@"Editor update raised %@: %@", exception.name, exception.reason];
            *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeUpdateFailed, message);
        }
        return NO;
    }
}

@end

@implementation SIXObjCXcodeBridge

+ (BOOL)installRuntimeManifestData:(NSData *)data error:(NSError **)error {
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        if (error != NULL && *error == nil) {
            *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeInvalidManifest, @"Manifest root must be a dictionary.");
        }
        return NO;
    }

    NSArray<NSDictionary<NSString *, id> *> *frameworks = ((NSDictionary *)jsonObject)[@"frameworks"];
    if (![frameworks isKindOfClass:[NSArray class]] || frameworks.count == 0) {
        if (error != NULL) {
            *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeInvalidManifest, @"Manifest.frameworks must be a non-empty array.");
        }
        return NO;
    }

    for (id candidate in frameworks) {
        if (![candidate isKindOfClass:[NSDictionary class]] || [candidate[@"path"] isKindOfClass:[NSString class]] == NO) {
            if (error != NULL) {
                *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeInvalidManifest, @"Each framework entry must contain a string path.");
            }
            return NO;
        }
    }

    if (SIXProcessIsRunningUnderXCTest()) {
        NSMutableArray<NSDictionary<NSString *, id> *> *filteredFrameworks = [NSMutableArray array];
        for (NSDictionary<NSString *, id> *entry in frameworks) {
            NSString *path = entry[@"path"];
            if (SIXIsTestFamilyReference(path)) {
                continue;
            }
            [filteredFrameworks addObject:entry];
        }
        frameworks = filteredFrameworks;
    }

    @synchronized(self) {
        SIXRuntimeManifestFrameworks = [frameworks copy];
    }
    return YES;
}

+ (BOOL)ensureRuntimeInitialized:(NSError **)error {
    @synchronized(self) {
        if (SIXIDEIsInitialized) {
            return YES;
        }
        if (SIXRuntimeManifestFrameworks.count == 0) {
            if (error != NULL) {
                *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeManifestNotInstalled, @"Runtime manifest must be installed before using the Xcode bridge.");
            }
            return NO;
        }

        NSMutableArray<NSDictionary<NSString *, id> *> *pending = [SIXRuntimeManifestFrameworks mutableCopy];
        NSError *lastLoadError = nil;
        while (pending.count > 0) {
            NSMutableArray<NSDictionary<NSString *, id> *> *failed = [NSMutableArray array];
            BOOL madeProgress = NO;

            for (NSDictionary<NSString *, id> *entry in pending) {
                NSString *path = entry[@"path"];
                NSError *loadError = nil;
                if ([self loadFrameworkAtPath:path error:&loadError]) {
                    madeProgress = YES;
                } else {
                    lastLoadError = loadError;
                    [failed addObject:entry];
                }
            }

            if (!madeProgress) {
                if (error != NULL) {
                    *error = lastLoadError ?: SIXMakeError(SIXObjCXcodeBridgeErrorCodeFrameworkLoadFailed, @"Failed to resolve Xcode framework dependency chain.");
                }
                return NO;
            }

            pending = failed;
        }

        SIXIDESetSafeFn setSafe = (SIXIDESetSafeFn)dlsym(RTLD_DEFAULT, "IDESetSafeToLoadDeveloperSystemFrameworks");
        if (setSafe != NULL) {
            setSafe(YES);
        }

        SIXIDEInitializeFn initialize = (SIXIDEInitializeFn)dlsym(RTLD_DEFAULT, "IDEInitialize");
        if (initialize == NULL) {
            if (error != NULL) {
                *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeIDEInitializationFailed, @"IDEInitialize symbol was not found.");
            }
            return NO;
        }

        NSError *initializationError = nil;
        BOOL initializeOK = initialize(0, &initializationError);
        if (initializeOK == NO) {
            if (error != NULL) {
                *error = initializationError ?: SIXMakeError(SIXObjCXcodeBridgeErrorCodeIDEInitializationFailed, @"IDEInitialize failed.");
            }
            return NO;
        }

        SIXIDEIsInitialized = YES;
        return YES;
    }
}

+ (BOOL)loadFrameworkAtPath:(NSString *)path error:(NSError **)error {
    return SIXLoadFrameworkAtPath(path, error);
}

+ (NSView *)makeEditorHostViewWithSource:(NSString *)source
                                fileName:(NSString *)fileName
                        themeDisplayName:(NSString *)themeDisplayName
                             previewMode:(BOOL)previewMode
                                   error:(NSError **)error {
    if (![self ensureRuntimeInitialized:error]) {
        return nil;
    }

    [NSApplication sharedApplication];

    // Runtime uses document -> editor -> IDESourceEditorView. We do not instantiate a bare
    // SourceEditorView on the main path; previewMode only disables editor-side diagnostics.
    SIXObjCXcodeEditorHostView *hostView = [[SIXObjCXcodeEditorHostView alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)];
    if (![hostView configureWithSource:source fileName:fileName themeDisplayName:themeDisplayName previewMode:previewMode error:error]) {
        return nil;
    }
    return hostView;
}

+ (BOOL)updateEditorHostView:(NSView *)view
                      source:(NSString *)source
                    fileName:(NSString *)fileName
            themeDisplayName:(NSString *)themeDisplayName
                 previewMode:(BOOL)previewMode
                       error:(NSError **)error {
    if ([view isKindOfClass:[SIXObjCXcodeEditorHostView class]] == NO) {
        if (error != NULL) {
            *error = SIXMakeError(SIXObjCXcodeBridgeErrorCodeUpdateFailed, @"Expected SIXObjCXcodeEditorHostView.");
        }
        return NO;
    }
    return [(SIXObjCXcodeEditorHostView *)view configureWithSource:source fileName:fileName themeDisplayName:themeDisplayName previewMode:previewMode error:error];
}

+ (void)refreshEditorHostView:(NSView *)view active:(BOOL)active {
    if ([view isKindOfClass:[SIXObjCXcodeEditorHostView class]]) {
        [(SIXObjCXcodeEditorHostView *)view refreshActive:active];
    }
}

@end
