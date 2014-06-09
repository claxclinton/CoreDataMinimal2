//
//  DCDataManager.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-07.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

@import CoreData;

#import "DCDataManager.h"
#import "DCSharedServices.h"
#import "DCUserDefaults.h"
#import "DCData.h"

static NSString * const DCUbiquitousContentName = @"CoreDataCloudMinimal";
static NSString * const DCStoreNameLocal = @"Data-Local.sqlite";
static NSString * const DCStoreNameCloud = @"Data-Cloud.sqlite";

@interface DCDataManager ()
@property (copy, nonatomic) NSString *modelName;
@property (weak, nonatomic) id <DCDataManagerDelegate> delegate;
@property (strong, nonatomic) DCSharedServices *sharedServices;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@property (assign, nonatomic) DCPersistentStorageType persistentStorageType;
@property (strong, nonatomic) NSPersistentStore *persistentStore;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (assign, nonatomic) BOOL registeredForNotificationStoresWillChange;
@property (assign, nonatomic) BOOL registeredForNotificationStoresDidChange;
@property (assign, nonatomic) BOOL registeredForNotificationDidImportUbiquitousContent;
@property (assign, nonatomic) BOOL registeredForNotificationUbiquitousIdentityDidChange;
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

- (instancetype)initWithModelName:(NSString *)modelName delegate:(id <DCDataManagerDelegate>)delegate
{
    self = [super init];
    if (self != nil) {
        self.modelName = modelName;
        self.delegate = delegate;
        self.persistentStorageType = DCPersistentStorageTypeNone;
        self.sharedServices = [DCSharedServices sharedServices];
        self.userDefaults = self.sharedServices.userDefaults;
        [self registerForCloudNotifications];
        [self updateStoredAccessIdentity];
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
    self.persistentStorageType = DCPersistentStorageTypeNone;
    [self.managedObjectContext reset];
    self.managedObjectContext = nil;
    [self clearAllPersistentStoresAndPersistentStoreCoordinators];
}

- (void)addLocalStorage
{
    if (self.persistentStorageType != DCPersistentStorageTypeLocal) {
        [self.delegate dataManagerDelegate:self accessDataAllowed:NO];
        [self.managedObjectContext reset];
        [self setupLocalPersistentStore];
        self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        [self.delegate dataManagerDelegate:self accessDataAllowed:YES];
        [self.delegate dataManagerDelegate:self shouldReload:YES];
        self.persistentStorageType = DCPersistentStorageTypeLocal;
    }
}

- (void)addCloudStorage
{
    NSAssert(self.userDefaults.appCloudAccessAllowed, @"The app must be configured to use iCloud.");
    if (self.persistentStorageType != DCPersistentStorageTypeCloud) {
        [self.delegate dataManagerDelegate:self accessDataAllowed:NO];
        [self.managedObjectContext reset];
        [self setupCloudPersistentStore];
        self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        self.persistentStorageType = DCPersistentStorageTypeCloud;
        [self.delegate dataManagerDelegate:self accessDataAllowed:YES];
        [self.delegate dataManagerDelegate:self shouldReload:YES];
    }
}

- (DCData *)insertDataItem
{
    DCData *data = nil;
    if (_managedObjectContext != nil) {
        data = [NSEntityDescription
                insertNewObjectForEntityForName:@"Data"
                inManagedObjectContext:self.managedObjectContext];
        data.date = [NSDate date];
        NSError *saveError;
        BOOL saveSuccess = [self.managedObjectContext save:&saveError];
        if (!saveSuccess) {
            NSLog(@"Failed to save with error: %@.", saveError);
            abort();
        }
    }
    return data;
}

- (NSArray *)sortedData
{
    NSArray *results = nil;
    if (_managedObjectContext != nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Data"];
        NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        [fetchRequest setSortDescriptors:@[sortByDate]];
        NSError *fetchExecutionError;
        results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchExecutionError];
        if (results == nil) {
            NSLog(@"Failed to execute fetch with error: %@.", fetchExecutionError);
            abort();
        }
    }
    return results;
}

