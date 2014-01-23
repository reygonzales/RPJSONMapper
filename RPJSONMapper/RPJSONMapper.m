// Created by reynaldo on 12/30/13.


#import <objc/runtime.h>
#import "RPJSONMapper.h"
#import "RPBoxSpecification.h"

@interface RPJSONMapper()
@property (atomic, strong) NSDateFormatter *dateFormatter;
@property (atomic, strong) NSNumberFormatter *numberFormatter;
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
        sharedInstance.numberFormatter = [[NSNumberFormatter alloc] init];
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

        if(jsonValue == [NSNull null] || jsonValue == nil)
            continue;

        if(mappingValue) {
            [self mapJSONValue:jsonValue withMapping:mappingValue toInstance:instance];
        } else {
            [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid mapping (%@)", [mapping description]]];
        }
    }
}

- (NSArray *)objectsFromJSONArray:(id)json
           withInstantiationBlock:(InstantiationBlock)instantiationBlock
                     usingMapping:(NSDictionary *)mapping {
    if([json isKindOfClass:[NSArray class]]) {
        NSMutableArray *objects = [NSMutableArray array];

        for(id subJSON in json) {
            id object = instantiationBlock();

            if(!object) {
                [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Instantiation block did not return instance for json (%@) and mapping (%@)", json, [mapping description]]];
            } else {
                [self mapJSONValuesFrom:subJSON
                             toInstance:object
                           usingMapping:mapping];
                [objects addObject:object];
            }
        }

        return objects;
    } else {
        [self log:[NSString stringWithFormat:@"RPJSONMapper Warning: Invalid JSON for objectsFromJSONArray:withInstantiationBlock:usingMapping:. JSON must be an array for json (%@) and mapping (%@)", json, [mapping description]]];
        return nil;
    }
}


- (id)childJSONInJSON:(id)json
            usingPath:(NSArray *)path {
    id childJSON = json;

    for(id pathObject in path) {
        if([pathObject isKindOfClass:[NSString class]]) {
            if([childJSON isKindOfClass:[NSDictionary class]]) {
                if([childJSON objectForKey:pathObject]) {
                    childJSON = [childJSON objectForKey:pathObject];
                } else {
                    [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid path object (%@) for json (%@) and path (%@), value not found for key", pathObject, json, path]];
                    return nil;
                }
            } else {
                [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid path object (%@) for json (%@) and path (%@), child JSON not a dictionary", pathObject, json, path]];
                return nil;
            }
        } else if([pathObject isKindOfClass:[NSNumber class]]) {
            if([childJSON isKindOfClass:[NSArray class]]) {
                if([childJSON count] > [pathObject unsignedIntegerValue]) {
                    childJSON = [childJSON objectAtIndex:[pathObject unsignedIntegerValue]];
                } else {
                    [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid path object (%@) for json (%@) and path (%@), index out of bounds", pathObject, json, path]];
                }
            } else {
                [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid path object (%@) for json (%@) and path (%@), child JSON not an array", pathObject, json, path]];
                return nil;
            }
        } else {
            [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid path object (%@) for json (%@) and path (%@)", pathObject, json, path]];
            return nil;
        }
    }
    return childJSON;
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
    __block __weak RPJSONMapper *blockSafeSelf = self;

    return [RPBoxSpecification boxValueIntoPropertyWithName:propertyName
                                                 usingBlock:^id(id jsonValue) {
                                                     if([jsonValue isKindOfClass:[NSString class]]) {
                                                         NSNumber *number;

                                                         @synchronized (blockSafeSelf.numberFormatter) {
                                                             [blockSafeSelf.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                                                             number = [blockSafeSelf.numberFormatter numberFromString:jsonValue];
                                                         }

                                                         return number;
                                                     } else if([jsonValue isKindOfClass:[NSNumber class]]) {
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
        [self mapJSONValue:jsonValue withBoxSpecification:mapping toInstance:instance];
    } else {
        [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid mapping (%@)", [mapping description]]];
    }
}

- (void)mapJSONValue:(id)jsonValue
withBoxSpecification:(RPBoxSpecification *)boxSpecification
          toInstance:(id)instance {
    PropertyMapperBlock block = boxSpecification.block;

    if(boxSpecification.propertyName.length && boxSpecification.block) {
        id userDefinedValue = block(jsonValue);
        [self mapJSONValue:userDefinedValue toKey:boxSpecification.propertyName forInstance:instance];
    } else {
        [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Invalid RPBoxSpecification (%@)", [boxSpecification description]]];
    }
}

- (void)mapJSONValue:(id)value
               toKey:(NSString *)key
         forInstance:(id)instance {
    NSString *setSelectorString = [NSString stringWithFormat:@"set%@:", [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[key substringToIndex:1] uppercaseString]]];
    SEL setSelector = NSSelectorFromString(setSelectorString);

    if([instance respondsToSelector:setSelector]) {
        if([self isValidValue:value forPropertyWithName:key forInstance:instance]) {
            [instance setValue:value forKey:key];
        } else if([self hasBoxMethodForPropertyName:key forInstance:instance selector:&setSelector]) {
            [self attemptAutoBoxForPropertyWithName:key withValue:value forInstance:instance usingSelector:setSelector];
        } else {
            [self log:[NSString stringWithFormat:@"RPJSONMapper Warning: No auto boxing methods found for instance (%@), value (%@), and key (%@)", [[instance class] description], value, key]];
        }
    } else {
        [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Instance (%@) does not respond to selector (%@)", [[instance class] description], setSelectorString]];
    }
}

- (BOOL)isValidValue:(id)value
 forPropertyWithName:(NSString *)key
         forInstance:(id)instance {
    NSString *propertyType = [self propertyTypeGivenPropertyAttributes:[NSString stringWithUTF8String:property_getAttributes(class_getProperty([instance class], [key UTF8String]))]];
    return ([value isKindOfClass:NSClassFromString(propertyType)]);
}

#pragma mark - Private Auto Boxing Methods

- (void)attemptAutoBoxForPropertyWithName:(NSString *)propertyName
                                withValue:(id)value
                              forInstance:(id)instance
                            usingSelector:(SEL)setSelector {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    RPBoxSpecification *boxSpecification = [self performSelector:setSelector withObject:propertyName];
#pragma clang diagnostic pop

    id userDefinedValue = boxSpecification.block(value);

    if(![self isValidValue:userDefinedValue forPropertyWithName:propertyName forInstance:instance]) {
        [self log:[NSString stringWithFormat:@"RPJSONMapper Error: Attempted to auto box and failed for instance (%@), value (%@), and key (%@)", [[instance class] description], value, propertyName]];
    } else {
        [self log:[NSString stringWithFormat:@"RPJSONMapper: Auto boxing value (%@) for key (%@) on instance (%@)", value, propertyName, [[instance class] description]]];
        [instance setValue:userDefinedValue forKey:propertyName];
    }
}

- (BOOL)hasBoxMethodForPropertyName:(NSString *)propertyName
                        forInstance:(id)instance
                           selector:(SEL *)selector {
    NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(class_getProperty([instance class], [propertyName UTF8String]))];
    NSString *propertyType = [self propertyTypeGivenPropertyAttributes:propertyAttributes];
    NSString *selectorString = [NSString stringWithFormat:@"boxValueAs%@IntoPropertyWithName:", propertyType];
    *selector = NSSelectorFromString(selectorString);
    if([self respondsToSelector:*selector])
        return YES;
    return NO;
}

- (NSString *)propertyTypeGivenPropertyAttributes:(NSString *)propertyAttributes {
    // See https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW5 for types
    NSString *secondCharacter = [propertyAttributes substringWithRange:NSMakeRange(1, 1)];
    if([secondCharacter isEqualToString:@"c"]) return @"char";
    else if([secondCharacter isEqualToString:@"d"]) return @"double";
    else if([secondCharacter isEqualToString:@"i"]) return @"int";
    else if([secondCharacter isEqualToString:@"f"]) return @"float";
    else if([secondCharacter isEqualToString:@"l"]) return @"long";
    else if([secondCharacter isEqualToString:@"s"]) return @"short";
    else if([secondCharacter isEqualToString:@"I"]) return @"unsigned";
    else if([secondCharacter isEqualToString:@"{"]) {
        unsigned int length = [propertyAttributes length] - 2;
        unichar buffer[length + 1];
        char structName[length];
        [propertyAttributes getCharacters:buffer range:NSMakeRange(1, length - 2)];
        for(NSInteger i = 0; i < length; ++i) {
            unichar currentCharacter = buffer[i];
            if(currentCharacter != '=') {
                structName[i] = (char) currentCharacter;
            } else {
                structName[i] = '\0';
                break;
            }
        }
        return [NSString stringWithCString:structName encoding:NSUTF8StringEncoding];
    }
    else if([secondCharacter isEqualToString:@"("]) {
        unsigned int length = [propertyAttributes length] - 2;
        unichar buffer[length + 1];
        char unionName[length];
        [propertyAttributes getCharacters:buffer range:NSMakeRange(1, length - 2)];
        for(NSInteger i = 0; i < length; ++i) {
            unichar currentCharacter = buffer[i];
            if(currentCharacter != '=') {
                unionName[i] = (char) currentCharacter;
            } else {
                unionName[i] = '\0';
                break;
            }
        }
        return [NSString stringWithCString:unionName encoding:NSUTF8StringEncoding];
    }
    else if([secondCharacter isEqualToString:@"@"]) {
        NSString *thirdCharacter = [propertyAttributes substringWithRange:NSMakeRange(2, 1)];
        if([thirdCharacter isEqualToString:@","])
            return @"id";

        unsigned int length = [propertyAttributes length] - 3;
        unichar buffer[length + 1];
        char objectName[length];
        [propertyAttributes getCharacters:buffer range:NSMakeRange(3, length)];
        for(NSInteger i = 0; i < length; ++i) {
            unichar currentCharacter = buffer[i];
            if(currentCharacter != '"') {
                objectName[i] = (char) currentCharacter;
            } else {
                objectName[i] = '\0';
                break;
            }
        }

        NSString *propertyName = [NSString stringWithCString:objectName encoding:NSUTF8StringEncoding];

        return propertyName;
    } else {
        [self log:[NSString stringWithFormat:@"RPJSONMapper Warning: Could not find type when attempting to auto box for property with attributes (%@)", propertyAttributes]];
        return @"";
    }
    // Note: I (Rey) am not sure if I should add functionality for autoboxing pointers
}

@end