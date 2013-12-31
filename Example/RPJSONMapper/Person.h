//
// Created by Reynaldo Gonzales on 12/30/13.
// Copyright (c) 2013 Reynaldo Gonzales. All rights reserved.

#import <Foundation/Foundation.h>

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