//
//  JKRequestOptionsProviderUIViewController.m
//  JKEasyAFNetworking
//
//  Created by Jayesh Kawli Backup on 12/6/14.
//  Copyright (c) 2014 Jayesh Kawli. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "UITableView+Utility.h"
#import "JKRequestOptionsProviderUIViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "JKOptionSelectorTableViewCell.h"
#import "JKAppearanceProvider.h"
#import "JKHMACHeadersGenerator.h"

static NSString* cellIdentifier = @"optionSelectorCell";
static const NSInteger totalNumberOfSections = 3;
typedef enum { HAS_HMAC_HEADERS = 2, HAS_NO_HMAC_HEADERS } currentHeadersState;

@interface JKRequestOptionsProviderUIViewController ()
@property (strong, nonatomic) NSArray* sectionHeaderNamesCollection;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *tableViewFooter;
@property (strong, nonatomic) IBOutlet UIView *tableViewHeader;
@property (strong, nonatomic) UIButton* addHeadersButton;
@property (strong, nonatomic) UIButton* generateNewHMACHeadersButton;
@property (strong, nonatomic) NSArray* allHMACHeaders;
@property (strong, nonatomic) NSMutableArray* sectionHeaderViewsCollection;
@property (strong, nonatomic) NSMutableArray* numberOfRowsInRespectiveSection;
@property (strong, nonatomic) NSMutableArray* keyValueParametersCollectionInArray;
@end

@implementation JKRequestOptionsProviderUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sectionHeaderViewsCollection = [NSMutableArray new];
    self.numberOfRowsInRespectiveSection = [[NSMutableArray alloc] initWithArray:@[@(1),@(1),@(1)]];
    
    if(!self.keyValueParametersCollectionInArray) {
        [self initializeKeyValueHolderArray];
    }
    
    self.sectionHeaderNamesCollection = @[@"Headers",@"GET Parameters",@"POST Parameters"];
    self.tableView.tableFooterView = self.tableViewFooter;
    UIView* tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 512, 60)];
    UILabel* headerViewTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(90, 10, 350, 35)];
    headerViewTitleLabel.center = tableHeaderView.center;
    [headerViewTitleLabel setText:@"Available Request Parameter Options"];
    [headerViewTitleLabel setBackgroundColor:[JKAppearanceProvider DarkOrangeColor]];
    headerViewTitleLabel.textAlignment = NSTextAlignmentCenter;
    [tableHeaderView addSubview:headerViewTitleLabel];
    self.tableView.tableHeaderView = tableHeaderView;
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

-(void)initializeKeyValueHolderArray {

    if(self.keyValueParametersCollectionInArray){
        [self.keyValueParametersCollectionInArray removeAllObjects];
    }
    else {
        self.keyValueParametersCollectionInArray = [NSMutableArray new];
    }
        NSInteger totalNumberOfSection = totalNumberOfSections;
        while (totalNumberOfSection--) {
            [self.keyValueParametersCollectionInArray addObject:[NSMutableArray new]];
        }
}

