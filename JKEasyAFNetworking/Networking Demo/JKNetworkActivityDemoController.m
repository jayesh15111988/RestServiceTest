//
//  JKNetworkActivityDemoController.m
//  JKEasyAFNetworking
//
//  Created by Jayesh Kawli on 9/7/14.
//  Copyright (c) 2014 Jayesh Kawli. All rights reserved.
//

#import <AFNetworking.h>
#import <TPKeyboardAvoidingScrollView.h>
#import "JKNetworkActivityDemoController.h"
#import "JKRequestOptionsProviderUIViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "NSString+Utility.h"
#import "UIView+Utility.h"
#import "JKObjectToStringConvertor.h"
#import "JKRestServiceAppSettingsViewController.h"
#import "JKNetworkActivity.h"
#import "JKNetworkingRequest.h"
#import "JKUserDefaultsOperations.h"
#import <RLMRealm.h>
#import <RLMResults.h>
#import "JKNetworkingWorkspace.h"
#import "JKStoredHistoryOperationUtility.h"
#import "JKNetworkRequestHistoryViewController.h"
#import "JKWorkspacesListViewController.h"
#import "JKURLConstants.h"
#import "JKNetworkingResponseLargeDisplayViewController.h"

#define animationTimeframe 0.5

@interface JKNetworkActivityDemoController ()

@property(weak, nonatomic) IBOutlet UITextField *inputURLField;
@property(weak, nonatomic) IBOutlet UISegmentedControl *inputURLScheme;
@property(weak, nonatomic) IBOutlet UISegmentedControl *requestType;
@property(weak, nonatomic) IBOutlet UITextView *inputDataToSend;
@property(weak, nonatomic) IBOutlet UITextView *serverResponse;
@property(weak, nonatomic) IBOutlet UITextView *inputGetParameters;
@property(weak, nonatomic) IBOutlet UIView *errorView;
@property(weak, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property(weak, nonatomic) IBOutlet UILabel *executionTime;
@property(strong, nonatomic) NSDate *requestSendTime;
@property(weak, nonatomic) IBOutlet UITextField *authorizationHeader;
@property(strong, nonatomic) UIPasteboard* generalPasteboard;
@property (strong, nonatomic) NSDateFormatter* formatter;

@property (weak, nonatomic) IBOutlet UIButton *currentWorkspaceLabel;

@property (strong, nonatomic) NSString* headersToSend;
@property (assign, nonatomic) BOOL isHMACRequest;
@property (strong, nonatomic) JKRequestOptionsProviderUIViewController* networkRequestParametersProvider;
@property (strong, nonatomic) JKRestServiceAppSettingsViewController* settingsViewController;
@property (strong, nonatomic) JKWorkspacesListViewController* workSpaceList;
@property (strong, nonatomic) JKNetworkRequestHistoryViewController* requestHistory;
@property (strong, nonatomic) JKNetworkingResponseLargeDisplayViewController* largeDisplayForServerResponse;
@property(weak, nonatomic)
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *mainScrollView;


- (IBAction)resetButtonPressed:(id)sender;
- (IBAction)sendAPIRequestButtonPressed:(id)sender;
- (IBAction)errorOkButtonPressed:(id)sender;


@end

@implementation JKNetworkActivityDemoController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.formatter = [NSDateFormatter new];
    [self.formatter setDateFormat:@"EEEE MMMM d, YYYY hh:mm a"];
    self.headersToSend = @"";
    [JKStoredHistoryOperationUtility createDefaultWorkSpace];
    
    
    
    [self.currentWorkspaceLabel setTitle:[NSString stringWithFormat:@"Workspace : %@",[JKUserDefaultsOperations getObjectFromDefaultForKey:@"defaultWorkspace"]] forState:UIControlStateNormal];

    [self hideErrorViewWithAnimationDuration:0];
    self.networkRequestParametersProvider = [[JKRequestOptionsProviderUIViewController alloc] initWithNibName:@"JKRequestOptionsProviderUIViewController" bundle:nil];
    self.settingsViewController = [[JKRestServiceAppSettingsViewController alloc] initWithNibName:@"JKRestServiceAppSettingsViewController" bundle:nil];
    __weak typeof(self) weakSelf = self;
    self.settingsViewController.dismissViewButtonAction = ^() {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf dismissPopupViewControllerWithanimationType:MJPopupViewAnimationSlideTopTop];
    };
    
    self.networkRequestParametersProvider.dismissViewButtonAction = ^(BOOL isOkAction, NSArray* inputKeyValuePairCollection, BOOL isHMACRequest){
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.isHMACRequest = isHMACRequest;
        if(inputKeyValuePairCollection) {
            
            strongSelf.inputGetParameters.text = [NSString stringWithFormat:@"%@", [JKObjectToStringConvertor jsonStringWithPrettyPrintWithObject:[strongSelf getKeyedDictionaryFromArray:inputKeyValuePairCollection[GET]]]];
            strongSelf.inputDataToSend.text = [NSString stringWithFormat:@"%@",[JKObjectToStringConvertor jsonStringWithPrettyPrintWithObject:[strongSelf getKeyedDictionaryFromArray:inputKeyValuePairCollection[POST]]]];
            strongSelf.headersToSend = [NSString stringWithFormat:@"%@",[JKObjectToStringConvertor jsonStringWithPrettyPrintWithObject:[strongSelf getKeyedDictionaryFromArray:inputKeyValuePairCollection[HEADER]]]];
        }
        [strongSelf dismissPopupViewControllerWithanimationType:MJPopupViewAnimationSlideTopTop];
    };
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (IBAction)resetButtonPressed:(id)sender {
    
    //Remove all previous entries from key-value pair array
    [self.networkRequestParametersProvider initializeKeyValueHolderArray];
    //Remove any stale header values in the variable
    self.headersToSend = @"";
    //Recursively reset all input fields in the the given view
    [self.view resetViewHierarchy];
}

