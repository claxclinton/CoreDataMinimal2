//
//  DCUserDefaults.h
//  DailyCheck
//
//  Created by Claes Lillieskold on 2014-03-11.
//  Copyright (c) 2014 Claes Lillieskold. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCUserDefaults : NSObject
@property (strong, nonatomic) id <NSObject, NSCopying, NSCoding> storedAccessIdentity;
@property (strong, nonatomic) NSString *questionnaireIdentity;
@property (readonly, nonatomic) BOOL persistentStore;

- (instancetype)initWithPersistentStore:(BOOL)persistentStore;
@end
