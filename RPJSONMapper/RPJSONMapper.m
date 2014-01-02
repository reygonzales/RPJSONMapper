// Created by reynaldo on 12/30/13.


#import "RPJSONMapper.h"
#import "RPBoxSpecification.h"

@interface RPJSONMapper()
@property (atomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation RPJSONMapper

+ (instancetype)sharedInstance {
    // Why a shared instance? Why not make every method static?
    // Because we need one instance variable: dateFormatter
    // Why not instantiate a new dateFormatter whenever we need it?
    // Because instantiating dateFormatters take a lot time

    static dispatch_once_t once;
    static RPJSONMapper *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.dateFormatter = [[NSDateFormatter alloc] init];
        sharedInstance.shouldSuppressWarnings = NO;
    });

    return sharedInstance;
}

- (void)mapJSONValuesFrom:(id)json
               toInstance:(id)instance
             usingMapping:(NSDictionary *)mapping {
    for(id mappingKey in [mapping allKeys]) {
        id mappingValue = [mapping objectForKey:mappingKey];
        id jsonValue;

        if([json isKindOfClass:[NSArray class]] && [mappingKey isKindOfClass:[NSNumber class]] && [json count] > [mappingKey unsignedIntegerValue]) {
            jsonValue = [json objectAtIndex:[mappingKey unsignedIntegerValue]];
        } else if([json isKindOfClass:[NSDictionary class]]) {
            jsonValue = [json objectForKey:mappingKey];
        } else {
            jsonValue = nil;
        }

        // If the developer entered a valid mapping, then mappingKey may be of these types
        //  * NSString
        //      * A JSON key
        //  * NSNumber
        //      * An array index
        //
        // And mappingValue may be of these types
        //  * NSString
        //      * A property name
        //  * NSDictionary
        //      * Sub-mapping
        //  * RPBoxSpecification
        //      * A block wrapper that implements custom type boxing

        if(jsonValue == [NSNull null])
            continue;

        if(mappingValue) {
            [self mapJSONValue:jsonValue withMapping:mappingValue toInstance:instance];
        } else {
            [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid mapping (%@)", [mapping description]]];
        }
    }
}

#pragma mark - Boxing

- (RPBoxSpecification *)boxValueAsNSStringIntoPropertyWithName:(NSString *)propertyName {
    return [RPBoxSpecification boxValueIntoPropertyWithName:propertyName
                                                 usingBlock:^id(id jsonValue) {
                                                     if([jsonValue isKindOfClass:[NSNumber class]])
                                                         return [((NSNumber *) jsonValue) stringValue];
                                                     else if([jsonValue isKindOfClass:[NSString class]]) {
                                                         [self log:[NSString stringWithFormat:@"RPJSONMapper Warning: Unnecessary boxing call for property (%@) with value (%@)", propertyName, jsonValue]];
                                                         return jsonValue;
                                                     }
                                                     return @"";
                                                 }];
}

- (RPBoxSpecification *)boxValueAsNSNumberIntoPropertyWithName:(NSString *)propertyName {
    return [RPBoxSpecification boxValueIntoPropertyWithName:propertyName
                                                 usingBlock:^id(id jsonValue) {
                                                     if([jsonValue isKindOfClass:[NSString class]])
                                                         return [NSNumber numberWithInteger:[((NSString *) jsonValue) integerValue]];
                                                     else if([jsonValue isKindOfClass:[NSNumber class]]) {
                                                         [self log:[NSString stringWithFormat:@"RPJSONMapper Warning: Unnecessary boxing call for property (%@) with value (%@)", propertyName, jsonValue]];
                                                         return jsonValue;
                                                     }
                                                     return @0;
                                                 }];
}

- (RPBoxSpecification *)boxValueAsNSDateIntoPropertyWithName:(NSString *)propertyName
                                             usingDateFormat:(NSString *)dateFormat {
    __block __weak RPJSONMapper *blockSafeSelf = self;

    return [RPBoxSpecification boxValueIntoPropertyWithName:propertyName
                                                 usingBlock:^id(id jsonValue) {
                                                     if ([jsonValue isKindOfClass:[NSString class]]) {
                                                         NSDate *date;

                                                         // Why wrap this in a @synchronized call? Because the RPJSONMapper is
                                                         // a singleton that may be accessed on multiple threads. The dateFormatter
                                                         // instance variable should only be set and accessed by one thread
                                                         // at a time.
                                                         @synchronized (blockSafeSelf.dateFormatter) {
                                                             [blockSafeSelf.dateFormatter setDateFormat:dateFormat];
                                                             date = [blockSafeSelf.dateFormatter dateFromString:jsonValue];
                                                         }

                                                         return date;
                                                     }

                                                     return nil;
                                                 }];
}

- (RPBoxSpecification *)boxValueAsNSURLIntoPropertyWithName:(NSString *)propertyName {
    return [RPBoxSpecification boxValueIntoPropertyWithName:propertyName
                                                 usingBlock:^id(id jsonValue) {
                                                     if([jsonValue isKindOfClass:[NSString class]])
                                                         return [NSURL URLWithString:jsonValue];
                                                     return nil;
                                                 }];
}

#pragma mark - Debug Logging

- (void)log:(NSString *)message {
    if(!self.shouldSuppressWarnings)
        NSLog(@"%@", message);
}

#pragma mark - Private Methods

- (void)mapJSONValue:(id)jsonValue
         withMapping:(id)mapping
          toInstance:(id)instance {
    // mapping may be of these types
    //  * NSString
    //      * A property name
    //  * NSDictionary
    //      * Sub-mapping
    //  * RPBoxSpecification
    //      * A block wrapper that implements custom type boxing

    if([mapping isKindOfClass:[NSString class]]) { // If it is a property name
        [self mapJSONValue:jsonValue toKey:mapping forInstance:instance];
    } else if([mapping isKindOfClass:[NSDictionary class]]) { // If it is a sub-mapping
        [self mapJSONValuesFrom:jsonValue toInstance:instance usingMapping:mapping];
    } else if([mapping isKindOfClass:[RPBoxSpecification class]]) {
        [self mapJSONValue:jsonValue withBlock:mapping toInstance:instance];
    } else {
        [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid mapping (%@)", [mapping description]]];
    }
}

- (void)mapJSONValue:(id)jsonValue
           withBlock:(RPBoxSpecification *)blockWrapper
          toInstance:(id)instance {
    PropertyMapperBlock block = blockWrapper.block;

    if(blockWrapper.propertyName.length && blockWrapper.block) {
        id userDefinedValue = block(jsonValue);
        [self mapJSONValue:userDefinedValue toKey:blockWrapper.propertyName forInstance:instance];
    } else {
        [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid RPBoxSpecification (%@)", [blockWrapper description]]];
    }
}

- (void)mapJSONValue:(id)value
               toKey:(NSString *)key
         forInstance:(id)instance {
    NSString *setSelectorString = [NSString stringWithFormat:@"set%@:", [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[key substringToIndex:1] uppercaseString]]];
    SEL setSelector = NSSelectorFromString(setSelectorString);

    if([instance respondsToSelector:setSelector]) {
        [instance setValue:value forKey:key];
    } else {
        [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Instance (%@) does not respond to selector (%@)", [[instance class] description], setSelectorString]];
    }
}

@end