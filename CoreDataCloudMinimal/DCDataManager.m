//
//  DCDataManager.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-07.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

@import CoreData;

#import "DCDataManager.h"
#import "DCUserDefaults.h"

@interface DCDataManager ()
@property (weak, nonatomic) id <DCDataManagerDelegate> delegate;
@property (strong, nonatomic) NSPersistentStore *persistentStore;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@end

@implementation DCDataManager
#pragma mark - Create And Init
+ (instancetype)dataManagerWithDelegate:(id <DCDataManagerDelegate>)delegate
{
    return [[DCDataManager alloc] initWithDelegate:delegate];
}

- (instancetype)initWithDelegate:(id <DCDataManagerDelegate>)delegate
{
    self = [super init];
    if (self != nil) {
        self.delegate = delegate;
        self.userDefaults = [DCUserDefaults userDefaultsWithPersistentStore:YES];
    }
    return self;
}

#pragma mark - Properties
- (id <NSObject, NSCopying, NSCoding>)ubiquityIdentityToken
{
    return self.userDefaults.storedAccessIdentity;
}

#pragma mark - Public Methods
- (void)removeStorage
{
}

- (void)addLocalStorage
{
}

- (void)addCloudStorage
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
