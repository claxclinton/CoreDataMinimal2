//
//  DCDataManager.m
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-07.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

@import CoreData;

#import "DCCoreDataManager.h"
#import "DCSharedServices.h"
#import "DCUserDefaults.h"
#import "DCUbiquityIdentityManager.h"
#import "DCStorageChangeEventsManager.h"
#import "DCData.h"

static NSString * const DCUbiquitousContentName = @"CoreDataCloudMinimal";
static NSString * const DCStoreNameLocal = @"ModelStorage-Local.sqlite";
static NSString * const DCStoreNameCloud = @"ModelStorage-Cloud.sqlite";

@interface DCCoreDataManager () <DCUbiquityIdentityManagerDelegate,
                                 DCStorageChangeEventsManagerDelegate>
@property (copy, nonatomic) NSString *modelName;
@property (weak, nonatomic) id <DCCoreDataManagerDelegate> delegate;
@property (strong, nonatomic) DCSharedServices *sharedServices;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@property (assign, nonatomic) DCStorageType storageType;
@property (assign, nonatomic) DCStorageType dataAccessAllowed;
@property (strong, nonatomic) NSPersistentStore *persistentStore;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFileManager *fileManager;
@end

@interface DCCoreDataManager ()
@property (strong, nonatomic) NSPersistentStoreCoordinator *cloudPersistentStoreCoordinator;
@property (strong, nonatomic) NSPersistentStore *cloudPersistentStore;
@property (assign, nonatomic) BOOL askedForCloudStorage;
@end

@interface DCCoreDataManager ()
@property (strong, nonatomic) NSPersistentStoreCoordinator *localPersistentStoreCoordinator;
@property (strong, nonatomic) NSPersistentStore *localPersistentStore;
@end

@implementation DCCoreDataManager
#pragma mark - Life Cycle
+ (instancetype)dataManagerWithModelName:(NSString *)modelName
                                delegate:(id <DCCoreDataManagerDelegate>)delegate
{
    return [[DCCoreDataManager alloc] initWithModelName:modelName delegate:delegate];
}

- (instancetype)initWithModelName:(NSString *)modelName
                         delegate:(id <DCCoreDataManagerDelegate>)delegate
{
    self = [super init];
    if (self != nil) {
        self.modelName = modelName;
        self.delegate = delegate;
        self.storageType = DCStorageTypeNone;
        self.sharedServices = [DCSharedServices sharedServices];
        self.userDefaults = self.sharedServices.userDefaults;
        self.fileManager = [NSFileManager defaultManager];
        [self setDataAccessAllowed:NO updateDelegateIfChange:NO updateDelegateForced:YES];
    }
    return self;
}

- (void)dealloc
{
    [self setDataAccessAllowed:NO updateDelegateIfChange:NO updateDelegateForced:YES];
    [self unregisterForAllEvents];
}

#pragma mark - Public Methods
- (void)addPersistentStore
{
    [self addPersistentStoreWithLocalStoreAsDefault:YES];
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
            NSLog(@"CLLI: Failed to save with error: %@.", saveError);
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
            NSLog(@"CLLI: Failed to execute fetch with error: %@.", fetchExecutionError);
            abort();
        }
    }
    return results;
}

#pragma mark - Add Remove Storage Methods
- (void)addStoreWithStorageType:(DCStorageType)storageType
{
    [self setDataAccessAllowed:NO updateDelegateIfChange:YES updateDelegateForced:NO];
    if (storageType == DCStorageTypeLocal) {
        [self addLocalStore];
    } else {
        [self addCloudStore];
    }
    [self saveStorageType];
    [self.delegate coreDataManager:self didAddStorageType:storageType];
    [self setDataAccessAllowed:YES updateDelegateIfChange:YES updateDelegateForced:NO];
}

- (void)addLocalStore
{
    if (self.storageType != DCStorageTypeLocal) {
        [self.managedObjectContext reset];
        if (self.storageType == DCStorageTypeCloud) {
            [self removeCloudStore];
        }
        [self setupLocalPersistentStore];
        self.managedObjectContext = nil;
        self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        self.storageType = DCStorageTypeLocal;
    }
}

- (void)removeLocalStore
{
    NSError *removePersistentStoreError;
    [self.localPersistentStoreCoordinator
     removePersistentStore:self.localPersistentStore
     error:&removePersistentStoreError];
}