- (IBAction)sendAPIRequestButtonPressed:(UIButton*)sender {

    
    NSError *error = nil;
    self.requestSendTime = [NSDate date];
    NSDictionary* inputPOSTData = nil;
    NSDictionary* inputGETParameters = nil;
 
    if ([self.inputDataToSend.text length]) {
        inputPOSTData = [self.inputDataToSend.text convertJSONStringToDictionaryWithErrorObject:&error];
    }
    if ([self.inputGetParameters.text length]) {
        inputGETParameters = [self.inputGetParameters.text convertJSONStringToDictionaryWithErrorObject:&error];
    }

    NSString* errorMessage = @"";
    
    if (![self.inputURLField.text isURLValid]) {
        errorMessage = @"Please input the valid URL in given field";
    }
    
    if(error != nil) {
        errorMessage = [errorMessage stringByAppendingString:@"\n Please enter valid values of GET/POST parameters in the given fields. E.g. Input parameters strictly follow standard JavaScript array and dictionary notations"];
    }
    
    if(errorMessage.length) {
        [self showErrorViewWithMessage:errorMessage
                  andAnimationDuration:animationTimeframe];
        return;
    }

    // We will check if user had already entered Auth token in the field - If
    // not, we will use the default ones setup
    // Through #defines
    [self disableButton:sender];
    JKNetworkActivity *newAPIRequest = [[JKNetworkActivity alloc]
                 initWithData:inputPOSTData];
    
   

    
    NSString* authorizationHeaderValue = self.authorizationHeader.text.length ? self.authorizationHeader.text
    : [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Authorization"];
    
    NSError* headerParamersConversionError = nil;
    
    NSMutableDictionary* mutableHeaderFields = [[self.headersToSend convertJSONStringToDictionaryWithErrorObject:&headerParamersConversionError] mutableCopy];
    [mutableHeaderFields setObject:authorizationHeaderValue forKey:@"Authorization"];
    
    [newAPIRequest
        communicateWithServerWithMethod:self.requestType.selectedSegmentIndex
        andHeaderFields:mutableHeaderFields
        andPathToAPI:self.inputURLField.text
        andParameters:inputGETParameters
        completion:^(id successResponse) {

            
            [self enableButton:sender];
            BOOL isRequestReallySuccessfull = NO;
            if([successResponse isKindOfClass:[NSDictionary class]]) {
                if([successResponse objectForKey:@"success"]) {
                    isRequestReallySuccessfull = [successResponse[@"success"] boolValue];
                }
                else {
                    isRequestReallySuccessfull = YES;
                }
            }
            
            [self showResponseWithMessage:successResponse
                 andIsSuccessfullResponse:isRequestReallySuccessfull];
            [self storeRequestInDataBaseWithSuccessValue:isRequestReallySuccessfull];
        }
        failure:^(NSError *errorResponse) {

            [self enableButton:sender];
            [self showResponseWithMessage:[errorResponse localizedDescription]
                 andIsSuccessfullResponse:NO];
            [self showErrorViewWithMessage:@"Error Occurred in processing the "
                                           @"request. Please try again with "
                                           @"valid URL, Auth token and "
                                           @"parameters"
                      andAnimationDuration:animationTimeframe];
            [self storeRequestInDataBaseWithSuccessValue:NO];
        }];
}


-(void)disableButton:(UIButton*)inputButton {
    inputButton.userInteractionEnabled = NO;
    inputButton.alpha = 0.5;
    [self.activityIndicatorView startAnimating];
}

-(void)enableButton:(UIButton*)inputButton {
    inputButton.userInteractionEnabled = YES;
    inputButton.alpha = 1.0;
    [self.activityIndicatorView stopAnimating];
}

-(void)storeRequestInDataBaseWithSuccessValue:(BOOL)isRequestSuccessfull {
    
    BOOL toSaveRequestInHistory = [[JKUserDefaultsOperations getObjectFromDefaultForKey:@"toSaveRequests"] boolValue];
    
    
    NSString* currentWorkspace = [JKUserDefaultsOperations getObjectFromDefaultForKey:@"defaultWorkspace"];
    
    if(toSaveRequestInHistory) {
        JKNetworkingRequest* newAPIRequest = [JKNetworkingRequest new];
        newAPIRequest.parentWorkspaceName = currentWorkspace;
        newAPIRequest.getParameters = self.inputGetParameters.text? : @"";
        newAPIRequest.postParameters = self.inputDataToSend.text? : @"";
        newAPIRequest.authHeaderValue = self.authorizationHeader.text? : @"";
        newAPIRequest.requestMethodType = self.requestType.selectedSegmentIndex;
        newAPIRequest.remoteURL = self.inputURLField.text;
        newAPIRequest.headers = self.headersToSend;
        newAPIRequest.dateOfRequestCreation = [self.formatter stringFromDate:[NSDate date]];
        newAPIRequest.timestampForRequestCreation = [[NSDate date]timeIntervalSince1970];
        newAPIRequest.isRequestSuccessfull = isRequestSuccessfull;
        newAPIRequest.requestIdentifier = [JKStoredHistoryOperationUtility generateRandomStringWithLength:7];
        newAPIRequest.serverResponseMessage = self.serverResponse.text;
        newAPIRequest.executionTime = self.executionTime.text;
        newAPIRequest.isHMACRequest = self.isHMACRequest;

        JKNetworkingWorkspace* workspace = [[JKNetworkingWorkspace objectsWhere:[NSString stringWithFormat:@"workSpaceName = '%@'",currentWorkspace]] firstObject];
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [workspace.requests addObject:newAPIRequest];
        [realm commitWriteTransaction];
    }
}

- (void)showResponseWithMessage:(id)responseMessage
       andIsSuccessfullResponse:(BOOL)isRequestSuccessfull {
    NSDate *requestCompletionTime;
    NSTimeInterval executionTime;
    //Reset headers as soon as request is finished
    self.headersToSend = @"";
    requestCompletionTime = [NSDate date];
    executionTime =
        [requestCompletionTime timeIntervalSinceDate:self.requestSendTime];
    self.executionTime.text =
        [NSString stringWithFormat:@"Executed in %.3f Seconds", executionTime];

    self.serverResponse.textColor = isRequestSuccessfull ? [UIColor blackColor] : [UIColor redColor];
    self.serverResponse.text =
        [NSString stringWithFormat:@"%@",
                                   [JKObjectToStringConvertor jsonStringWithPrettyPrintWithObject:responseMessage]];

}


- (IBAction)errorOkButtonPressed:(id)sender {
    [self hideErrorViewWithAnimationDuration:animationTimeframe];
}

- (void)showErrorViewWithMessage:(NSString *)errorMessage
            andAnimationDuration:(CGFloat)animationDuration {

    self.errorView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.errorMessageLabel.text = errorMessage ?: @"No Error Generated";

    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^() {

                         self.errorView.transform =
                             CGAffineTransformMakeScale(1.0, 1.0);
                     }
                     completion:nil];
}

