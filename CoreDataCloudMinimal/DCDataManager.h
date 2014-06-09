//
//  DCDataManager.h
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-07.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCDataManager;
@class DCData;

typedef NS_ENUM(NSUInteger, DCPersistentStorageType) {
    DCPersistentStorageTypeNone = 0,
    DCPersistentStorageTypeLocal,
    DCPersistentStorageTypeCloud
};

@protocol DCDataManagerDelegate <NSObject>
@required
- (void)dataManagerDelegate:(DCDataManager *)dataManager
         shouldLockInterace:(BOOL)lockInterface;
- (void)dataManagerDelegate:(DCDataManager *)dataManager
          accessDataAllowed:(BOOL)accessDataAllowed;
- (void)dataManagerDelegate:(DCDataManager *)dataManager
               shouldReload:(BOOL)shouldReload;
@optional
- (void)dataManagerDelegate:(DCDataManager *)dataManager
     didChangeToStorageType:(DCPersistentStorageType)storageType;
- (void)dataManagerDelegate:(DCDataManager *)dataManager
 didChangeUbiquityTokenFrom:(id)fromToken
            toUbiquityToken:(id)toToken;
@end

@interface DCDataManager : NSObject
@property (strong, readonly, nonatomic) id <NSObject, NSCopying, NSCoding> ubiquityIdentityToken;

+ (instancetype)dataManagerWithModelName:(NSString *)modelName
                                delegate:(id <DCDataManagerDelegate>)delegate;
- (void)removeStorage;
- (void)addLocalStorage;
- (void)addCloudStorage;
- (DCData *)insertDataItem;
- (NSArray *)sortedData;
@end
