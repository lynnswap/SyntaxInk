#if DEBUG && os(macOS)
import SyntaxInk
import SwiftUI

struct ObjCPlayground: View {
    var code: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let syntaxHighlighter = ObjCSyntaxHighlighter(theme: colorScheme == .light ? .default : .defaultDark)
        let attributedString = syntaxHighlighter.highlight(code)

        ScrollView {
            Text(attributedString)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(colorScheme == .light ? Color.xcodeBackgroundDefaultColor : .xcodeBackgroundDefaultDarkColor)
#if os(visionOS)
        .glassBackgroundEffect()
#endif
    }
}

private let objcHeaderSample = """
#import <Foundation/Foundation.h>

/// Greeter interface
@interface SYNGreeter : NSObject <NSCopying>

@property (nonatomic, copy) NSString *name;

- (instancetype)initWithName:(NSString *)name;
@end
"""

private let objcImplementationSample = """
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const SYNBridgeErrorDomain;

typedef NS_ERROR_ENUM(SYNBridgeErrorDomain, SYNBridgeErrorCode) {
    SYNBridgeErrorCodeInvalidInput = 1,
    SYNBridgeErrorCodeHandlerUnavailable = 2,
    SYNBridgeErrorCodeFrameUnavailable = 3,
    SYNBridgeErrorCodeURLCreationFailed = 4,
};

@interface SYNBridgeRuntime : NSObject

+ (nullable NSObject *)objectResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName;
+ (nullable NSNumber *)flagResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName;
+ (BOOL)invokeVoidOnTarget:(NSObject *)target selectorName:(NSString *)selectorName;
+ (BOOL)invokeActionStateOnTarget:(NSObject *)target
                    selectorName:(NSString *)selectorName
                   stateRawValue:(NSInteger)stateRawValue
                 notifyObservers:(BOOL)notifyObservers;
+ (void)frameInfosForWebView:(WKWebView *)webView
           completionHandler:(void (^)(NSArray<WKFrameInfo *> * _Nullable frameInfos))completionHandler;
+ (nullable NSValue *)frameHandleValueForFrameInfo:(WKFrameInfo *)frameInfo;
+ (BOOL)installResourceLoadDelegateOnWebView:(WKWebView *)webView
                                selectorName:(NSString *)selectorName
                                    delegate:(nullable id)delegate;

+ (nullable SYNBridgeRuntime *)makeBridgeWithData:(NSData *)data
                                      classNames:(NSArray<NSString *> *)classNames
                               allocSelectorName:(NSString *)allocSelectorName
                                initSelectorName:(NSString *)initSelectorName;

+ (BOOL)addBufferOnController:(WKUserContentController *)controller
                 selectorName:(NSString *)selectorName
                       buffer:(id)buffer
                         name:(NSString *)name
                 contentWorld:(WKContentWorld *)contentWorld
              isPublicSignature:(BOOL)isPublicSignature;

#if TARGET_OS_OSX
+ (nullable NSWindow *)windowForView:(NSView *)view;
#endif

@end

@implementation SYNBridgeRuntime
@end

NS_ASSUME_NONNULL_END

"""

#Preview("Objective-C Header") {
    ObjCPlayground(code: objcHeaderSample)
}

#Preview("Objective-C Implementation") {
    ObjCPlayground(code: objcImplementationSample)
        .frame(width:1000,height:400)
}
#endif