- (void)hideErrorViewWithAnimationDuration:(CGFloat)animationDuration {
    self.errorView.transform = CGAffineTransformMakeScale(1, 1);

    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^() {
                         self.errorView.transform =
                             CGAffineTransformMakeScale(0.001, 0.001);
                     }
                     completion:nil];
}

- (IBAction)addMoreOptionsButtonPressed:(id)sender {
    NSError* getParamersConversionError = nil;
    NSError* postParamersConversionError = nil;
    NSError* headerParamersConversionError = nil;
    
    NSDictionary* getParamertsKeyValueHolderDictionary = @{};
    NSDictionary* postParametersHolderDictionary = @{};
    NSDictionary* headerParametersHolderDictionary = @{};
    
    if(self.inputGetParameters.text.length) {
        getParamertsKeyValueHolderDictionary = [self.inputGetParameters.text convertJSONStringToDictionaryWithErrorObject:&getParamersConversionError];
    }
    
    if(self.inputDataToSend.text.length) {
        postParametersHolderDictionary = [self.inputDataToSend.text convertJSONStringToDictionaryWithErrorObject:&postParamersConversionError];
    }
    
    if(self.headersToSend.length > 0) {
        headerParametersHolderDictionary = [self.headersToSend convertJSONStringToDictionaryWithErrorObject:&headerParamersConversionError];
    }
    
    self.networkRequestParametersProvider.didAddHMACHeaders = self.isHMACRequest;
    if(getParamertsKeyValueHolderDictionary.count || postParametersHolderDictionary.count || headerParametersHolderDictionary.count) {
        [self.networkRequestParametersProvider initializeKeyValueHolderArray];
        [self.networkRequestParametersProvider accumulateKeyValuesInParameterHolder:@[headerParametersHolderDictionary,getParamertsKeyValueHolderDictionary, postParametersHolderDictionary]];
    }
    else {
        self.networkRequestParametersProvider.numberOfRowsInRespectiveSection = [[NSMutableArray alloc] initWithArray:@[@(1),@(1),@(1)]];
    }
    
    [self presentPopupViewController:self.networkRequestParametersProvider animationType:MJPopupViewAnimationSlideTopTop];
}

