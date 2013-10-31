//
//  MPTDataController.h
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MPTChatMessage.h"
#import "MPTChatUser.h"

typedef void(^ChatUserMapper)(MPTChatUser *chatUser);
typedef void(^ChatMessageMapper)(MPTChatMessage *chatMessage);

@interface MPTDataController : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (instancetype)sharedController;

- (NSManagedObjectContext *)createManagedObjectContextForBackgroundThread;
- (MPTChatUser *)chatUserWithPeerID:(NSString *)peerID inManagedObjectContext:(NSManagedObjectContext *)context;

- (MPTChatMessage *)createChatMessageWithMapping:(ChatMessageMapper)mapper inManagedObjectContext:(NSManagedObjectContext *)context;
- (MPTChatUser *)createChatUserWithMapping:(ChatUserMapper)mapper inManagedObjectContext:(NSManagedObjectContext *)context;

- (void)deleteAllChatMessagesInManagedObjectContext:(NSManagedObjectContext *)context;

@end