#pragma mark - Cloud Notifications
- (void)unregisterForCloudNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    if (self.registeredForNotificationStoresWillChange) {
        [notificationCenter removeObserver:self forKeyPath:NSPersistentStoreCoordinatorStoresWillChangeNotification];
        self.registeredForNotificationStoresWillChange = NO;
    }
    if (self.registeredForNotificationStoresDidChange) {
        [notificationCenter removeObserver:self forKeyPath:NSPersistentStoreCoordinatorStoresDidChangeNotification];
        self.registeredForNotificationStoresDidChange = NO;
    }
    if (self.registeredForNotificationDidImportUbiquitousContent) {
        [notificationCenter removeObserver:self forKeyPath:NSPersistentStoreDidImportUbiquitousContentChangesNotification];
        self.registeredForNotificationDidImportUbiquitousContent = NO;
    }
    if (self.registeredForNotificationUbiquitousIdentityDidChange) {
        [notificationCenter removeObserver:self forKeyPath:NSUbiquityIdentityDidChangeNotification];
        self.registeredForNotificationUbiquitousIdentityDidChange = YES;
    }
}

- (void)registerForCloudNotifications
{
    [self unregisterForCloudNotifications];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = self.persistentStoreCoordinator;
    __weak typeof(self)weakSelf = self;
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [notificationCenter addObserverForName:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                    object:persistentStoreCoordinator queue:mainQueue usingBlock:^(NSNotification *note) {
                                        [weakSelf storesWillChangeWithNotification:note];
                                    }];
    self.registeredForNotificationStoresWillChange = YES;
    [notificationCenter addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                    object:persistentStoreCoordinator queue:mainQueue usingBlock:^(NSNotification *note) {
                                        [weakSelf storesDidChangeWithNotification:note];
                                    }];
    self.registeredForNotificationStoresDidChange = YES;
    [notificationCenter addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                    object:persistentStoreCoordinator queue:mainQueue usingBlock:^(NSNotification *note) {
                                        [weakSelf persistentStoreDidImportUbiquitousContentChanges:note];
                                    }];
    self.registeredForNotificationDidImportUbiquitousContent = YES;
    [notificationCenter addObserverForName:NSUbiquityIdentityDidChangeNotification object:nil
                                     queue:mainQueue usingBlock:^(NSNotification *note) {
                                         [weakSelf ubiquityIdentityDidChangeWithNotification:note];
                                     }];
    self.registeredForNotificationUbiquitousIdentityDidChange = YES;
}

- (void)storesWillChangeWithNotification:(NSNotification *)notification
{
}

- (void)storesDidChangeWithNotification:(NSNotification *)notification
{
}

- (void)persistentStoreDidImportUbiquitousContentChanges:(NSNotification *)changeNotification
{
}

- (void)ubiquityIdentityDidChangeWithNotification:(NSNotification *)notification
{
    [self updateStoredAccessIdentity];
}

#pragma mark - Managed Object Context
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc]
                                 initWithConcurrencyType:NSMainQueueConcurrencyType];
    }
    return _managedObjectContext;
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
    NSDictionary *options = [self localPersistentStoreCoordinatorOptions];
    
    // Setup local persistent store URL.
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:DCStoreNameLocal];
    
    // Create persistent store and add to persistent store coordinator.
    NSError *addPersistentStoreError = nil;
    persistentStore = [persistentStoreCoordinator
                       addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL
                       options:options error:&addPersistentStoreError];
    if (persistentStore == nil) {
        NSLog(@"When adding store to local persistent store coordinator, got error %@, with user info %@",
              addPersistentStoreError, [addPersistentStoreError userInfo]);
        abort();
    }
    
    // Output variables
    *persistentStoreCoordinatorOutput = persistentStoreCoordinator;
    *persistentStoreOutput = persistentStore;
}

