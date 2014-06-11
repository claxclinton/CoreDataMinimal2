//
//  DCStorageEventManager.m
//  CoreDataCloudMinimal2
//
//  Created by Claes Lillieskold on 2014-06-11.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

@import CoreData;

#import "DCStorageEventNotificationManager.h"

@interface DCDelegateAndCoordinator : NSObject
@property (strong, nonatomic) id <DCStorageEventNotificationManagerDelegate> delegate;
@property (strong, nonatomic) NSPersistentStoreCoordinator *coordinator;
@end

@implementation DCDelegateAndCoordinator
@end

@interface DCStorageEventNotificationManager ()
@property (strong, nonatomic) NSMutableArray *delegateAndCoordinators;
@property (strong, nonatomic) NSMutableArray *registeredCoordinators;
@property (strong, nonatomic) NSNotificationCenter *notificationCenter;
@property (assign, nonatomic) BOOL registeredForNilCoordinator;
@end

@implementation DCStorageEventNotificationManager
#pragma mark - Life Cycle
+ (instancetype)storageEventManager
{
    return [[DCStorageEventNotificationManager alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        self.delegateAndCoordinators = [NSMutableArray new];
        self.registeredCoordinators = [NSMutableArray new];
        self.notificationCenter = [NSNotificationCenter defaultCenter];
        [self registerForNotificationsFromCoordinator:nil];
    }
    return self;
}

- (void)dealloc
{
    for (DCDelegateAndCoordinator *delegateAndCoordinator in self.delegateAndCoordinators) {
        NSPersistentStoreCoordinator *coordinator = delegateAndCoordinator.coordinator;
        [self unregisterForNotificationsFromCoordinator:coordinator];
    }
    [self unregisterForNotificationsFromCoordinator:nil];
}

#pragma mark - Public Methods
- (void)addDelegate:(id <DCStorageEventNotificationManagerDelegate>)delegate
     forCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    NSParameterAssert(delegate != nil);
    DCDelegateAndCoordinator *delegateAndCoordinator = [DCDelegateAndCoordinator new];
    delegateAndCoordinator.delegate = delegate;
    delegateAndCoordinator.coordinator = persistentStoreCoordinator;
    [self.delegateAndCoordinators addObject:delegateAndCoordinator];
}

- (void)removeDelegate:(id <DCStorageEventNotificationManagerDelegate>)delegate
        forCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    NSParameterAssert(delegate != nil);
    DCDelegateAndCoordinator *delegateAndCoordinatorToRemove = nil;
    for (DCDelegateAndCoordinator *delegateAndCoordinator in self.delegateAndCoordinators) {
        if (delegateAndCoordinator.delegate == delegate) {
            delegateAndCoordinatorToRemove = delegateAndCoordinator;
        }
    }
    if (delegateAndCoordinatorToRemove) {
        [self.delegateAndCoordinators removeObject:delegateAndCoordinatorToRemove];
    }
}

#pragma mark - Register And Unregister
- (void)registerForNotificationsFromCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    BOOL shouldRegister;
    if (coordinator == nil && !self.registeredForNilCoordinator) {
        self.registeredForNilCoordinator = YES;
        shouldRegister = YES;
    } else if (![self isRegisteredForCoordinator:coordinator]) {
        shouldRegister = YES;
    } else {
        shouldRegister = NO;
    }
    
    if (shouldRegister) {
        __weak typeof(self)weakSelf = self;
        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
        
        [self.notificationCenter
         addObserverForName:NSPersistentStoreCoordinatorStoresWillChangeNotification
         object:coordinator queue:mainQueue usingBlock:^(NSNotification *note) {
             [weakSelf storesWillChangeWithNotification:note];
         }];
        [self.notificationCenter
         addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification
         object:coordinator queue:mainQueue usingBlock:^(NSNotification *note) {
             [weakSelf storesDidChangeWithNotification:note];
         }];
        [self.notificationCenter
         addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
         object:coordinator queue:mainQueue usingBlock:^(NSNotification *note) {
             [weakSelf didImportUbiquitousContentChangesWithNotification:note];
         }];
    }
}

- (void)unregisterForNotificationsFromCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    BOOL shouldUnregister;
    if (coordinator == nil && self.registeredForNilCoordinator) {
        shouldUnregister = YES;
    } else if ([self isRegisteredForCoordinator:coordinator]) {
        shouldUnregister = YES;
    } else {
        shouldUnregister = NO;
    }
    
    if (shouldUnregister) {
        [self.notificationCenter
         removeObserver:self
         name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:coordinator];
        [self.notificationCenter
         removeObserver:self
         name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:coordinator];
        [self.notificationCenter
         removeObserver:self
         name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];
    }
}

#pragma mark - Notification Methods
- (void)storesWillChangeWithNotification:(NSNotification *)notification
{
    NSPersistentStoreCoordinator *coordinatorFromNotification = (NSPersistentStoreCoordinator *)notification.object;
    __weak typeof(self)weakSelf = self;
    [self forAllDelegatesWithCoordinator:coordinatorFromNotification applyBlock:^(id<DCStorageEventNotificationManagerDelegate> delegate) {
        [delegate storageEventNotificationManager:weakSelf
           didReceiveStoresWillChangeNotification:notification
                       persistentStoreCoordinator:coordinatorFromNotification];
    }];
}

- (void)storesDidChangeWithNotification:(NSNotification *)notification
{
    NSPersistentStoreCoordinator *coordinatorFromNotification = (NSPersistentStoreCoordinator *)notification.object;
    __weak typeof(self)weakSelf = self;
    [self forAllDelegatesWithCoordinator:coordinatorFromNotification applyBlock:^(id<DCStorageEventNotificationManagerDelegate> delegate) {
        [delegate storageEventNotificationManager:weakSelf
            didReceiveStoresDidChangeNotification:notification
                       persistentStoreCoordinator:coordinatorFromNotification];
    }];
}

- (void)didImportUbiquitousContentChangesWithNotification:(NSNotification *)notification
{
    NSPersistentStoreCoordinator *coordinatorFromNotification = (NSPersistentStoreCoordinator *)notification.object;
    __weak typeof(self)weakSelf = self;
    [self forAllDelegatesWithCoordinator:coordinatorFromNotification applyBlock:^(id<DCStorageEventNotificationManagerDelegate> delegate) {
        [delegate storageEventNotificationManager:weakSelf
                    didReceiveContentImportNotification:notification
                       persistentStoreCoordinator:coordinatorFromNotification];
    }];
}

#pragma mark - Internal Helper Methods
- (BOOL)isRegisteredForCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    NSParameterAssert(coordinator != nil);
    for (DCDelegateAndCoordinator *delegateAndCoordinator in self.delegateAndCoordinators) {
        NSPersistentStoreCoordinator *currentCoordinator = delegateAndCoordinator.coordinator;
        if (currentCoordinator == coordinator) {
            return YES;
        }
    }
    return NO;
}

- (void)forAllDelegatesWithCoordinator:(NSPersistentStoreCoordinator *)coordinator
                            applyBlock:(void (^)(id <DCStorageEventNotificationManagerDelegate>delegate))block
{
    NSParameterAssert(block != nil);
    for (DCDelegateAndCoordinator *delegateAndCoordinator in self.delegateAndCoordinators) {
        NSPersistentStoreCoordinator *currentCoordinator = delegateAndCoordinator.coordinator;
        if (currentCoordinator == coordinator) {
            block(delegateAndCoordinator.delegate);
        }
    }
}
@end
