//
//  DCSharedServices.h
//  iCloudAndCoreData
//
//  Created by Claes Lillieskold on 2014-05-30.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCUserDefaults;
@class DCUbiquityIdentityManager;
@class DCStorageEventNotificationManager;


@interface DCSharedServices : NSObject
@property (strong, nonatomic) NSBundle *mainBundle;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@property (strong, nonatomic) DCUbiquityIdentityManager *ubiquityIdentityManager;
@property (strong, nonatomic) DCStorageEventNotificationManager *storageEventNotificationManager;
@property (readonly, nonatomic) BOOL persistentStore;

+ (instancetype)sharedServicesWithPersistentStore:(BOOL)persistentStore;
+ (instancetype)sharedServices;
@end
