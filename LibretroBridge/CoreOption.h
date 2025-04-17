//
//  CoreOption.h
//  SwiftRetro
//
//  Created by Matt Hammond on 4/17/25.
//

#import <Foundation/Foundation.h>

#ifndef CoreOption_h
#define CoreOption_h

NS_ASSUME_NONNULL_BEGIN

@interface CoreOption : NSObject

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy, readonly) NSString *descriptionText;
@property (nonatomic, copy, readonly) NSArray<NSString *> *possibleValues;
@property (nonatomic, copy, readonly) NSString *defaultValue;
@property (nonatomic, copy) NSString *currentValue;

- (instancetype)initWithKey:(NSString *)key valueString:(NSString *)valueString;

@end

NS_ASSUME_NONNULL_END

#endif /* CoreOption_h */
