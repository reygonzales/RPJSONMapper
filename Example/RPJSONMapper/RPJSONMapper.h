// Created by reynaldo on 12/30/13.


#import <Foundation/Foundation.h>

@class RPBoxSpecification;

typedef id (^InstantiationBlock)();

@interface RPJSONMapper : NSObject

@property (nonatomic) BOOL shouldSuppressWarnings;

+ (instancetype)sharedInstance;

- (void)mapJSONValuesFrom:(id)json
               toInstance:(id)instance
             usingMapping:(NSDictionary *)mapping;

- (NSArray *)objectsFromJSONArray:(id)json
           withInstantiationBlock:(InstantiationBlock)instantiationBlock
                       andMapping:(NSDictionary *)mapping;

#pragma mark - Boxing

- (RPBoxSpecification *)boxValueAsNSStringIntoPropertyWithName:(NSString *)propertyName;

- (RPBoxSpecification *)boxValueAsNSNumberIntoPropertyWithName:(NSString *)propertyName;

- (RPBoxSpecification *)boxValueAsNSDateIntoPropertyWithName:(NSString *)propertyName usingDateFormat:(NSString *)dateFormat;

- (RPBoxSpecification *)boxValueAsNSURLIntoPropertyWithName:(NSString *)propertyName;

@end