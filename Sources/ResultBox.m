 //
// Created by Nan Yang on 2020/11/26.
//

#import "ResultBox.h"

@interface ResultBox () {
    id _value;
    NSError* _error;
}
@end

@implementation ResultBox

- (instancetype)init {
    return [self initWithValue:nil];
}

- (instancetype)initWithValue:(id)value {
    self = [super init];
    if (self) {
        _value = value;
        _error = nil;
    }
    return self;
}

- (instancetype)initWithError:(NSError*)error {
    self = [super init];
    if (self) {
        _value = nil;
        _error = error;
    }
    return self;
}

- (id)value {
    return _value;
}

- (NSError*)error {
    return _error;
}

- (BOOL)hasError {
    return _error != nil;
}

- (BOOL)hasValue {
    return _error == nil;
}

@end
