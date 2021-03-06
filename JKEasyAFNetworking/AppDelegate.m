//
//  AppDelegate.m
//  JKEasyAFNetworking
//
//  Created by Jayesh Kawli on 9/7/14.
//  Copyright (c) 2014 Jayesh Kawli. All rights reserved.
//

#import <RLMRealm.h>
#import <RLMMigration.h>
#import "AppDelegate.h"
#import "JKNetworkingRequest.h"
#import "JKUserDefaultsOperations.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Set up default realm for app
    if(![JKUserDefaultsOperations getObjectFromDefaultForKey:@"defaultWorkspace"]) {
        [JKUserDefaultsOperations setObjectInDefaultForValue:@"default" andKey:@"defaultWorkspace"];
    }
    if(![JKUserDefaultsOperations getObjectFromDefaultForKey:@"toSaveRequests"]) {
        [JKUserDefaultsOperations setObjectInDefaultForValue:@(YES) andKey:@"toSaveRequests"];
    }
    if(![JKUserDefaultsOperations getObjectFromDefaultForKey:@"maxHistory"]) {
        [JKUserDefaultsOperations setObjectInDefaultForValue:@(100) andKey:@"maxHistory"];
    }
    
//    NSArray* tempArray = @[@"jayesh",@"kawli",@"manali",@"raut",@"archana",@"raur"];
  //  NSArray* modifiedArray = [tempArray subarrayWithRange:NSMakeRange(0, 2)];

    
    //[self performDatabaseMigration];
    return YES;
}

-(void)performDatabaseMigration {
    [RLMRealm setSchemaVersion:1 withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {

        if (oldSchemaVersion < 1) {

            [migration enumerateObjects:JKNetworkingRequest.className
                                  block:^(RLMObject *oldObject, RLMObject *newObject) {
                                      //newObject[@"headers"] = @"";
            }];
        }
       /* if(oldSchemaVersion < 2) {
            [migration enumerateObjects:JKNetworkingRequest.className
                                  block:^(RLMObject *oldObject, RLMObject *newObject) {
                                      newObject[@"serverResponseMessage"] = @"";
                                  }];
        }
        
        if(oldSchemaVersion < 3) {
            [migration enumerateObjects:JKNetworkingRequest.className
                                  block:^(RLMObject *oldObject, RLMObject *newObject) {
                                      newObject[@"executionTime"] = @"";
                                  }];
        }
        
        if(oldSchemaVersion < 4) {
            [migration enumerateObjects:JKNetworkingRequest.className
                                  block:^(RLMObject *oldObject, RLMObject *newObject) {
                                      newObject[@"isHMACRequest"] = @(NO);
                                  }];
        }*/
        
    }];
    
    
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    [[NSUserDefaults standardUserDefaults]synchronize];
}

@end
