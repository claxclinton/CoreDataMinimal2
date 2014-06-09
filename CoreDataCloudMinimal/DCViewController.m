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
@property (strong, nonatomic) IBOutlet UISegmentedControl *appCloudAccessSegmentedControl;
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
- (IBAction)appCloudAccessSegmentedControlActionWithSender:(id)sender
{
    BOOL appCloudAccessAllowed = (self.appCloudAccessSegmentedControl.selectedSegmentIndex == 1);
    self.userDefaults.appCloudAccessAllowed = appCloudAccessAllowed;
    NSLog(@"%s allow:%@", __PRETTY_FUNCTION__, (appCloudAccessAllowed) ? @"YES" : @"NO");
}

- (IBAction)persistentStoreTypeSegmentedControlActionWithSender:(id)sender
{
    NSInteger selectedSegmentIndex = self.persistentStoreTypeSegmentedControl.selectedSegmentIndex;
    DCPersistentStorageType storageType = (DCPersistentStorageType)selectedSegmentIndex;
    switch (storageType) {
        case DCPersistentStorageTypeNone:
            [self.dataManager removeStorage];
            break;
        case DCPersistentStorageTypeLocal:
            [self.dataManager addLocalStorage];
            break;
        case DCPersistentStorageTypeCloud:
            [self.dataManager addCloudStorage];
            break;
    }
    NSLog(@"%s Change To:\"%@\"", __PRETTY_FUNCTION__, self.persistentStorageTypeDescription[@(storageType)]);
}

- (IBAction)accessDataButtonActionWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"accessData" sender:self];
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
- (void)setPersistentStorageType:(DCPersistentStorageType)storageState
{
    [self.persistentStoreTypeSegmentedControl setSelectedSegmentIndex:storageState];
}
@end
