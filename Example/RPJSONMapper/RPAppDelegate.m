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
#import "Car.h"

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
            @"age" : @25,
            @"heightInInches" : @68.5,
            @"languagesKnown" : @[@"Objective-C", @"English"],
            @"car" : @{
                    @"make" : @"Ford",
                    @"model" : @"Mustang"
            }
    };

    Person *john = [Person new];

    [[RPJSONMapper sharedInstance] mapJSONValuesFrom:json
                                          toInstance:john
                                        usingMapping:@{
                                                @"firstName" : @"firstName",
                                                @"age" : [[RPJSONMapper sharedInstance] boxNSNumberAsNSStringIntoPropertyWithName:@"age"],
                                                @"heightInInches" : @"heightInInches",
                                                @"languagesKnown" : @{
                                                        @0 : @"languageKnown"
                                                },
                                                @"car" : [RPBoxSpecification boxValueIntoPropertyWithName:@"car" usingBlock:^id(id jsonValue) {
                                                    Car *mustang = [Car new];
                                                    [[RPJSONMapper sharedInstance] mapJSONValuesFrom:jsonValue
                                                                                          toInstance:mustang
                                                                                        usingMapping:@{
                                                                                                @"make" : @"make",
                                                                                                @"model" : @"model"
                                                                                        }];
                                                    return mustang;
                                                }]
                                        }];

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
