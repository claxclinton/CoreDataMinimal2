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

@interface DCViewController () <DCCoreDataManagerDelegate>
@property (strong, nonatomic) IBOutlet UISegmentedControl *cloudAccessStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *persistentStoreStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *launchStateStatusSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *persistentStoreSegmentedControl;
@property (strong, nonatomic) IBOutlet UIButton *accessDataButton;
@property (strong, nonatomic) DCCoreDataManager *coreDataManager;
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
    self.coreDataManager = [DCCoreDataManager dataManagerWithModelName:@"Model" delegate:self];
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

#pragma mark - Data Manager Delegate

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
