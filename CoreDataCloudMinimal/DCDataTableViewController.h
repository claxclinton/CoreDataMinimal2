//
//  DCDataTableViewController.h
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-05.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DCDataManager;

@interface DCDataTableViewController : UITableViewController
@property (strong, nonatomic) DCDataManager *dataManager;
@end
