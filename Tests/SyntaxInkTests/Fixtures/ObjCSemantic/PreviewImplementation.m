#import "PreviewHeader.h"

@implementation SYNGreeter

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name stringByAppendingString:@"-preview"];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SYN-%02ld-%@", (long)7, [super description]];
}

@end
