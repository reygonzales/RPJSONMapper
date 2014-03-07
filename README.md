## Given ##
```Objective-C
@interface Person : NSObject
@property (nonatomic, copy) NSString *givenName;
@property (nonatomic, copy) NSString *familyName;
@property (nonatomic, strong) NSNumber *yearsOld;
@property (nonatomic, strong) NSNumber *heightInInches;
@property (nonatomic, copy) NSString *languageKnown;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *zip;
@property (nonatomic, copy) NSString *ssn;
@property (nonatomic, strong) NSDate *birthDate;
@property (nonatomic, strong) NSDate *startDate;
@end

...

NSDictionary *json = @{
        @"firstName" : @"John",
        @"lastName" : @"Jacob",
        @"age" : @25,
        @"heightInInches" : @68.5,
        @"phoneNumber" : @"415-555-1234",
        @"state" : @"California",
        @"city" : @"Daly City",
        @"zip" : @94015,
        @"socialSecurityNumber" : [NSNull null],
        @"birthDate" : @"11-08-1988",
        @"startDate" : @"Nov 05 2012"
};
```

## Before ##
```Objective-C
Person *person = [Person new];
person.givenName = [json objectForKey:@"firstName"];
person.familyName = [json objectForKey:@"lastName"];
person.yearsOld = [json objectForKey:@"age"];
person.heightInInches = [json objectForKey:@"heightInInches"];
person.phone = [json objectForKey:@"phoneNumber"];
person.state = [json objectForKey:@"state"];
person.city = [json objectForKey:@"city"];
NSNumber *zipNumber = [json objectForKey:@"zip"];
if([zipNumber isKindOfClass:[NSNumber class]]
        person.zip = [zipNumber stringValue];

NSString *socialSecurityNumber = [json objectForKey:@"socialSecurityNumber"];
if([socialSecurityNumber isKindOfClass:[NSString class]])
    person.ssn = socialSecurityNumber;

NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

NSString *birthDateString = [json objectForKey:@"birthDate"];
if([birthDateString isKindOfClass:[NSString class]]) {
    [dateFormatter setDateFormat:@"MM-dd-yyyy"];
    person.birthDate = [dateFormatter dateFromString:birthDateString];
}

NSString *startDateString = [json objectForKey:@"startDate"];
if([startDateString isKindOfClass:[NSString class]]) {
    [dateFormatter setDateFormat:@"MMM dd yyyy"];
    person.startDate = [dateFormatter dateFromString:startDateString];
}
```

## After ##
```Objective-C
Person *person = [Person new];
[[RPJSONMapper sharedInstance] mapJSONValuesFrom:json toInstance:person usingMapping:@{
        @"firstName" : @"givenName",
        @"lastName" : @"familyName",
        @"age" : @"yearsOld",
        @"heightInInches" : @"heightInInches",
        @"phoneNumber" : @"phone",
        @"state" : @"state",
        @"city" : @"city",
        @"zip" : [[RPJSONMapper sharedInstance] boxValueAsNSStringIntoPropertyWithName:@"zip"],
        @"socialSecurityNumber" : @"ssn",
        @"birthDate" : [[RPJSONMapper sharedInstance] boxValueAsNSDateIntoPropertyWithName:@"birthDate" usingDateFormat:@"MM-dd-yyyy"],
        @"startDate" : [[RPJSONMapper sharedInstance] boxValueAsNSDateIntoPropertyWithName:@"startDate" usingDateFormat:@"MMM dd yyyy"]
}];
```

## Explanation ##
The first key-value pair in the mapping dictionary is `@"firstName" : @"givenName"`. This mapping sets the value of `"firstName"` from the JSON dictionary (@"John") into `@property (nonatomic, copy) NSString *givenName` for `person`.

Another key-value pair is `@"zip" : [[RPJSONMapper sharedInstance] boxValueAsNSStringIntoPropertyWithName:@"zip"]`. This mapping retrieves the value of `"zip"` from the JSON dictionary (@94015), gets the string value of it (@"94015") and then sets it into `@property (nonatomic, copy) NSString *zip` for `person`. We box the value as an NSString because we cannot store an NSNumber into an NSString.

The second type of boxing is for NSDates and is demonstrated with the key-value pair `@"birthDate" : [[RPJSONMapper sharedInstance] boxValueAsNSDateIntoPropertyWithName:@"birthDate" usingDateFormat:@"MM-dd-yyyy"]`. This, just like the other two key-value pairs, takes the value of `"birthDate"` from the JSON dictionary (@"11-08-1988"), gets the NSDate value of it using the date format (@"MM-dd-yyyy") and then sets it into `@property (nonatomic, strong) NSDate *birthDate`. The underlying NSDateFormatter is an instance variable of the RPJSONMapper and is accessed only in a @synchronized call (so it is multi-threaded safe).

