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
#import "DCData.h"

typedef NS_ENUM(NSUInteger, DCStorageState) {
    DCStorageStateNone = 0,
    DCStorageStateLocal,
    DCStorageStateCloud
};

@interface DCDataManager ()
@property (copy, nonatomic) NSString *modelName;
@property (weak, nonatomic) id <DCDataManagerDelegate> delegate;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@property (assign, nonatomic) DCStorageState storageState;
@property (strong, nonatomic) NSPersistentStore *persistentStore;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end

@interface DCDataManager ()
@property (strong, nonatomic) NSPersistentStoreCoordinator *cloudPersistentStoreCoordinator;
@property (strong, nonatomic) NSPersistentStore *cloudPersistentStore;
@end

@interface DCDataManager ()
@property (strong, nonatomic) NSPersistentStoreCoordinator *localPersistentStoreCoordinator;
@property (strong, nonatomic) NSPersistentStore *localPersistentStore;
@end

@implementation DCDataManager
#pragma mark - Create And Init
+ (instancetype)dataManagerWithModelName:(NSString *)modelName
                                delegate:(id <DCDataManagerDelegate>)delegate
{
    return [[DCDataManager alloc] initWithModelName:modelName delegate:delegate];
}

- (instancetype)initWithModelName:(NSString *)modelName
                         delegate:(id <DCDataManagerDelegate>)delegate
{
    self = [super init];
    if (self != nil) {
        self.modelName = modelName;
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
}

- (void)addLocalStorage
{
    self.storageState = DCStorageStateLocal;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSPersistentStore *persistentStore;
    [self localPersistentStoreCoordinator:&persistentStoreCoordinator persistentStore:&persistentStore];
    self.localPersistentStoreCoordinator = persistentStoreCoordinator;
    self.localPersistentStore = persistentStore;
    [self setPersistentStore:persistentStore persistentStoreCoordinator:persistentStoreCoordinator];
    self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    [self.delegate dataManagerDelegate:self accessDataAllowed:YES];
    [self.delegate dataManagerDelegate:self shouldReload:YES];
}

- (void)addCloudStorage
{
    self.storageState = DCStorageStateCloud;
    [self.delegate dataManagerDelegate:self accessDataAllowed:YES];
    [self.delegate dataManagerDelegate:self shouldReload:YES];
}

- (DCData *)insertDataItem
{
    DCData *data = [NSEntityDescription
                    insertNewObjectForEntityForName:@"Data"
                    inManagedObjectContext:self.managedObjectContext];
    data.date = [NSDate date];
    return data;
}

- (NSArray *)sortedData
{
    
}

#pragma mark - Managed Object Context
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc]
                                 initWithConcurrencyType:NSMainQueueConcurrencyType];
    }
}

#pragma mark - Persistent Store Coordinators
- (void)localPersistentStoreCoordinator:(NSPersistentStoreCoordinator **)persistentStoreCoordinatorOutput
                        persistentStore:(NSPersistentStore **)persistentStoreOutput
{
    // Result variables
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSPersistentStore *persistentStore;
    
    // Create coordinator with managed object model.
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel:self.managedObjectModel];
    
    // Create coordinator with persistent store.
    NSDictionary *options = @{NSReadOnlyPersistentStoreOption: @(YES),
                              NSPersistentStoreUbiquitousContentNameKey: self.modelName,
                              NSMigratePersistentStoresAutomaticallyOption: @(YES),
                              NSInferMappingModelAutomaticallyOption: @(YES)};
    
    // Create persistent store and add to persistent store coordinator.
    NSError *addPersistentStoreError = nil;
    persistentStore = [persistentStoreCoordinator
                       addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:nil
                       options:options error:&addPersistentStoreError];
    if (persistentStore == nil) {
        NSLog(@"When adding store to store coordinator, got error %@, with user info %@",
              addPersistentStoreError, [addPersistentStoreError userInfo]);
        abort();
    }
    
    // Output variables
    *persistentStoreCoordinatorOutput = persistentStoreCoordinator;
    *persistentStoreOutput = persistentStore;
}

#pragma mark - Managed Object Model
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSArray *extensionMomURLs = [mainBundle URLsForResourcesWithExtension:@"mom" subdirectory:nil];
        NSArray *extensionMomdURLs = [mainBundle URLsForResourcesWithExtension:@"momd" subdirectory:nil];
        NSAssert(([extensionMomURLs count] == 0 && [extensionMomdURLs count] == 1) ||
                 ([extensionMomURLs count] == 1 && [extensionMomdURLs count] == 0),
                 @"Should exactly one .mom or one .momd in main bundle.");
        NSURL *modelURL;
        if ([extensionMomURLs count] == 0) {
            modelURL = [extensionMomdURLs firstObject];
        } else if ([extensionMomdURLs count] == 0) {
            modelURL = [extensionMomURLs firstObject];
        } else {
            NSString *message = [NSString stringWithFormat:@"Did not find any manage object "
                                 "model in bundle with identifier %@.",
                                 mainBundle.bundleIdentifier];
            NSLog(@"%@", message);
            NSAssert(NO, message);
        }
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

#pragma mark - Helper Methods
- (void)setPersistentStore:(NSPersistentStore *)persistentStore
persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    self.persistentStore = persistentStore;
    self.persistentStoreCoordinator = persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager]
             URLsForDirectory:NSDocumentDirectory
             inDomains:NSUserDomainMask] lastObject];
}
@end