- (NSDictionary *) getKeyedDictionaryFromArray:(NSArray *)array {
    
    NSDictionary* outputDictionary;
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    for (outputDictionary in array){
        NSString* key = [[outputDictionary allKeys] firstObject];
        [mutableDictionary setObject:outputDictionary[key] forKey:key];
    }
    return mutableDictionary;
}

-(IBAction)settingsButtonPressed:(id)sender {
    [self presentPopupViewController:self.settingsViewController animationType:MJPopupViewAnimationSlideTopTop];
    
}

-(IBAction)copyServerResponseButtonPressed:(id)sender {
    if(!self.generalPasteboard) {
        self.generalPasteboard = [UIPasteboard generalPasteboard];
    }
    [self.generalPasteboard setString:self.serverResponse.text];
    [self showErrorViewWithMessage:@"Response Successfully Copied to clipboard" andAnimationDuration:0.5];
}

- (IBAction)removeWorkspaceButtonPressed:(id)sender {
    [self showWorkSpaceListViewControllerWithRead:NO];
}


- (IBAction)addWorkspaceButtonPressed:(id)sender {
    [self showInputPopupBoxForNewWorkspace];
}

- (IBAction)viewWorkspaceButtonPressed:(id)sender {
    [self showWorkSpaceListViewControllerWithRead:YES];
    
}

-(void)showWorkSpaceListViewControllerWithRead:(BOOL)isReading {
    if(!self.workSpaceList) {
        self.workSpaceList = [[JKWorkspacesListViewController alloc] initWithNibName:@"JKWorkspacesListViewController" bundle:nil];
        __weak typeof(self) weakSelf = self;

        self.workSpaceList.hideWorkSpaceListsBlockSelected = ^(NSString* updatedWorkspaceName) {
            __strong typeof(self) strongSelf = weakSelf;
            if(updatedWorkspaceName) {
                [strongSelf.currentWorkspaceLabel setTitle:[NSString stringWithFormat:@"Workspace : %@",updatedWorkspaceName] forState:UIControlStateNormal];
            }
            [strongSelf dismissPopupViewControllerWithanimationType:MJPopupViewAnimationSlideTopTop];
        };
    }
    self.workSpaceList.isReading = isReading;
    self.workSpaceList.topLabelTitle = isReading? @"List Of Available Workspaces" : @"Swipe or press edit to remove workspace";
    [self presentPopupViewController:self.workSpaceList animationType:MJPopupViewAnimationSlideTopTop];
    
}

