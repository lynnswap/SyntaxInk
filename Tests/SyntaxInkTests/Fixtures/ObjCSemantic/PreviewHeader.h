#import <Foundation/Foundation.h>

/// Greeter interface
@interface SYNGreeter : NSObject <NSCopying>

@property (nonatomic, copy) NSString *name;

- (instancetype)initWithName:(NSString *)name;
@end
