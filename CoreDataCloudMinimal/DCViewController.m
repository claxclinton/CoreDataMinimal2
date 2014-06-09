    //
//  DCViewController.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-05.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCViewController.h"
#import "DCSharedServices.h"
#import "DCDataManager.h"
#import "DCUserDefaults.h"
#import "DCDataTableViewController.h"

@interface DCViewController () <DCDataManagerDelegate>
@property (strong, nonatomic) IBOutlet UISegmentedControl *systemCloudAccessSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *storageBackendSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *persistentStoreTypeSegmentedControl;
@property (strong, nonatomic) DCDataManager *dataManager;
@property (strong, nonatomic) UIButton *selectedButton;
@property (assign, nonatomic) DCPersistentStorageType persistentStorageType;
@property (strong, nonatomic) NSDictionary *persistentStorageTypeDescription;
@property (strong, nonatomic) DCSharedServices *sharedServices;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@end

@implementation DCViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sharedServices = [DCSharedServices sharedServices];
    self.dataManager = [DCDataManager dataManagerWithModelName:@"Model" delegate:self];
    self.persistentStorageTypeDescription = @{@(DCPersistentStorageTypeNone): @"No Persistent Store",
                                              @(DCPersistentStorageTypeLocal): @"Local Persistent Store",
                                              @(DCPersistentStorageTypeCloud): @"Cloud Persistent Store"};
    self.userDefaults = self.sharedServices.userDefaults;
    [self setupSystemCloudAccessSegmentedControl];
    [self setupStorageBackendSegmentedControl];
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
        dataTableViewController.dataManager = self.dataManager;
    }
}

- (IBAction)unwindActionWithStoryboardSegue:(UIStoryboardSegue *)storyboardSegue
{
}

#pragma mark - User Actions
- (IBAction)storageBackendSegmentedControlActionWithSender:(id)sender
{
    BOOL usingCloudStorageBackend = (self.storageBackendSegmentedControl.selectedSegmentIndex == 1);
    self.userDefaults.usingCloudStorageBackend = usingCloudStorageBackend;
    [self setupStorageBackendSegmentedControl];
    NSLog(@"%s allow:%@", __PRETTY_FUNCTION__, (usingCloudStorageBackend) ? @"YES" : @"NO");
}

- (IBAction)persistentStoreTypeSegmentedControlActionWithSender:(id)sender
{
    NSInteger selectedSegmentIndex = self.persistentStoreTypeSegmentedControl.selectedSegmentIndex;
    DCPersistentStorageType storageType = (DCPersistentStorageType)selectedSegmentIndex;
    switch (storageType) {
        case DCPersistentStorageTypeNone:
            [self removeStorage];
            break;
        case DCPersistentStorageTypeLocal:
            [self addLocalStorage];
            break;
        case DCPersistentStorageTypeCloud:
            [self addCloudStorage];
            break;
    }
    NSLog(@"%s Change To:\"%@\"", __PRETTY_FUNCTION__, self.persistentStorageTypeDescription[@(storageType)]);
}

- (IBAction)accessDataButtonActionWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"accessData" sender:self];
}

#pragma mark - Storage Change Method
- (void)removeStorage
{
    [self.dataManager removeStorage];
}

- (void)addLocalStorage
{
    [self.dataManager addLocalStorage];
}

- (void)addCloudStorage
{
    if (!self.userDefaults.usingCloudStorageBackend) {
        self.persistentStorageType = self.persistentStorageType;
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Missing App iCloud Permissions"
                                  message:@"Allow the app to access iCloud from within the app."
                                  delegate:nil cancelButtonTitle:@"Done" otherButtonTitles:nil];
        [alertView show];
    } else {
        if (self.userDefaults.storedAccessIdentity == nil) {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"App Misses System Access To iCloud"
                                      message:@"Since the app misses system access to iCloud, your changes "
                                      "will not be shared to other devices until system access is available. "
                                      "Check that you are logged in and app has access to \"Documents & Data\"."
                                      delegate:nil cancelButtonTitle:@"Done" otherButtonTitles:nil];
            [alertView show];
        }
        [self.dataManager addCloudStorage];
    }
}

#pragma mark - Data Manager
- (void)dataManagerDelegate:(DCDataManager *)dataManager
         shouldLockInterace:(BOOL)lockInterface
{
    NSLog(@"%s lockInterface:%@", __PRETTY_FUNCTION__, (lockInterface) ? @"YES" : @"NO");
}

- (void)dataManagerDelegate:(DCDataManager *)dataManager
          accessDataAllowed:(BOOL)accessDataAllowed
{
    NSLog(@"%s accessDataAllowed:%@", __PRETTY_FUNCTION__, (accessDataAllowed) ? @"YES" : @"NO");
}

- (void)dataManagerDelegate:(DCDataManager *)dataManager
               shouldReload:(BOOL)shouldReload
{
    NSLog(@"%s shouldReload:%@", __PRETTY_FUNCTION__, (shouldReload) ? @"YES" : @"NO");
}

- (void)dataManagerDelegate:(DCDataManager *)dataManager
     didChangeToStorageType:(DCPersistentStorageType)storageType
{
    self.persistentStorageType = storageType;
}

- (void)dataManagerDelegate:(DCDataManager *)dataManager
 didChangeUbiquityTokenFrom:(id)fromToken
            toUbiquityToken:(id)toToken
{
    NSLog(@"%s from:\"%@\" to:\"%@\"", __PRETTY_FUNCTION__, fromToken, toToken);
    NSInteger selectedSegmentIndex = (toToken == nil) ? 0 : 1;
    [self.systemCloudAccessSegmentedControl setSelectedSegmentIndex:selectedSegmentIndex];
}

#pragma mark - Helper Methods
- (void)setupSystemCloudAccessSegmentedControl
{
    id ubiquityIdentity = self.userDefaults.storedAccessIdentity;
    NSInteger segmentIndex = (ubiquityIdentity == nil) ? 0 : 1;
    [self.systemCloudAccessSegmentedControl setSelectedSegmentIndex:segmentIndex];
}

- (void)setupStorageBackendSegmentedControl
{
    BOOL appCloudAccessAllowed = self.userDefaults.usingCloudStorageBackend;
    NSInteger segmentIndex = (appCloudAccessAllowed) ? 1 : 0;
    [self.storageBackendSegmentedControl setSelectedSegmentIndex:segmentIndex];
}

- (void)setPersistentStorageType:(DCPersistentStorageType)storageState
{
    [self.persistentStoreTypeSegmentedControl setSelectedSegmentIndex:storageState];
}
@end
