// Created by reynaldo on 12/30/13.


#import <Foundation/Foundation.h>

@class RPBoxSpecification;

// Mappings can be of the format:
//  @{
//      @"firstName" : @"firstName",
//      @"age" : [RPJSONMapper boxNSNumberAsNSStringIntoPropertyWithName:@"age" fromInstance:person],
//      @"heightInInches" : @"heightInInches",
//      ...
//      @"languagesKnown" : @{
//          @0 : @"languageKnown"
//      },
//      @"car" : [RPBoxSpecification boxValueIntoPropertyWithName:@"floorPlanImages" usingBlock:^id(id jsonValue) {...}]
//  }

// Instances must be KVC compliant

@interface RPJSONMapper : NSObject

@property (nonatomic) BOOL shouldSuppressWarnings;

+ (instancetype)sharedInstance;

- (void)mapJSONValuesFrom:(id)json
               toInstance:(id)instance
             usingMapping:(NSDictionary *)mapping;

#pragma mark - Boxing

- (RPBoxSpecification *)boxNSNumberAsNSStringIntoPropertyWithName:(NSString *)propertyName;

- (RPBoxSpecification *)boxNSStringAsNSDateIntoPropertyWithName:(NSString *)propertyName usingDateFormat:(NSString *)dateFormat;

@end