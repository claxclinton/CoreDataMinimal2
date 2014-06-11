//
//  DCUbiquityIdentityManager.h
//  CoreDataCloudMinimal2
//
//  Created by Claes Lillieskold on 2014-06-11.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCUbiquityIdentityManager;

@protocol DCUbiquityIdentityManagerDelegate
- (void)ubiquityIdentityManager:(DCUbiquityIdentityManager *)ubiquityIdentityManager
          didChangeFromIdentity:(id <NSObject, NSCopying, NSCoding>)fromIdentity
                     toIdentity:(id <NSObject, NSCopying, NSCoding>)toIdentity;
@end

@interface DCUbiquityIdentityManager : NSObject
+ (instancetype)ubiquityIdentityManager;
- (BOOL)hasPendingIdentityChange;
- (void)savePendingChangedIdentity;
- (void)addDelegate:(id <DCUbiquityIdentityManagerDelegate>)delegate;
- (void)removeDelegate:(id <DCUbiquityIdentityManagerDelegate>)delegate;
- (BOOL)isDelegate:(id <DCUbiquityIdentityManagerDelegate>)delegate;
@end
