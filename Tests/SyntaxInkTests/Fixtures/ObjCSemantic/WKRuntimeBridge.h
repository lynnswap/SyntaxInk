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
};

@interface SYNBridgeRuntime : NSObject
+ (nullable NSObject *)objectResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName;
+ (nullable NSNumber *)flagResultFromTarget:(NSObject *)target selectorName:(NSString *)selectorName;
- (BOOL)invokeVoidOnTarget:(NSObject *)target selectorName:(NSString *)selectorName;
@end

NS_ASSUME_NONNULL_END
