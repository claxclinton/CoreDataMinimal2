//
//  DCUserDefaults.h
//  DailyCheck
//
//  Created by Claes Lillieskold on 2014-03-11.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCStorageType.h"

@interface DCUserDefaults : NSObject
@property (readonly, nonatomic) BOOL persistentStore;
@property (strong, nonatomic) id <NSObject, NSCopying, NSCoding> storedAccessIdentity;
@property (strong, nonatomic) NSString *questionnaireIdentity;
@property (assign, nonatomic) DCStorageType storageType;
@property (assign, nonatomic) BOOL hasAskedForCloudStorage;

+ (instancetype)userDefaultsWithPersistentStore:(BOOL)persistentStore;
@end
