//
//  MPTChatUser.h
//  MultiPeerTest
//
//  Created by Wayne on 10/31/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MPTChatMessage;

@interface MPTChatUser : NSManagedObject

@property (nonatomic, retain) NSNumber * isLocalUser;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *messages;
@end

@interface MPTChatUser (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(MPTChatMessage *)value;
- (void)removeMessagesObject:(MPTChatMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