- (void)cloudPersistentStoreCoordinator:(NSPersistentStoreCoordinator **)persistentStoreCoordinatorOutput
                        persistentStore:(NSPersistentStore **)persistentStoreOutput
{
    // Result variables
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSPersistentStore *persistentStore;
    
    // Create coordinator with managed object model.
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel:self.managedObjectModel];
    
    // Create coordinator with persistent store.
    NSDictionary *options = [self cloudPersistentStoreCoordinatorOptions];
    
    // Setup local persistent store URL.
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:DCStoreNameCloud];
    
    // Create persistent store and add to persistent store coordinator.
    NSError *addPersistentStoreError = nil;
    persistentStore = [persistentStoreCoordinator
                       addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL
                       options:options error:&addPersistentStoreError];
    if (persistentStore == nil) {
        NSLog(@"When adding store to cloud persistent store coordinator, got error %@, with user info %@",
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

#pragma mark - Persistent Store Helper Methods
#pragma mark Common
- (void)setPersistentStore:(NSPersistentStore *)persistentStore
persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    self.persistentStore = persistentStore;
    self.persistentStoreCoordinator = persistentStoreCoordinator;
}

#pragma mark Local Persistent Store
- (NSDictionary *)localPersistentStoreCoordinatorOptions
{
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
                              NSInferMappingModelAutomaticallyOption: @(YES)};
    return options;
}

- (void)setupLocalPersistentStore
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSPersistentStore *persistentStore;
    [self localPersistentStoreCoordinator:&persistentStoreCoordinator persistentStore:&persistentStore];
    self.localPersistentStoreCoordinator = persistentStoreCoordinator;
    self.localPersistentStore = persistentStore;
    [self setPersistentStore:persistentStore persistentStoreCoordinator:persistentStoreCoordinator];
    NSLog(@"Local persistent store: %@", persistentStore.URL);
}

#pragma mark Cloud Persistent Store
- (NSDictionary *)cloudPersistentStoreCoordinatorOptions
{
    NSDictionary *options = @{NSPersistentStoreUbiquitousContentNameKey: DCUbiquitousContentName,
                              NSMigratePersistentStoresAutomaticallyOption: @(YES),
                              NSInferMappingModelAutomaticallyOption: @(YES)};
    return options;
}

- (void)setupCloudPersistentStore
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSPersistentStore *persistentStore;
    [self cloudPersistentStoreCoordinator:&persistentStoreCoordinator persistentStore:&persistentStore];
    self.cloudPersistentStoreCoordinator = persistentStoreCoordinator;
    self.cloudPersistentStore = persistentStore;
    [self setPersistentStore:persistentStore persistentStoreCoordinator:persistentStoreCoordinator];
    NSLog(@"Cloud persistent store: %@", persistentStore.URL);
}

#pragma mark - Internal Helper Methods
- (void)setPersistentStorageType:(DCPersistentStorageType)persistentStorageType
{
    _persistentStorageType = persistentStorageType;
    if ([self.delegate respondsToSelector:@selector(dataManagerDelegate:didChangeToStorageType:)]) {
        [self.delegate dataManagerDelegate:self didChangeToStorageType:persistentStorageType];
    }
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager]
             URLsForDirectory:NSDocumentDirectory
             inDomains:NSUserDomainMask] lastObject];
}

- (void)clearAllPersistentStoresAndPersistentStoreCoordinators
{
    self.localPersistentStore = nil;
    self.localPersistentStoreCoordinator = nil;
    self.cloudPersistentStore = nil;
    self.cloudPersistentStoreCoordinator = nil;
    self.persistentStore = nil;
    self.persistentStoreCoordinator = nil;
}

- (void)updateStoredAccessIdentity
{
    id previousUbiquityIdentity = self.userDefaults.storedAccessIdentity;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    id nextUbiquityIdentity = [fileManager ubiquityIdentityToken];
    [self.delegate dataManagerDelegate:self didChangeUbiquityTokenFrom:previousUbiquityIdentity toUbiquityToken:nextUbiquityIdentity];
    self.userDefaults.storedAccessIdentity = nextUbiquityIdentity;    
}
@end
