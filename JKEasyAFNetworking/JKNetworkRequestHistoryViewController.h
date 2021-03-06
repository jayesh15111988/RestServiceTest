//
//  JKNetworkRequestHistoryViewController.h
//  JKEasyAFNetworking
//
//  Created by Jayesh Kawli Backup on 12/14/14.
//  Copyright (c) 2014 Jayesh Kawli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RLMArray.h>
#import "JKNetworkingRequest.h"
#import "JKNetworkingWorkspace.h"

@interface JKNetworkRequestHistoryViewController : UIViewController
@property RLMArray<JKNetworkingRequest> *requestsForCurrentWorkspace;
@property (nonatomic, strong) JKNetworkingWorkspace* currentWorkspace;
typedef void (^PastRequestSelectedBlock)(JKNetworkingRequest* selectedRequest);
@property (strong, nonatomic) PastRequestSelectedBlock pastRequestSelectedAction;
@end
