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

@interface DCViewController () <DCCoreDataManagerDelegate,
                                DCUbiquityIdentityManagerDelegate,
                                UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UISegmentedControl *cloudAccessStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *persistentStoreStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *cloudQuestionStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UIButton *activateCoreDataButton;
@property (strong, nonatomic) IBOutlet UIButton *accessDataButton;
@property (strong, nonatomic) DCCoreDataManager *coreDataManager;
@property (assign, nonatomic) DCStorageType storageType;
@property (strong, nonatomic) NSDictionary *persistentStorageTypeDescription;
@property (strong, nonatomic) DCSharedServices *sharedServices;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@property (strong, nonatomic) DCUbiquityIdentityManager *ubiquityIdentityManager;
@property (copy, nonatomic) void (^storageTypeBlock)(DCStorageType type);
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
    self.ubiquityIdentityManager = self.sharedServices.ubiquityIdentityManager;
    [self.ubiquityIdentityManager addDelegate:self];
    [self setupCloudAccessStatusSegmentedControl];
    [self setupPersistentStoreStatusSegmentedControl];
    [self setupCloudQuestionStatusSegmentedControl];
    [self setupActivateCoreDataButton];
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
- (IBAction)activateCoreDataButtonActionWithSender:(id)sender
{
    [self.coreDataManager activate];
}

- (IBAction)accessDataButtonActionWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"accessData" sender:self];
}

#pragma mark - Core Data Manager Delegate
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
didRequestStorageTypeFrom:(NSUInteger)availableStorageTypes
             usingBlock:(void (^)(DCStorageType selectedStorageType))block;
{
    self.storageTypeBlock = block;
    BOOL storageTypeCloudAvailable = (availableStorageTypes & DCStorageTypeCloud);
    if (storageTypeCloudAvailable) {
        NSString *title = @"Select Storage";
        NSString *message = @"Select Local or iCloud storage. This can only be done once, "
        "and any existing data from a local store will not be migrated to iCloud.";
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:title message:message delegate:self
                                  cancelButtonTitle:nil otherButtonTitles:@"Local", @"iCloud", nil];
        [alertView show];
    } else {
        NSString *title = @"Local Storage";
        NSString *message = @"Local storage has been selected since iCloud is not availble";
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:title message:message delegate:self
                                  cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
      didAddStorageType:(DCStorageType)storageType
{
    self.storageType = storageType;
}

- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
     didAllowDataAccess:(BOOL)dataAccessAllowed
{
    self.activateCoreDataButton.enabled = NO;
}

- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
didChangeUbiquitousIdentityTo:(id)ubiquitousIdentity
{
}

#pragma mark - Alert View Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.numberOfButtons == 1) {
        self.storageTypeBlock(DCStorageTypeLocal);
    } else {
        if (buttonIndex == 0) {
            self.storageTypeBlock(DCStorageTypeLocal);
        } else {
            self.storageTypeBlock(DCStorageTypeCloud);
        }
        [self setupCloudQuestionStatusSegmentedControl];
    }
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

- (void)setupCloudQuestionStatusSegmentedControl
{
    NSInteger segmentIndex = ([self.userDefaults.hasAskedForCloudStorage]) ? 1 : 0;
    [self.cloudAccessStatusSegmentedControl setSelectedSegmentIndex:segmentIndex];
}

- (void)setupActivateCoreDataButton
{
    self.activateCoreDataButton.enabled = (self.storageType == DCStorageTypeNone);
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
