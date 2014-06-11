//
//  DCStorageEventManager.h
//  CoreDataCloudMinimal2
//
//  Created by Claes Lillieskold on 2014-06-11.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCStorageEventNotificationManager;

@protocol DCStorageEventNotificationManagerDelegate <NSObject>
- (void)storageEventNotificationManager:(DCStorageEventNotificationManager *)storageEventManager
 didReceiveStoresWillChangeNotification:(NSNotification *)notification
             persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (void)storageEventNotificationManager:(DCStorageEventNotificationManager *)storageEventManager
  didReceiveStoresDidChangeNotification:(NSNotification *)notification
             persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (void)storageEventNotificationManager:(DCStorageEventNotificationManager *)storageEventManager
    didReceiveContentImportNotification:(NSNotification *)notification
             persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
@end

@interface DCStorageEventNotificationManager : NSObject
+ (instancetype)storageEventManager;
- (void)addDelegate:(id <DCStorageEventNotificationManagerDelegate>)delegate
     forCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (void)removeDelegate:(id <DCStorageEventNotificationManagerDelegate>)delegate
        forCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
@end
