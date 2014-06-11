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
@property (strong, nonatomic) IBOutlet UISegmentedControl *cloudAccessStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *persistentStoreStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *launchStateStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *persistentStoreSegmentedControl;
@property (strong, nonatomic) IBOutlet UIButton *accessDataButton;
@property (strong, nonatomic) DCDataManager *dataManager;
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
        dataTableViewController.dataManager = self.dataManager;
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

#pragma mark - Storage Change Method

#pragma mark - Data Manager
- (void)dataManagerDelegate:(DCDataManager *)dataManager
         shouldLockInterace:(BOOL)lockInterface
{
    NSLog(@"CLLI: %s lockInterface:%@", __PRETTY_FUNCTION__, (lockInterface) ? @"YES" : @"NO");
}

- (void)dataManagerDelegate:(DCDataManager *)dataManager
          accessDataAllowed:(BOOL)accessDataAllowed
{
    NSLog(@"CLLI: %s accessDataAllowed:%@", __PRETTY_FUNCTION__, (accessDataAllowed) ? @"YES" : @"NO");
}

- (void)dataManagerDelegate:(DCDataManager *)dataManager
               shouldReload:(BOOL)shouldReload
{
    NSLog(@"CLLI: %s shouldReload:%@", __PRETTY_FUNCTION__, (shouldReload) ? @"YES" : @"NO");
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
    NSLog(@"CLLI: %s from:\"%@\" to:\"%@\"", __PRETTY_FUNCTION__, fromToken, toToken);
    NSInteger selectedSegmentIndex = (toToken == nil) ? 0 : 1;
    [self.cloudAccessStatusSegmentedControl setSelectedSegmentIndex:selectedSegmentIndex];
}

#pragma mark - UI Setup Methods
- (void)setupCloudAccessStatusSegmentedControl
{
}

- (void)setupPersistentStoreStatusSegmentedControl
{
}

- (void)setupLaunchStateStatusSegmentedControl
{
}

- (void)setupPersistentStoreSegmentedControl
{
}

- (void)setupAccessDataButton
{
}
@end
