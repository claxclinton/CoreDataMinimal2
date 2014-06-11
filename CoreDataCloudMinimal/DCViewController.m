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
@property (assign, nonatomic) BOOL dataAccessAllowed;
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
    [self configureCloudAccessStatusSegmentedControl];
    [self configurePersistentStoreStatusSegmentedControl];
    [self configureCloudQuestionStatusSegmentedControl];
    [self configureActivateCoreDataButton];
    [self configureAccessDataButton];
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
    [self.coreDataManager addPersistentStore];
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
    self.dataAccessAllowed = dataAccessAllowed;
    [self configureAccessDataButton];
}

- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
didChangeUbiquitousIdentityTo:(id)ubiquitousIdentity
requestStorageTypeBlock:(void (^)(DCStorageType selectedStorageType))block
{
    NSString *title = @"iCloud Account Changed";
    NSString *message = @"You can now choose to use the local data, "
    "or the data from the new iCloud account.";
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:title message:message delegate:self
                              cancelButtonTitle:nil otherButtonTitles:@"Local", @"iCloud", nil];
    [alertView show];
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
        [self configureCloudQuestionStatusSegmentedControl];
    }
}

#pragma mark - UI Setup Methods
- (void)configureCloudAccessStatusSegmentedControl
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

- (void)configurePersistentStoreStatusSegmentedControl
{
    [self.persistentStoreStatusSegmentedControl setSelectedSegmentIndex:self.storageType];
}

- (void)configureCloudQuestionStatusSegmentedControl
{
    NSInteger segmentIndex = (self.userDefaults.hasAskedForCloudStorage) ? 1 : 0;
    [self.cloudQuestionStatusSegmentedControl setSelectedSegmentIndex:segmentIndex];
}

- (void)configureActivateCoreDataButton
{
    self.activateCoreDataButton.enabled = (self.storageType == DCStorageTypeNone);
}

- (void)configureAccessDataButton
{
    self.accessDataButton.enabled = self.dataAccessAllowed;
}

#pragma mark - Properties
- (void)setStorageType:(DCStorageType)storageType
{
    _storageType = storageType;
    [self configurePersistentStoreStatusSegmentedControl];
    [self configureActivateCoreDataButton];
}

- (void)setDataAccessAllowed:(BOOL)dataAccessAllowed
{
    if (_dataAccessAllowed != dataAccessAllowed) {
        NSLog(@"CLLI: App Access: %@.", (dataAccessAllowed) ? @"YES" : @"NO");
        _dataAccessAllowed = dataAccessAllowed;
        [self configureAccessDataButton];
    }
}

#pragma mark - Ubiquity Identity Manager Delegate - Only for Testing!
- (void)ubiquityIdentityManager:(DCUbiquityIdentityManager *)ubiquityIdentityManager
          didChangeFromIdentity:(id<NSObject,NSCopying,NSCoding>)fromIdentity
                     toIdentity:(id<NSObject,NSCopying,NSCoding>)toIdentity
{
    [self configureCloudAccessStatusSegmentedControl];
}
@end
