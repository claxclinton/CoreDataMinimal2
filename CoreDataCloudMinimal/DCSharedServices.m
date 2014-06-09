//
//  DCSharedServices.m
//  iCloudAndCoreData
//
//  Created by Claes Lillieskold on 2014-05-30.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCSharedServices.h"
#import "DCUserDefaults.h"

static DCSharedServices *DCSingleton = nil;
static dispatch_once_t DCServicesCreatedOnceToken;

@interface DCSharedServices ()
@property (assign, nonatomic) BOOL persistentStore;
@end

@implementation DCSharedServices
@synthesize userDefaults = _userDefaults;

+ (instancetype)sharedServicesWithPersistentStore:(BOOL)persistentStore
{
    dispatch_once(&DCServicesCreatedOnceToken, ^{
        DCSingleton = [[DCSharedServices alloc] initWithPersistentStore:persistentStore];
    });
    return DCSingleton;
}

+ (instancetype)sharedServices
{
    id sharedServices;
    if (DCSingleton == nil) {
        sharedServices = [DCSharedServices sharedServicesWithPersistentStore:YES];
    } else {
        sharedServices = DCSingleton;
    }
    return sharedServices;
}

- (instancetype)initWithPersistentStore:(BOOL)persistentStore
{
    self = [super init];
    if (self != nil) {
        self.persistentStore = persistentStore;
    }
    return self;
}

- (DCUserDefaults *)userDefaults
{
    if (_userDefaults == nil) {
        _userDefaults = [DCUserDefaults userDefaultsWithPersistentStore:self.persistentStore];
    }
    return _userDefaults;
}

- (NSBundle *)mainBundle
{
    if (_mainBundle == nil) {
        _mainBundle = [NSBundle mainBundle];
    }
    return _mainBundle;
}
@end
