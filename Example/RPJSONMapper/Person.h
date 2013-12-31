//
// Created by Reynaldo Gonzales on 12/30/13.
// Copyright (c) 2013 Reynaldo Gonzales. All rights reserved.

#import <Foundation/Foundation.h>

@class Car;

@interface Person : NSObject
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, strong) NSString *age;
@property (nonatomic, strong) NSNumber *heightInInches;
@property (nonatomic, strong) NSString *languageKnown;
@property (nonatomic, strong) Car *car;
@end