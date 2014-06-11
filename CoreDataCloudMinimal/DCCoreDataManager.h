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

@protocol DCCoreDataManagerDelegate <NSObject>
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
didRequestStorageTypeFrom:(NSUInteger)availableStorageTypes
             usingBlock:(void (^)(DCStorageType selectedStorageType))block;
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
      didAddStorageType:(DCStorageType)storageType;
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
     didAllowDataAccess:(BOOL)dataAccessAllowed;
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
didChangeUbiquitousIdentityTo:(id)ubiquitousIdentity;
@end

@interface DCCoreDataManager : NSObject
+ (instancetype)dataManagerWithModelName:(NSString *)modelName
                                delegate:(id <DCCoreDataManagerDelegate>)delegate;
- (void)addPersistentStore;
- (DCData *)insertDataItem;
- (NSArray *)sortedData;
@end
