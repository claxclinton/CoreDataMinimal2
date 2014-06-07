//
//  DCViewController.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-05.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCViewController.h"

@interface DCViewController ()
@property (strong, nonatomic) IBOutlet UISegmentedControl *systemCloudAccessSegmentedControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *appCloudAccessSegmentedControl;
@end

@implementation DCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Navigation
- (IBAction)unwindActionWithStoryboardSegue:(UIStoryboardSegue *)storyboardSegue
{
}

#pragma mark - User Actions
- (IBAction)disconnectButtonActionWithSender:(id)sender
{
}

- (IBAction)connectToLocalStorageButtonActionWithSender:(id)sender
{
}

- (IBAction)connectToCloudStorageButtonActionWithSender:(id)sender
{
}

- (IBAction)accessDataButtonActionWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"accessData" sender:self];
}
@end