#pragma MARK tableView dataSource and delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return totalNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.numberOfRowsInRespectiveSection[section] integerValue];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath  *)indexPath {
    JKOptionSelectorTableViewCell* currentCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(currentCell == nil) {
        [tableView registerNib:[UINib nibWithNibName:@"JKOptionSelectorTableViewCell" bundle:nil] forCellReuseIdentifier:cellIdentifier];
        currentCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }

    NSArray* keyValuePairDetailsForCurrentSection = self.keyValueParametersCollectionInArray[indexPath.section];
    if(indexPath.row < keyValuePairDetailsForCurrentSection.count) {
        NSDictionary* currentKeyValuePairDictionary = keyValuePairDetailsForCurrentSection[indexPath.row];
        currentCell.keyField.text = [currentKeyValuePairDictionary allKeys][0];
        currentCell.valueField.text = [currentKeyValuePairDictionary objectForKey:currentCell.keyField.text];
        currentCell.didAddKeyValuePairToArray = YES;
        currentCell.currentKeyValuePairArrayIndex = indexPath.row;
        DLog(@"%@ - Key %@ - Value and current index %d",currentCell.keyField.text,currentCell.valueField.text,indexPath.row);
    }
    else {
        currentCell.keyField.text = @"";
        currentCell.valueField.text = @"";
        currentCell.didAddKeyValuePairToArray = NO;
    }
    
    __weak typeof(JKOptionSelectorTableViewCell*) weakCellInstance = currentCell;
    currentCell.KeyValueAddedBlock = ^(NSString* parameterKey, NSString* parameterValue) {
        __strong typeof(JKOptionSelectorTableViewCell*) strongCellInstance = weakCellInstance;
        
        if(strongCellInstance.didAddKeyValuePairToArray) {
            [self.keyValueParametersCollectionInArray[indexPath.section] replaceObjectAtIndex:strongCellInstance.currentKeyValuePairArrayIndex withObject:@{parameterKey : parameterValue}];
        }
        else {
            [self.keyValueParametersCollectionInArray[indexPath.section] addObject:@{parameterKey : parameterValue}];
            strongCellInstance.currentKeyValuePairArrayIndex = [self.keyValueParametersCollectionInArray[indexPath.section] count] - 1;
            strongCellInstance.didAddKeyValuePairToArray = YES;
        }
        DLog(@"Current value of key value pair %@",self.keyValueParametersCollectionInArray);
    };
    return currentCell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self getHeaderForSectionWithIndex:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60.0;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    JKOptionSelectorTableViewCell* optionsCell = (JKOptionSelectorTableViewCell*)cell;
    optionsCell.KeyValueAddedBlock = nil;
}

