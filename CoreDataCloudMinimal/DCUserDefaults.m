//
//  DCUserDefaults.m
//  DailyCheck
//
//  Created by Claes Lillieskold on 2014-03-11.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import "DCUserDefaults.h"

NSString * const DCUbiquityIdentityTokenKey = @"com.lillysoft.DailyCheck.ubiquityIdentityToken";
NSString * const DCQuestionnaireIdentityKey = @"com.lillysoft.DailyCheck.questionnaireIdentity";

@interface DCUserDefaults ()
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (assign, nonatomic) BOOL persistentStore;
@end

@implementation DCUserDefaults
@synthesize storedAccessIdentity = _storedAccessIdentity;
@synthesize questionnaireIdentity = _questionnaireIdentity;
@synthesize persistentStore = _persistentStore;

#pragma mark - Create And Init
- (instancetype)initWithPersistentStore:(BOOL)persistentStore
{
    self = [super init];
    if (self) {
        self.persistentStore = persistentStore;
        if (persistentStore) {
            self.userDefaults = [NSUserDefaults standardUserDefaults];
        } else {
            self.userDefaults = nil;
        }
    }
    return self;
}

- (instancetype)init
{
    return [self initWithPersistentStore:NO];
}

#pragma mark - Public Interface
- (id <NSObject, NSCopying, NSCoding>)storedAccessIdentity
{
    if (self.persistentStore) {
        _storedAccessIdentity = [self.userDefaults objectForKey:DCUbiquityIdentityTokenKey];
    }
    return _storedAccessIdentity;
}

- (void)setStoredAccessIdentity:(id<NSObject,NSCopying,NSCoding>)storedAccessIdentity
{
    _storedAccessIdentity = storedAccessIdentity;
    if (_storedAccessIdentity == nil) {
        [self.userDefaults removeObjectForKey:DCUbiquityIdentityTokenKey];
    } else {
        [self.userDefaults setObject:_storedAccessIdentity forKey:DCUbiquityIdentityTokenKey];
    }
    [self.userDefaults synchronize];
}

- (NSString *)questionnaireIdentity
{
    if (self.persistentStore) {
        _questionnaireIdentity = [self.userDefaults objectForKey:DCQuestionnaireIdentityKey];
    }
    return _questionnaireIdentity;
}

- (void)setQuestionnaireIdentity:(NSString *)questionnaireIdentity
{
    _questionnaireIdentity = questionnaireIdentity;
    if (_questionnaireIdentity == nil) {
        [self.userDefaults removeObjectForKey:DCUbiquityIdentityTokenKey];
    } else {
        [self.userDefaults setObject:_questionnaireIdentity forKey:DCQuestionnaireIdentityKey];
    }
    [self.userDefaults synchronize];
}
@end