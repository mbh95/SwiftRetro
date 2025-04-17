//
//  CoreOption.m
//  LibretroBridge
//
//  Created by Matt Hammond on 4/17/25.
//

#import "CoreOption.h"

@implementation CoreOption

- (instancetype)initWithKey:(NSString *)key
                valueString:(NSString *)valueString {
    self = [super init];
    if (self) {
        _key = [key copy];

        // description; default_value|value1|value2|etc.
        NSRange descriptionSeparator = [valueString rangeOfString:@"; "];
        _descriptionText =
            [valueString substringToIndex:descriptionSeparator.location];
        NSString *valuesPart =
            [valueString substringFromIndex:descriptionSeparator.location +
                                            descriptionSeparator.length];
        _possibleValues = [valuesPart componentsSeparatedByString:@"|"];
        _defaultValue =
            _possibleValues.count > 0 ? [_possibleValues[0] copy] : @"";
        _currentValue = [_defaultValue copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString
        stringWithFormat:@"<CoreOption key='%@' desc='%@' possible='%@' "
                         @"default='%@' current='%@'>",
                         self.key, self.descriptionText,
                         [self.possibleValues componentsJoinedByString:@"|"],
                         self.defaultValue, self.currentValue];
}

@end
