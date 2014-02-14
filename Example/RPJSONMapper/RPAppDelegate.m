//
//  RPAppDelegate.m
//  RPJSONMapper
//
//  Created by Reynaldo Gonzales on 12/30/13.
//  Copyright (c) 2013 Reynaldo Gonzales. All rights reserved.
//

#import "RPAppDelegate.h"
#import "RPJSONMapper.h"
#import "Person.h"
#import "RPBoxSpecification.h"

@implementation RPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    // RPJSONMapper Example

    NSDictionary *json = @{
            @"firstName" : @"John",
            @"lastName" : [NSNull null],
            @"age" : @"",
            @"heightInInches" : @68.5,
            @"phoneNumber" : @"415-555-1234",
            @"state" : @"California",
            @"city" : @"Daly City",
            @"zip" : @94015,
            @"socialSecurityNumber" : [NSNull null],
            @"birthDate" : @"11-08-1988",
            @"startDate" : @"Nov 05 2012"
    };

    Person *person = [Person new];
    [[RPJSONMapper sharedInstance] mapJSONValuesFrom:json toInstance:person usingMapping:@{
            @"firstName" : @"FirstName",
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

    NSArray *jsonArray = @[json, json, json];

    NSArray *jsonObjects = [[RPJSONMapper sharedInstance] objectsFromJSONArray:jsonArray
                                                        withInstantiationBlock:^id {
                                                            return [Person new];
                                                        }
                                                                  usingMapping:@{
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

    NSDictionary *childJSON = [[RPJSONMapper sharedInstance] childJSONInJSON:largeJSON usingPath:@[@"Animals", @1, @"Cat", @"Babies", @1]];
    // childJSON = @"Runt" : @{
    //    @"Name" : @"Bobby",
    //    @"Age" : @"Kitten"
    // }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
