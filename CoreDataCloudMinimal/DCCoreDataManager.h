//
//  DCDataManager.h
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-07.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCCoreDataManager;
@class DCData;

typedef NS_ENUM(NSUInteger, DCStorageType) {
    DCStorageTypeNone = 0,
    DCStorageTypeLocal,
    DCStorageTypeCloud
};

@protocol DCCoreDataManagerDelegate <NSObject>
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
  didRequestStorageType:(DCStorageType *)storageType;
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
      didAddStorageType:(DCStorageType)storageType;
- (void)coreDataManager:(DCCoreDataManager *)coreDataManager
     didAllowDataAccess:(BOOL)dataAccessAllowed;
@end

@interface DCCoreDataManager : NSObject
+ (instancetype)dataManagerWithModelName:(NSString *)modelName
                                delegate:(id <DCCoreDataManagerDelegate>)delegate;
- (void)addPersistentStore;
- (DCData *)insertDataItem;
- (NSArray *)sortedData;
@end
