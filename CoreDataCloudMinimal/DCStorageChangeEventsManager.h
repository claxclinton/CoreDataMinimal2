//
//  DCStorageEventManager.h
//  CoreDataCloudMinimal2
//
//  Created by Claes Lillieskold on 2014-06-11.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCStorageChangeEventsManager;

@protocol DCStorageChangeEventsManagerDelegate <NSObject>
- (void)storageChangeEventsManager:(DCStorageChangeEventsManager *)manager
didReceiveStoresWillChangeNotification:(NSNotification *)notification
        persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (void)storageChangeEventsManager:(DCStorageChangeEventsManager *)manager
didReceiveStoresDidChangeNotification:(NSNotification *)notification
        persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (void)storageChangeEventsManager:(DCStorageChangeEventsManager *)manager
didReceiveContentImportNotification:(NSNotification *)notification
        persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
@end

@interface DCStorageChangeEventsManager : NSObject
+ (instancetype)storageEventManager;
- (void)addDelegate:(id <DCStorageChangeEventsManagerDelegate>)delegate
     forCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (void)removeDelegate:(id <DCStorageChangeEventsManagerDelegate>)delegate
        forCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
@end
