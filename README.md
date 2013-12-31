RPJSONMapper
============

Given
-----

```Objective-C
@interface Person : NSObject
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, strong) NSNumber *age;
@property (nonatomic, strong) NSNumber *heightInInches;
@property (nonatomic, strong) NSString *languageKnown;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *socialSecurityNumber;
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

Before
------
```Objective-C
Person *person = [Person new];
person.firstName = [json objectForKey:@"firstName"];
person.lastName = [json objectForKey:@"lastName"];
person.age = [json objectForKey:@"age"];
person.heightInInches = [json objectForKey:@"heightInInches"];
person.phoneNumber = [json objectForKey:@"phoneNumber"];
person.state = [json objectForKey:@"state"];
person.city = [json objectForKey:@"city"];
NSNumber *zipNumber = [json objectForKey:@"zip"];
if([zipNumber isKindOfClass:[NSNumber class]]
        person.zip = [zipNumber stringValue];

NSString *socialSecurityNumber = [json objectForKey:@"socialSecurityNumber"];
if([socialSecurityNumber isKindOfClass:[NSString class]])
    person.socialSecurityNumber = socialSecurityNumber;

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

After
-----
```Objective-C
Person *person = [Person new];
[[RPJSONMapper sharedInstance] mapJSONValuesFrom:json toInstance:person usingMapping:@{
        @"firstName" : @"firstName",
        @"lastName" : @"lastName",
        @"age" : @"age",
        @"heightInInches" : @"heightInInches",
        @"phoneNumber" : @"phoneNumber",
        @"state" : @"state",
        @"city" : @"city",
        @"zip" : [[RPJSONMapper sharedInstance] boxValueAsNSStringIntoPropertyWithName:@"zip"],
        @"socialSecurityNumber" : @"socialSecurityNumber",
        @"birthDate" : [[RPJSONMapper sharedInstance] boxValueAsNSDateIntoPropertyWithName:@"birthDate" usingDateFormat:@"MM-dd-yyyy"],
        @"startDate" : [[RPJSONMapper sharedInstance] boxValueAsNSDateIntoPropertyWithName:@"startDate" usingDateFormat:@"MMM dd yyyy"]
}];

```

How it works
------------

```
For all keys in the mapping dictionary
        1. Get the JSON value in the JSON dictionary
        2. If the JSON value is not [NSNull null]
                i. Get the mapping value in the mapping dictionary
                        a. If the mapping value is an NSString, generate a setter and call it with the JSON value
                        b. If the mapping value is an NSDictionary, iterate it as a submapping
                        c. If the mapping value is an RPBoxSpecification, generate a setter and call it with the returned value from the corresponding block and JSON value
```
Why
---
* Less to type and easier to read
* Automatic handling for [NSNull null] values
* One multi-threaded safe NSDateFormatter per sharedInstance
  * NSDateFormatters take a long time to instantiate

Requirements
------------
* ARC
* Objects must be KVC Compliant (https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueCoding/Articles/Compliant.html#//apple_ref/doc/uid/20002172-BAJEAIEE)

Install
-------
* Use CocoaPods

Or

* Copy files in RPJSONMapper to your project
