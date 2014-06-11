//
//  DCUbiquityIdentityManager.m
//  CoreDataCloudMinimal2
//
//  Created by Claes Lillieskold on 2014-06-11.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCUbiquityIdentityManager.h"
#import "DCSharedServices.h"
#import "DCUserDefaults.h"

@interface DCUbiquityIdentityManager()
@property (strong, nonatomic) NSMutableArray *delegates;
@property (assign, nonatomic) BOOL pendingIdentityChange;
@property (readonly, nonatomic) id <NSObject, NSCopying, NSCoding> currentIdentity;
@property (strong, nonatomic) id <NSObject, NSCopying, NSCoding> storedIdentity;
@property (strong, nonatomic) NSFileManager *fileManager;
@property (strong, nonatomic) DCUserDefaults *userDefaults;
@end

@implementation DCUbiquityIdentityManager
#pragma mark - Life Cycle
+ (instancetype)ubiquityIdentityManager
{
    return [[DCUbiquityIdentityManager alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        self.delegates = [NSMutableArray new];
        self.fileManager = [NSFileManager defaultManager];
        self.userDefaults = [DCSharedServices sharedServices].userDefaults;
        [self registerForIdentityChanges];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterForIdentityChanges];
}

#pragma mark - Public Methods
- (BOOL)hasPendingIdentityChange
{
    return self.pendingIdentityChange;
}

- (void)savePendingChangedIdentity
{
    if (self.pendingIdentityChange) {
        self.userDefaults.storedAccessIdentity = self.currentIdentity;
        self.pendingIdentityChange = NO;
    }
}

- (void)addDelegate:(id <DCUbiquityIdentityManagerDelegate>)delegate
{
    if (![self.delegates containsObject:delegate]) {
        [self.delegates addObject:delegate];
    }
}

- (void)removeDelegate:(id <DCUbiquityIdentityManagerDelegate>)delegate
{
    if ([self.delegates containsObject:delegate]) {
        [self.delegates removeObject:delegate];
    }
}

- (BOOL)isDelegate:(id <DCUbiquityIdentityManagerDelegate>)delegate
{
    return [self.delegates containsObject:delegate];
}

#pragma mark - Identity Changes
- (void)registerForIdentityChanges
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    __weak typeof(self)weakSelf = self;
    [notificationCenter addObserverForName:NSUbiquityIdentityDidChangeNotification object:nil
                                     queue:mainQueue usingBlock:^(NSNotification *note) {
                                         [weakSelf identityDidChangeWithNotification:note];
                                     }];
}

- (void)unregisterForIdentityChanges
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NSUbiquityIdentityDidChangeNotification object:nil];
}

- (void)identityDidChangeWithNotification:(NSNotification *)notification
{
    self.pendingIdentityChange = YES;
    id <NSObject, NSCopying, NSCoding> fromIdentity = self.storedIdentity;
    id <NSObject, NSCopying, NSCoding> toIdentity = self.currentIdentity;
    for (id <DCUbiquityIdentityManagerDelegate> delegate in self.delegates) {
        [delegate ubiquityIdentityManager:self
                    didChangeFromIdentity:fromIdentity
                               toIdentity:toIdentity];
    }
}

#pragma mark - Properties
- (id <NSObject, NSCopying, NSCoding>)currentIdentity
{
    return self.fileManager.ubiquityIdentityToken;
}

- (id <NSObject, NSCopying, NSCoding>)storedIdentity
{
    return self.userDefaults.storedAccessIdentity;
}

- (void)setStoredIdentity:(id<NSObject,NSCopying,NSCoding>)storedIdentity
{
    self.userDefaults.storedAccessIdentity = storedIdentity;
}
@end
