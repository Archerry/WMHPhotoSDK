//
// Created by Nan Yang on 2020/11/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ResultBox<ValueType> : NSObject

@property (nonatomic, nullable, readonly) ValueType value;
@property (nonatomic, nullable, readonly) NSError* error;

@property (nonatomic, readonly) BOOL hasValue;
@property (nonatomic, readonly) BOOL hasError;

- (instancetype)init;
- (instancetype)initWithValue:(nullable ValueType)value NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithError:(NSError *)error NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END