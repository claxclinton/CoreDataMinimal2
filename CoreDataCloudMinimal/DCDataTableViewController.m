//
//  DCDataTableViewController.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-05.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCDataTableViewController.h"
#import "DCDataManager.h"
#import "DCData.h"

@interface DCDataTableViewController ()
@property (strong, nonatomic) NSArray *sortedData;
@end

@implementation DCDataTableViewController
#pragma mark - View Controller
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.sortedData = [self.dataManager sortedData];
}

#pragma mark - Table View Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sortedData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    DCData *data = self.sortedData[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", data.date];
    return cell;
}

#pragma mark - User Actions
- (IBAction)addButtonActionWithSender:(id)sender
{
    [self.dataManager insertDataItem];
    self.sortedData = [self.dataManager sortedData];
    [self.tableView reloadData];
}

- (IBAction)cancelButtonActionWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"unwind" sender:self];
}
@end
