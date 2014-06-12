//
//  DCDataManager.h
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-07.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "DCStorageType.h"

@class DCCoreDataManager;
@class DCData;

/** The DCCoreDataManagerDelegate handles storage types and permissions.
 * When requesting storage types, the available alternatives are given as well as
 * a block that the implementor should run after deciding which storage type to use.
 * When a storage type is requested, the implementor can show an alert with two options.
 */
@protocol DCCoreDataManagerDelegate <NSObject>
/** Requests which storage type to use and pass the result using the provided block.
 * @param coreDataManager Core data manager.
 * @param availableStorageTypes The types that can be chosen.
 * @param block The block that must be called with the selected storage type.
 */
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
didRequestStorageTypeFrom:(NSUInteger)availableStorageTypes
requestStorageTypeBlock:(void (^)(DCStorageType selectedStorageType))block;

/** Notifies the delegate that the given storage type was chosen by core data manager.
 * @param coreDataManager Core data manager
 * @param storageType The storage type that is in use
 */
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
      didAddStorageType:(DCStorageType)storageType;

/** Notifies the delegate that access to the managed objects is available or not.
 * If access is not allowed the managed objects should not be used.
 * @param coreDataManager Core data manager
 * @param dataAccessAllowed True if managed objects can be used.
 */
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
     didAllowDataAccess:(BOOL)dataAccessAllowed;

/** Notifies the delegate that the ubiquity identity has changed if the current storage
 * type is cloud. The implementer must chose one of the available storage type using the block.
 * @param coreDataManager Core data manager
 * @param ubiquitousIdentity The current ubiquitous identity, or nil if no iCloud acces.
 * @param availableStorageTypes The possible storage type the delegate can choose from.
 * @param block The block that must be called with the chosen storage type.
 */
 - (void)coreDataManager:(DCCoreDataManager *)coreDataManager
didChangeUbiquitousIdentityTo:(id)ubiquitousIdentity
  availableStorageTypes:(NSUInteger)availableStorageTypes
requestStorageTypeBlock:(void (^)(DCStorageType selectedStorageType))block;
@end

/** The DCCoreDataManager implements a basic Core Data Stack with iCloud support, 
 * using a single managed object context and persistent store coordinator.
 * When iCloud changes occur, the delegate is either notified that Local storage is choosen
 * by necessity, or that the delegate needs to provide the next storage type that will be used.
 *
 * Merge is not implemented. When a user changes storage type, no data is merged.
 */
@interface DCCoreDataManager : NSObject
+ (instancetype)dataManagerWithModelName:(NSString *)modelName
                                delegate:(id <DCCoreDataManagerDelegate>)delegate;
- (void)addPersistentStore;
- (DCData *)insertDataItem;
- (NSArray *)sortedData;
@end
