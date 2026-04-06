#if DEBUG && os(macOS)
import SwiftUI

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

@implementation SYNGreeter

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self != nil) {
        _name = [name copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SYN-%@", self.name];
}

@end
"""

#Preview("Objective-C Header") {
    ObjCSyntaxHighlighterView(
        source: objcHeaderSample,
        fileKind: .header,
        theme: .default,
        fileName: "SYNGreeter.h"
    )
    .frame(width: 1000, height: 700)
}

#Preview("Objective-C Implementation") {
    ObjCSyntaxHighlighterView(
        source: objcImplementationSample,
        fileKind: .implementation,
        theme: .defaultDark,
        fileName: "SYNGreeter.m"
    )
    .frame(width: 1000, height: 700)
}
#endif
