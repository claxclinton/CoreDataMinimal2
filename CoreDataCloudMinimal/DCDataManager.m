//
//  DCDataManager.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-07.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

@import CoreData;

#import "DCDataManager.h"

@interface DCDataManager ()
@property (strong, nonatomic) NSPersistentStore *persistentStore;
@end

@implementation DCDataManager
#pragma mark - Create And Init
+ (instancetype)dataManager
{
    return [[DCDataManager alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
    }
    return self;
}

#pragma mark - Core Data
- (void)initPersistensUsingCloud:(BOOL)usingCloud
{
    
}

#pragma mark - Helper Methods
- (NSURL *)applicationDocumentsDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directories = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *applicationDocumentsDirectory = [directories lastObject];
    return applicationDocumentsDirectory;
}
@end
