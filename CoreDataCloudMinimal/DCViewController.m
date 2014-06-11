    //
//  DCViewController.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-05.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCViewController.h"
#import "DCSharedServices.h"
#import "DCCoreDataManager.h"
#import "DCUserDefaults.h"
#import "DCDataTableViewController.h"
#import "DCUbiquityIdentityManager.h"

@interface DCViewController () <DCCoreDataManagerDelegate, DCUbiquityIdentityManagerDelegate>
@property (strong, nonatomic) IBOutlet UISegmentedControl *cloudAccessStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *persistentStoreStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *launchStateStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *persistentStoreSegmentedControl;
@property (strong, nonatomic) IBOutlet UIButton *accessDataButton;
@property (strong, nonatomic) DCCoreDataManager *coreDataManager;
@property (assign, nonatomic) DCStorageType storageType;
@property (assign, nonatomic) NSUInteger availableStorageTypes;
@property (strong, nonatomic) NSDictionary *persistentStorageTypeDescription;
@property (strong, nonatomic) DCSharedServices *sharedServices;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@property (strong, nonatomic) DCUbiquityIdentityManager *ubiquityIdentityManager;
@end

@implementation DCViewController
#pragma mark - View Controller
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sharedServices = [DCSharedServices sharedServices];
    self.coreDataManager = [DCCoreDataManager dataManagerWithModelName:@"Model" delegate:self];
    self.persistentStorageTypeDescription = @{@(DCStorageTypeNone): @"No Persistent Store",
                                              @(DCStorageTypeLocal): @"Local Persistent Store",
                                              @(DCStorageTypeCloud): @"Cloud Persistent Store"};
    self.userDefaults = self.sharedServices.userDefaults;
    self.availableStorageTypes = DCStorageTypeNone;
    self.ubiquityIdentityManager = self.sharedServices.ubiquityIdentityManager;
    [self.ubiquityIdentityManager addDelegate:self];
    [self setupCloudAccessStatusSegmentedControl];
    [self setupPersistentStoreStatusSegmentedControl];
    [self setupLaunchStateStatusSegmentedControl];
    [self setupPersistentStoreSegmentedControl];
    [self setupAccessDataButton];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    UIViewController *viewController = segue.destinationViewController;
    if ([identifier isEqualToString:@"accessData"]) {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        UIViewController *topViewController = [navigationController topViewController];
        DCDataTableViewController *dataTableViewController = (DCDataTableViewController *)topViewController;
        dataTableViewController.dataManager = self.coreDataManager;
    }
}

- (IBAction)unwindActionWithStoryboardSegue:(UIStoryboardSegue *)storyboardSegue
{
}

#pragma mark - User Actions
- (IBAction)persistentStoreSegmentedControlActionWithSender:(id)sender
{
}

- (IBAction)accessDataButtonActionWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"accessData" sender:self];
}

#pragma mark - Core Data Manager Delegate
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
  didRequestStorageType:(DCStorageType *)storageType
       fromStorageTypes:(NSUInteger)availableStorageTypes
{
    self.availableStorageTypes = availableStorageTypes;
    [self setupPersistentStoreSegmentedControl];
    BOOL storageTypeCloudAvailable = (self.availableStorageTypes & DCStorageTypeCloud);
    
}

- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
      didAddStorageType:(DCStorageType)storageType
{
    self.storageType = storageType;
}

- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
     didAllowDataAccess:(BOOL)dataAccessAllowed
{
    
}

#pragma mark - UI Setup Methods
- (void)setupCloudAccessStatusSegmentedControl
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    id ubiquityIdentityToken = [fileManager ubiquityIdentityToken];
    [self.cloudAccessStatusSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    if (ubiquityIdentityToken == nil) {
        [self.cloudAccessStatusSegmentedControl setSelectedSegmentIndex:0];
    } else {
        [self.cloudAccessStatusSegmentedControl setSelectedSegmentIndex:1];
    }
}

- (void)setupPersistentStoreStatusSegmentedControl
{
    [self.persistentStoreStatusSegmentedControl setSelectedSegmentIndex:self.storageType];
}

- (void)setupLaunchStateStatusSegmentedControl
{
}

- (void)setupPersistentStoreSegmentedControl
{
    BOOL storageTypeNoneAvailable = (self.availableStorageTypes & DCStorageTypeNone);
    BOOL storageTypeLocalAvailable = (self.availableStorageTypes & DCStorageTypeLocal);
    BOOL storageTypeCloudAvailable = (self.availableStorageTypes & DCStorageTypeCloud);
    [self.persistentStoreStatusSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    if (storageTypeNoneAvailable) {
        [self.persistentStoreStatusSegmentedControl setSelectedSegmentIndex:0];
    }
    if (storageTypeLocalAvailable) {
        [self.persistentStoreStatusSegmentedControl setSelectedSegmentIndex:1];
    }
    if (storageTypeCloudAvailable) {
        [self.persistentStoreStatusSegmentedControl setSelectedSegmentIndex:2];
    }
}

- (void)setupAccessDataButton
{
}

#pragma mark - Storage Type Property
- (void)setStorageType:(DCStorageType)storageType
{
    _storageType = storageType;
    [self setupPersistentStoreStatusSegmentedControl];
}

#pragma mark - Ubiquity Identity Manager Delegate - Only for Testing!
- (void)ubiquityIdentityManager:(DCUbiquityIdentityManager *)ubiquityIdentityManager
          didChangeFromIdentity:(id<NSObject,NSCopying,NSCoding>)fromIdentity
                     toIdentity:(id<NSObject,NSCopying,NSCoding>)toIdentity
{
    [self setupCloudAccessStatusSegmentedControl];
}
@end
