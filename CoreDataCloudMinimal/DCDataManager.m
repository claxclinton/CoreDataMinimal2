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

typedef NS_ENUM(NSUInteger, DCStorageState) {
    DCStorageStateNone = 0,
    DCStorageStateLocal,
    DCStorageStateCloud
};

@interface DCDataManager ()
@property (weak, nonatomic) id <DCDataManagerDelegate> delegate;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@property (assign, nonatomic) DCStorageState storageState;
@property (strong, nonatomic) NSPersistentStore *persistentStore;
@property (strong, nonatomic) NSPersistentStoreCoordinator *storeCoordinator;
@end

@interface DCDataManager ()
@property (strong, nonatomic) NSPersistentStoreCoordinator *cloudStoreCoordinator;
@property (strong, nonatomic) NSPersistentStore *cloudPersistentStore;
@end

@interface DCDataManager ()
@property (strong, nonatomic) NSPersistentStore *localPersistentStore;
@property (strong, nonatomic) NSPersistentStoreCoordinator *localStoreCoordinator;
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
        self.storageState = DCStorageStateNone;
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
    self.storageState = DCStorageStateNone;
    [self.delegate dataManagerDelegate:self accessDataAllowed:NO];
}

- (void)addLocalStorage
{
    self.storageState = DCStorageStateLocal;
    [self.delegate dataManagerDelegate:self accessDataAllowed:YES];
    [self.delegate dataManagerDelegate:self shouldReload:YES];
}

- (void)addCloudStorage
{
    self.storageState = DCStorageStateCloud;
    [self.delegate dataManagerDelegate:self accessDataAllowed:YES];
    [self.delegate dataManagerDelegate:self shouldReload:YES];
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