- (void)addCloudStore
{
    if (self.storageType != DCStorageTypeCloud) {
        [self.managedObjectContext reset];
        if (self.storageType == DCStorageTypeLocal) {
            [self removeLocalStore];
        }
        [self setupCloudPersistentStore];
        self.managedObjectContext = nil;
        self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        self.storageType = DCStorageTypeCloud;
    }
}

- (void)removeCloudStore
{
    NSError *removePersistentStoreError;
    [self.cloudPersistentStoreCoordinator
     removePersistentStore:self.cloudPersistentStore
     error:&removePersistentStoreError];
}

#pragma mark - Register And Unregister For Ubiquity Identity And Storage Changes
- (void)registerForAllEventsWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    [self.sharedServices.ubiquityIdentityManager addDelegate:self];
    [self.sharedServices.storageEventNotificationManager
     addDelegate:self forCoordinator:coordinator];
}

- (void)unregisterForAllEvents
{
    [self.sharedServices.ubiquityIdentityManager removeDelegate:self];
    [self.sharedServices.storageEventNotificationManager
     removeDelegate:self forCoordinator:self.persistentStoreCoordinator];
}

#pragma mark - Ubiquity Identity Changes Delegate
- (void)ubiquityIdentityManager:(DCUbiquityIdentityManager *)ubiquityIdentityManager
          didChangeFromIdentity:(id <NSObject, NSCopying, NSCoding>)fromIdentity
                     toIdentity:(id <NSObject, NSCopying, NSCoding>)toIdentity
{
    [self setDataAccessAllowed:NO updateDelegateIfChange:YES updateDelegateForced:NO];
    if (self.storageType == DCStorageTypeCloud) {
        // If iCloud support is now disabled, the user has to choose local storage.
        // But if, on a later occation iCloud becomes available again, the choice
        // between local or cloud should be possible again.
        if (toIdentity == nil) {
            self.userDefaults.hasAskedForCloudStorage = NO;
        }
        
        __weak typeof(self)weakSelf = self;
        [self.delegate coreDataManager:self
         didChangeUbiquitousIdentityTo:toIdentity
               requestStorageTypeBlock:^(DCStorageType selectedStorageType) {
                   [weakSelf addStoreWithStorageType:selectedStorageType];
               }];
    } else {
        [self addPersistentStoreWithLocalStoreAsDefault:NO];
        [self setDataAccessAllowed:YES updateDelegateIfChange:YES updateDelegateForced:NO];
    }
}

#pragma mark - Storage Change Events Delegate
- (void)storageChangeEventsManager:(DCStorageChangeEventsManager *)manager
didReceiveStoresWillChangeNotification:(NSNotification *)notification
        persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    [self logTransitionTypeFromUserInfo:notification.userInfo];
    [self setDataAccessAllowed:NO updateDelegateIfChange:YES updateDelegateForced:NO];
    if ([self.managedObjectContext hasChanges]) {
        __weak typeof(self)weakSelf = self;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [weakSelf.managedObjectContext performBlockAndWait:^{
                NSError *saveError;
                BOOL saveSuccess = [self.managedObjectContext save:&saveError];
                if (!saveSuccess) {
                    NSLog(@"CLLI: Failed to save with error: %@.", saveError);
                    abort();
                }
            }];
             [weakSelf.managedObjectContext performBlockAndWait:^{
                 [weakSelf.managedObjectContext reset];
             }];
        });
    }
}

- (void)storageChangeEventsManager:(DCStorageChangeEventsManager *)manager
didReceiveStoresDidChangeNotification:(NSNotification *)notification
        persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    [self logTransitionTypeFromUserInfo:notification.userInfo];
    [self setDataAccessAllowed:YES updateDelegateIfChange:YES updateDelegateForced:NO];
}

- (void)storageChangeEventsManager:(DCStorageChangeEventsManager *)manager
didReceiveContentImportNotification:(NSNotification *)notification
        persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    [self setDataAccessAllowed:NO updateDelegateIfChange:YES updateDelegateForced:NO];
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    [self setDataAccessAllowed:YES updateDelegateIfChange:YES updateDelegateForced:NO];
}

