//
//  DCViewController.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-05.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCViewController.h"

@interface DCViewController ()
@property (strong, nonatomic) IBOutlet UITextView *storageTextView;
@end

@implementation DCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation
- (IBAction)unwindWithStoryboardSegue:(UIStoryboardSegue *)storyboardSegue
{
}

#pragma mark - User Actions
- (IBAction)cloudAppAllowBarButtonItemActionWithSender:(id)sender
{
}

- (IBAction)cloudSystemAllowBarButtonItemActionWithSender:(id)sender
{
}

- (IBAction)rebuildFromCloudButtonActionWithSender:(id)sender
{
}

- (IBAction)showStorageButtonActionWithSender:(id)sender
{
}

- (IBAction)dataButtonWithAction:(id)sender
{
    [self performSegueWithIdentifier:@"data" sender:self];
}
@end