-(UIView*)getHeaderForSectionWithIndex:(NSInteger)sectionNumber {

    
    if (([self.sectionHeaderViewsCollection count] < sectionNumber + 1)) {
        UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 512, 60)];
        [headerView setBackgroundColor:[UIColor whiteColor]];
        UILabel* headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 250, 40)];
        headerTitleLabel.text = self.sectionHeaderNamesCollection[sectionNumber];
        CGFloat titleLabelWidth = [headerTitleLabel.text
                                   boundingRectWithSize:headerTitleLabel.frame.size
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:@{ NSFontAttributeName:headerTitleLabel.font }
                                   context:nil].size.width;
        
        UIButton* addRowButton = [[UIButton alloc] initWithFrame:CGRectMake(20 + titleLabelWidth , 20, 25, 25)];
        [addRowButton setBackgroundImage:[UIImage imageNamed:@"button_plus_green"] forState:UIControlStateNormal];
        addRowButton.tag = sectionNumber;
        
        UIButton* deleteRowButton = [[UIButton alloc] initWithFrame:CGRectMake(addRowButton.center.x + 25 , 20, 25, 25)];
        [deleteRowButton setBackgroundImage:[UIImage imageNamed:@"button_minus_red"] forState:UIControlStateNormal];
        deleteRowButton.tag = sectionNumber;
        
        //If this is a headers section, then add a provision to create and add HMAC headers
        if(sectionNumber == HEADER) {
            UIFont* generalActionButtonFont = [UIFont systemFontOfSize:16];
            self.addHeadersButton = [[UIButton alloc] initWithFrame:CGRectMake(deleteRowButton.center.x + 30, 20, 160, 25)];
            [self.addHeadersButton setTitle:@"Add HMAC Headers" forState:UIControlStateNormal];
            self.addHeadersButton.tag = HAS_NO_HMAC_HEADERS;
            [self.addHeadersButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            self.addHeadersButton.titleLabel.font = generalActionButtonFont;
            [self.addHeadersButton addTarget:self action:@selector(addHMACHeaderButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [headerView addSubview:self.addHeadersButton];
            
            //This button will allow users to generate new HMAC headers for more convenience
            self.generateNewHMACHeadersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.addHeadersButton.frame.origin.x + self.addHeadersButton.frame.size.width , 20, 170, 25)];
            [self.generateNewHMACHeadersButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.generateNewHMACHeadersButton setTitle:@"Create HMAC Headers" forState:UIControlStateNormal];
            self.generateNewHMACHeadersButton.titleLabel.font = generalActionButtonFont;
            self.generateNewHMACHeadersButton.hidden = YES;
            [self.generateNewHMACHeadersButton addTarget:self action:@selector(generateNewHMACHeaders:) forControlEvents:UIControlEventTouchUpInside];
            [headerView addSubview:self.generateNewHMACHeadersButton];
        }
        
        [addRowButton addTarget:self action:@selector(addRowButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [deleteRowButton addTarget:self action:@selector(deleteRowButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:headerTitleLabel];
        [headerView addSubview:addRowButton];
        [headerView addSubview:deleteRowButton];
        [self.sectionHeaderViewsCollection setObject:headerView atIndexedSubscript:sectionNumber];
    }
    return self.sectionHeaderViewsCollection[sectionNumber];
}

- (IBAction)cancelButtonPressed:(id)sender {
    if(self.dismissViewButtonAction) {
        self.dismissViewButtonAction(0, nil);
    }
}

- (IBAction)doneButtonPressed:(id)sender {
    [self.view endEditing:YES];
    if(self.dismissViewButtonAction) {
        self.dismissViewButtonAction(1, self.keyValueParametersCollectionInArray);
    }
}

- (IBAction)addHMACHeaderButtonPressed:(UIButton*)sender {
    
    if(sender.tag == HAS_NO_HMAC_HEADERS){
        if(!self.allHMACHeaders || ![self.allHMACHeaders count]) {
            self.allHMACHeaders = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"HMACHeaders"];
        }
        [_keyValueParametersCollectionInArray[HEADER] addObjectsFromArray:[JKHMACHeadersGenerator getDesiredHMACHeaderFields]];
        [self addRemoveNewRowsToSection:HEADER andNumberOfNewRows:4];
        [sender setTitle:@"Remove Headers" forState:UIControlStateNormal];
        sender.tag = HAS_HMAC_HEADERS;
    } else {
        [self removeUpdateHMACHeaders];
        [sender setTitle:@"Add HMAC Headers" forState:UIControlStateNormal];
        sender.tag = HAS_NO_HMAC_HEADERS;
    }
    self.generateNewHMACHeadersButton.hidden = (sender.tag == HAS_NO_HMAC_HEADERS);
}

- (IBAction)generateNewHMACHeaders:(UIButton*)sender {
    NSArray* newHMACHeaders = [JKHMACHeadersGenerator getDesiredHMACHeaderFields];
    NSArray* currentListOfHeaders = self.keyValueParametersCollectionInArray[HEADER];
    NSMutableArray* temporaryListOfKeyValuePairs = [currentListOfHeaders mutableCopy];
    
    
    __block NSString* currentHeaderKey;
    __block NSInteger indexOfHeaderCurrentHeader;
   [currentListOfHeaders enumerateObjectsUsingBlock:^(NSDictionary* listOfAllKeyValueHeaders, NSUInteger index, BOOL *stop) {
    
       currentHeaderKey = [listOfAllKeyValueHeaders allKeys][0];
       if([_allHMACHeaders containsObject:currentHeaderKey]) {
           indexOfHeaderCurrentHeader = [self.allHMACHeaders indexOfObject:currentHeaderKey];
           
           //Public key virtually remains same each time
           if(indexOfHeaderCurrentHeader != PUBLIC_KEY) {
               [temporaryListOfKeyValuePairs replaceObjectAtIndex:index withObject:newHMACHeaders[indexOfHeaderCurrentHeader]];
           }
       }
   }];
    self.keyValueParametersCollectionInArray[HEADER] = temporaryListOfKeyValuePairs;
    [self.tableView reloadSectionDU:HEADER withRowAnimation:UITableViewRowAnimationNone];
    
}

- (void)removeUpdateHMACHeaders{
    NSMutableArray* listOfAllKeyValueHeaders = [self.keyValueParametersCollectionInArray[HEADER] mutableCopy];
    

    __block NSString* currentKey;
    NSMutableIndexSet *indexSetOfItemsToDelete = [NSMutableIndexSet indexSet];
    
    
    [listOfAllKeyValueHeaders enumerateObjectsUsingBlock:^(NSDictionary* listOfAllKeyValueHeaders, NSUInteger index, BOOL *stop) {
    
        currentKey = [listOfAllKeyValueHeaders allKeys][0];
        if([self.allHMACHeaders containsObject:currentKey]) {
            [indexSetOfItemsToDelete addIndex:index];
        }
    }];
    [listOfAllKeyValueHeaders removeObjectsAtIndexes:indexSetOfItemsToDelete];
    self.keyValueParametersCollectionInArray[HEADER] = listOfAllKeyValueHeaders;
    [self addRemoveNewRowsToSection:HEADER andNumberOfNewRows:-(indexSetOfItemsToDelete.count)];
}

-(IBAction)addRowButtonPressed:(UIButton*)sender {
    [self.view endEditing:YES];
    NSInteger sectionNumberToAddRowsTo = sender.tag;
    [self addRemoveNewRowsToSection:sectionNumberToAddRowsTo andNumberOfNewRows:1];
}

-(void)addRemoveNewRowsToSection:(NSInteger)sectionNumber andNumberOfNewRows:(NSInteger)numberOfAddedRows {
    NSInteger newNumberOfRowsInSection = [self.numberOfRowsInRespectiveSection[sectionNumber] integerValue] + numberOfAddedRows;
    [self.numberOfRowsInRespectiveSection setObject:@(newNumberOfRowsInSection) atIndexedSubscript:sectionNumber];
    [self.tableView reloadSectionDU:sectionNumber withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)deleteRowButtonPressed:(UIButton*)sender {
    [self.view endEditing:YES];
    NSInteger sectionNumberToDeleteRowFrom = sender.tag;
    NSInteger newNumberOfRowsInSection = [self.numberOfRowsInRespectiveSection[sectionNumberToDeleteRowFrom] integerValue] - 1;
    
    if(newNumberOfRowsInSection == 0) {
        [self.keyValueParametersCollectionInArray[sectionNumberToDeleteRowFrom] removeAllObjects];
        [self.tableView reloadSectionDU:sectionNumberToDeleteRowFrom withRowAnimation:UITableViewRowAnimationNone];
        return;
    }

    if(newNumberOfRowsInSection < [self.keyValueParametersCollectionInArray[sectionNumberToDeleteRowFrom] count]) {
        [self.keyValueParametersCollectionInArray[sectionNumberToDeleteRowFrom] removeLastObject];
    }

    [self.numberOfRowsInRespectiveSection setObject:@(newNumberOfRowsInSection) atIndexedSubscript:sectionNumberToDeleteRowFrom];
    [self.tableView reloadSectionDU:sectionNumberToDeleteRowFrom withRowAnimation:UITableViewRowAnimationNone];
}

- (void)accumulateKeyValuesInParameterHolder:(NSArray*)inputParametersHolderArray {
    NSInteger currentIndex = 0;
    for(NSDictionary* individualKeyValueDictionary in inputParametersHolderArray) {
        for(NSString* key in individualKeyValueDictionary) {
            [self.keyValueParametersCollectionInArray[currentIndex] addObject:@{key : individualKeyValueDictionary[key]}];
        }
        currentIndex++;
    }
}

@end