#pragma mark - Managed Object Context
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc]
                                 initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
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
    
    // Register for notifications for ubiquity identity and storage.
    [self unregisterForAllEvents];
    [self registerForAllEventsWithPersistentStoreCoordinator:persistentStoreCoordinator];
    
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
        NSLog(@"CLLI: When adding store to local persistent store coordinator, got error %@, with user info %@",
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

    // Register for notifications for ubiquity identity and storage.
    [self unregisterForAllEvents];
    [self registerForAllEventsWithPersistentStoreCoordinator:persistentStoreCoordinator];

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
        NSLog(@"CLLI: When adding store to cloud persistent store coordinator, got error %@, with user info %@",
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
            NSLog(@"CLLI: %@", message);
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
    NSLog(@"CLLI: Local persistent store: %@", persistentStore.URL);
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
    NSLog(@"CLLI: Cloud persistent store: %@", persistentStore.URL);
}

#pragma mark - Internal Helper Methods
- (void)addPersistentStoreWithLocalStoreAsDefault:(BOOL)localStoreAsDefault
{
    [self setDataAccessAllowed:NO updateDelegateIfChange:YES updateDelegateForced:NO];
    BOOL shouldAskDelegate = [self shouldAskDelegateForStorageType];
    if (shouldAskDelegate) {
        self.userDefaults.hasAskedForCloudStorage = YES;
        __weak typeof(self)weakSelf = self;
        NSUInteger availableStorageTypes = (DCStorageTypeLocal | DCStorageTypeCloud);
        [self.delegate coreDataManager:self didRequestStorageTypeFrom:availableStorageTypes
                            usingBlock:^(DCStorageType selectedStorageType) {
                                [weakSelf addStoreWithStorageType:selectedStorageType];
                            }];
    } else {
        switch (self.storageType) {
            case DCStorageTypeNone:
                if (localStoreAsDefault) {
                    [self addStoreWithStorageType:DCStorageTypeLocal];
                }
                break;
            case DCStorageTypeLocal:
                [self addStoreWithStorageType:DCStorageTypeLocal];
                break;
            case DCStorageTypeCloud:
                [self addStoreWithStorageType:DCStorageTypeCloud];
                break;
        }
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

- (void)logTransitionTypeFromUserInfo:(NSDictionary *)userInfo
{
    NSNumber *transitionKeyNumber = userInfo[NSPersistentStoreUbiquitousTransitionTypeKey];
    if (transitionKeyNumber != nil) {
        switch (transitionKeyNumber.unsignedIntegerValue) {
            case NSPersistentStoreUbiquitousTransitionTypeAccountAdded:
                NSLog(@"CLLI: Transition type: Account Added");
                break;
            case NSPersistentStoreUbiquitousTransitionTypeAccountRemoved:
                NSLog(@"CLLI: Transition type: Account Removed");
                break;
            case NSPersistentStoreUbiquitousTransitionTypeContentRemoved:
                NSLog(@"CLLI: Transition type: Content Removed");
                break;
            case NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted:
                NSLog(@"CLLI: Transition type: Import Completed");
                break;
        }
    }
}

- (BOOL)shouldAskDelegateForStorageType
{
    BOOL shouldAskDelegate;
    BOOL hasCloudAccess = self.fileManager.ubiquityIdentityToken;
    BOOL hasAskedForCloudStorage = self.userDefaults.hasAskedForCloudStorage;
    switch (self.storageType) {
        case DCStorageTypeNone:
            shouldAskDelegate = hasCloudAccess;
            break;
        case DCStorageTypeLocal:
            shouldAskDelegate = (hasCloudAccess && !hasAskedForCloudStorage);
            break;
        case DCStorageTypeCloud:
            shouldAskDelegate = NO;
            break;
    }
    return shouldAskDelegate;
}

- (void)setDataAccessAllowed:(BOOL)dataAccessAllowed
      updateDelegateIfChange:(BOOL)updateDelegateIfChange
        updateDelegateForced:(BOOL)updateDelegateForced
{
    if (_dataAccessAllowed != dataAccessAllowed) {
        self.dataAccessAllowed = dataAccessAllowed;
        if (updateDelegateIfChange || updateDelegateForced) {
            [self.delegate coreDataManager:self didAllowDataAccess:dataAccessAllowed];
        }
    } else {
        if (updateDelegateForced) {
            [self.delegate coreDataManager:self didAllowDataAccess:dataAccessAllowed];
        }
    }
}

- (void)saveStorageType
{
    self.userDefaults.storageType = self.storageType;
}
@end
