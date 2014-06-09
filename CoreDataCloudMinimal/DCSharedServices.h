//
//  DCSharedServices.h
//  iCloudAndCoreData
//
//  Created by Claes Lillieskold on 2014-05-30.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCUserDefaults.h"

@interface DCSharedServices : NSObject
@property (strong, nonatomic) NSBundle *mainBundle;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@property (readonly, nonatomic) BOOL persistentStore;

+ (instancetype)sharedServicesWithPersistentStore:(BOOL)persistentStore;
+ (instancetype)sharedServices;
@end
