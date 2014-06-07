//
//  DCDataManager.h
//  CoreDataCloudMinimal
//
//  Created by Claes Lillieskold on 2014-06-07.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCDataManager;

@protocol DCDataManagerDelegate <NSObject>
- (void)dataManagerDelegate:(DCDataManager *)dataManager
         shouldLockInterace:(BOOL)lockInterface;
- (void)dataManagerDelegate:(DCDataManager *)dataManager
          accessDataAllowed:(BOOL)accessDataAllowed;
- (void)dataManagerDelegate:(DCDataManager *)dataManager
               shouldReload:(BOOL)shouldReload;
- (void)dataManagerDelegate:(DCDataManager *)dataManager
 didChangeUbiquityTokenFrom:(id)fromToken
            toUbiquityToken:(id)toToken;
@end

@interface DCDataManager : NSObject
@property (strong, readonly, nonatomic) id <NSObject, NSCopying, NSCoding> ubiquityIdentityToken;

+ (instancetype)dataManagerWithDelegate:(id <DCDataManagerDelegate>)delegate;

@end
