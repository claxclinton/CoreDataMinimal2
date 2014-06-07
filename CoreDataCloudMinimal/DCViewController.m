//
//  DCViewController.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-05.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCViewController.h"
#import "DCDataManager.h"

typedef NS_ENUM(NSUInteger, DCStorageState) {
    DCStorageStateNone = 0,
    DCStorageStateLocal,
    DCStorageStateCloud
};

@interface DCViewController () <DCDataManagerDelegate>
@property (strong, nonatomic) IBOutlet UISegmentedControl *systemCloudAccessSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *appCloudAccessSegmentedControl;
@property (strong, nonatomic) DCDataManager *dataManager;
@property (assign, nonatomic) DCStorageState storageState;
@end

@implementation DCViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dataManager = [DCDataManager dataManagerWithDelegate:self];
}

#pragma mark - Navigation
- (IBAction)unwindActionWithStoryboardSegue:(UIStoryboardSegue *)storyboardSegue
{
}

#pragma mark - User Actions
- (IBAction)disconnectButtonActionWithSender:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.dataManager removeStorage];
}

- (IBAction)connectToLocalStorageButtonActionWithSender:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.dataManager addLocalStorage];
}

- (IBAction)connectToCloudStorageButtonActionWithSender:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.dataManager addCloudStorage];
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
 didChangeUbiquityTokenFrom:(id)fromToken
            toUbiquityToken:(id)toToken
{
    NSLog(@"%s from:\"%@\" to:\"%@\"", __PRETTY_FUNCTION__, fromToken, toToken);
    NSInteger selectedSegmentIndex = (toToken == nil) ? 0 : 1;
    [self.systemCloudAccessSegmentedControl setSelectedSegmentIndex:selectedSegmentIndex];
}

#pragma mark - Helper Methods
- (void)setStorageState:(DCStorageState)storageState
{
    [self.systemCloudAccessSegmentedControl setSelectedSegmentIndex:storageState];
}
@end