## But Wait, There's More! ##
### Array mapping ###
```Objective-C
@interface WeatherReport : NSObject
@property (nonatomic, copy) NSString *weatherDescription;
@property (nonatomic, copy) NSNumber *temperature;
@end

...

NSDictionary *json = @{
        @"JanuaryWeatherReport" : @[
                @{
                        @"description" : @"Sunny with a chance of storms",
                        @"temperature" : @98.1
                },
                @{
                        @"description" : @"Hailing and fog",
                        @"temperature" : @70.2
                },
                ...
        ],
        @"FebruaryWeatherReport" : @[...],
        ...
};

WeatherReport *firstReportOfYear = [WeatherReport new];
WeatherReport *secondReportOfYear = [WeatherReport new];

[[RPJSONMapper sharedInstance] mapJSONValuesFrom:json toInstance:firstReportOfYear usingMapping:@{
        @0 : @{ // Get the first element (index: 0) of the array
                @"description" : @"weatherDescription",
                @"temperature" : @"temperature"
        }
};

[[RPJSONMapper sharedInstance] mapJSONValuesFrom:json toInstance:secondReportOfYear usingMapping:@{
        @1 : @{ // Get the second element (index: 1) of the array
                @"description" : @"weatherDescription",
                @"temperature" : @"temperature"
        }
};
```

### Automatic handling for [NSNull null] values ###
```Objective-C
@interface PowerPack : NSObject
@property (nonatomic, copy) NSString *supercharger;
@property (nonatomic, copy) NSString *turbocharger;
@end

...

NSDictionary *json = @{
        @"supercharger" : [NSNull null],
        @"turbocharger" : [NSNull null]
};

PowerPack *mustangPowerPack = [PowerPack new];
[[RPJSONMapper sharedInstance] mapJSONValuesFrom:json toInstance:mustangPowerPack usingMapping:@{
        @"supercharger" : @"supercharger", // No need to wrap setObject:forKey: calls with if statements anymore!
        @"turbocharger" : @"turbocharger"
}];
```

### Automatic boxing ###
```Objective-C
@interface PowerLifter : NSObject
@property (nonatomic, strong) NSNumber *bench;
@property (nonatomic, strong) NSNumber *squat;
@property (nonatomic, strong) NSNumber *deadlift;
@end

...

NSDictionary *json = @{
        @"bench" : @"225",
        @"squat" : @"315",
        @"deadlift" : @"405"
};

PowerLifter *lifter = [PowerLifter new];
[[RPJSONMapper sharedInstance] mapJSONValuesFrom:json toInstance:log usingMapping:@{
        @"bench" : @"bench", // Forgot to write boxValueAsNSNumberIntoPropertyWithName:?
        @"squat" : @"squat", // Don't worry!
        @"deadlift" : @"deadlift" // It's done automatically!
}];
```

### JSON Array Parsing ###
```Objective-C
NSDictionary *json = @{...};

NSArray *jsonArray = @[json, json, json];

// Before
NSMutableArray *people = [NSMutableArray array];
if([jsonArray isKindOfClass:[NSArray class]]) {
     for(NSDictionary *subJSON in jsonArray) {
          Person *person = [Person new];
          [[RPJSONMapper sharedInstance] mapJSONValuesFrom:json toInstance:person usingMapping:@{...}];
          [people addObject:person];
     }
}

// After
people = [[RPJSONMapper sharedInstance] objectsFromJSONArray:jsonArray withInstantiationBlock:^id { return [Person new];} usingMapping:@{...}];
```

### Child JSON Paths ###
```Objective-C
NSDictionary *largeJSON = @{
            @"Animals" : @[
                    @{
                        @"Dog" : @{}
                    },
                    @{
                        @"Cat" : @{
                            @"Babies" : @[
                                    @{},
                                    @{
                                        @"Runt" : @{
                                                @"Name" : @"Bobby",
                                                @"Age" : @"Kitten"
                                        }
                                    }
                                ]
                        }
                    },
                    @{
                        @"Bird" : @{}
                    }
            ]
    };

// Before
id childJSON = [largeJSON objectForKey:@"Animals"];
if([childJSON isKindOfClass:[NSArray class]] && [childJSON count] > 1) {
    childJSON = [childJSON objectAtIndex:1];
    if([childJSON isKindOfClass:[NSDictionary class]] && [childJSON objectForKey:@"Cat"]) {
        childJSON = [childJSON objectForKey:@"Cat"];
        if([childJSON isKindOfClass:[NSDictionary class]] && [childJSON objectForKey:@"Babies"]) {
            childJSON = [childJSON objectForKey:@"Babies"];
            if([childJSON isKindOfClass:[NSArray class]] && [childJSON count] > 1) {
                childJSON = [childJSON objectAtIndex:1];
            }
        }
    }
}

// After
childJSON = [[RPJSONMapper sharedInstance] childJSONInJSON:largeJSON usingPath:@[@"Animals", @1, @"Cat", @"Babies", @1]];
```

### One multi-threaded safe NSDateFormatter per sharedInstance ###
NSDateFormatters take a long time to instantiate and thus we want to be careful with how many we have

## Requirements ##
* [ARC](http://en.wikipedia.org/wiki/Automatic_Reference_Counting)
* Objects must be [KVC Compliant](https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueCoding/Articles/Compliant.html#//apple_ref/doc/uid/20002172-BAJEAIEE)

## Install ##
* Use [CocoaPods](http://cocoapods.org)

Or

* Copy files in RPJSONMapper to your project