-(void)showInputPopupBoxForNewWorkspace {
    /* Ref : http://stackoverflow.com/questions/26074475/uialertview-vs-uialertcontroller-no-keyboard-in-ios-8 */
    UIAlertController *alert= [UIAlertController
                               alertControllerWithTitle:@"Enter New Workspace Name"
                               message:@"Keep it short and sweet"
                               preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action){
        
                                                   UITextField *textField = alert.textFields[0];
                                                   NSString* newWorkspaceName = textField.text;
                                                   //create new workspace with this name
                                                   if(newWorkspaceName.length > 4) {
                                                       [self showErrorViewWithMessage:[JKStoredHistoryOperationUtility createWorkspaceWithName:newWorkspaceName] andAnimationDuration:0.25];
                                                   }
                                                   else {
                                                       [self showErrorViewWithMessage:@"Workspace name must be at least 5 letters long" andAnimationDuration:0.25];
                                                   }
                                                   
                                               }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                       
                                                   }];
    
    [alert addAction:cancel];
    [alert addAction:ok];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Workspace Name";
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)showHistoryForCurrentWorkspace:(id)sender {
    
    if(!self.requestHistory) {
        self.requestHistory = [self.storyboard instantiateViewControllerWithIdentifier:@"requesthistory"];
    }
    
    JKNetworkingWorkspace* currentWorkspaceObject = [[JKNetworkingWorkspace objectsWhere:[NSString stringWithFormat:@"workSpaceName = '%@'",[JKUserDefaultsOperations getObjectFromDefaultForKey:@"defaultWorkspace"]]] firstObject];

    
    if(currentWorkspaceObject.requests.count > 0) {
        self.requestHistory.requestsForCurrentWorkspace = currentWorkspaceObject.requests;
        self.requestHistory.currentWorkspace = currentWorkspaceObject;
        
        __weak typeof(self) weakSelf = self;
        self.requestHistory.pastRequestSelectedAction = ^(JKNetworkingRequest* selectedRequest) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf resetButtonPressed:nil];
            [strongSelf populateInputFieldsWithPreviousRequest:selectedRequest];
        };
        [self presentViewController:self.requestHistory animated:YES completion:nil];
    }
    else {
        [self showErrorViewWithMessage:[NSString stringWithFormat:@"Workspace %@ is Empty. No requests to display", currentWorkspaceObject.workSpaceName] andAnimationDuration:0.2];
    }
}

-(void)populateInputFieldsWithPreviousRequest:(JKNetworkingRequest*)pastRequestObject {
    self.inputURLField.text = pastRequestObject.remoteURL;
    self.authorizationHeader.text = pastRequestObject.authHeaderValue;
    [self.inputURLScheme setSelectedSegmentIndex:1];
    [self.requestType setSelectedSegmentIndex:pastRequestObject.requestMethodType];
    self.inputGetParameters.text = pastRequestObject.getParameters;
    self.inputDataToSend.text = pastRequestObject.postParameters;
    self.headersToSend = pastRequestObject.headers;
    self.serverResponse.text = pastRequestObject.serverResponseMessage;
    self.executionTime.text = pastRequestObject.executionTime;
    self.isHMACRequest = pastRequestObject.isHMACRequest;
    DLog(@"Was This request HMAC? %d",self.isHMACRequest);
    if(pastRequestObject.isRequestSuccessfull) {
        self.serverResponse.textColor = [UIColor blackColor];
    }
    else {
        self.serverResponse.textColor = [UIColor redColor];
    }

}

#pragma mark textView delegate methods
- (void)textViewDidEndEditing:(UITextView *)textView {

    //Stupid bug, causes scroll view content size to increase by significant amount after each edit
    //to UITextField
    if(self.mainScrollView.contentSize.width > self.view.frame.size.width) {
        CGSize sizeWithFixedWidth = CGSizeMake(self.view.frame.size.width, self.mainScrollView.contentSize.height);
        [self.mainScrollView setContentSize:sizeWithFixedWidth];
    }
}

#pragma textField delegate method 
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if(textField == self.inputURLField) {
        self.isHMACRequest = NO;
    }
}


- (IBAction)showFullScreenResponseButtonPressed:(id)sender {
    
    if([self didReceiveValidResponse]) {
        if(!self.largeDisplayForServerResponse) {
        self.largeDisplayForServerResponse = (JKNetworkingResponseLargeDisplayViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"largeresponsedisplay"];
        }
        self.largeDisplayForServerResponse.remoteURL = self.inputURLField.text;
        self.largeDisplayForServerResponse.serverResponse = self.serverResponse.text;
        [self presentViewController:self.largeDisplayForServerResponse animated:YES completion:nil];
    }
    else {
        [self showErrorViewWithMessage:@"Request not valid or no valid response received" andAnimationDuration:0.3];
    }
}

-(BOOL)didReceiveValidResponse {
    return (([self.inputURLField.text isURLValid]) && (![self.serverResponse.text isEqualToString:@"Non-Editable"]));
}


@end
