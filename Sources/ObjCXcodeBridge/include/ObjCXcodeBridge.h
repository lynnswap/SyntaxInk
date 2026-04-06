#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const SIXObjCXcodeBridgeErrorDomain;

typedef NS_ERROR_ENUM(SIXObjCXcodeBridgeErrorDomain, SIXObjCXcodeBridgeErrorCode) {
    SIXObjCXcodeBridgeErrorCodeManifestNotInstalled = 1,
    SIXObjCXcodeBridgeErrorCodeInvalidManifest = 2,
    SIXObjCXcodeBridgeErrorCodeFrameworkLoadFailed = 3,
    SIXObjCXcodeBridgeErrorCodeIDEInitializationFailed = 4,
    SIXObjCXcodeBridgeErrorCodeEditorConstructionFailed = 5,
    SIXObjCXcodeBridgeErrorCodeUpdateFailed = 6,
};

@interface SIXObjCXcodeBridge : NSObject

+ (BOOL)installRuntimeManifestData:(NSData *)data error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSView *)makeEditorHostViewWithSource:(NSString *)source
                                         fileName:(NSString *)fileName
                                 themeDisplayName:(NSString *)themeDisplayName
                                      previewMode:(BOOL)previewMode
                                            error:(NSError * _Nullable * _Nullable)error;

+ (BOOL)updateEditorHostView:(NSView *)view
                      source:(NSString *)source
                    fileName:(NSString *)fileName
            themeDisplayName:(NSString *)themeDisplayName
                 previewMode:(BOOL)previewMode
                       error:(NSError * _Nullable * _Nullable)error;

+ (void)refreshEditorHostView:(NSView *)view active:(BOOL)active;

@end

NS_ASSUME_NONNULL_END
