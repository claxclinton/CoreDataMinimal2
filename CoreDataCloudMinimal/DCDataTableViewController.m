//
//  DCDataTableViewController.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-05.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCDataTableViewController.h"

@interface DCDataTableViewController ()

@end

@implementation DCDataTableViewController

#pragma mark - User Actions
- (IBAction)addButtonActionWithSender:(id)sender
{

}

- (IBAction)cancelButtonActionWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"unwind" sender:self];
}
@end
