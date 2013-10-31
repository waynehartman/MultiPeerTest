//
//  MPTChatController.h
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPTChatController : NSObject

+ (instancetype)sharedController;

- (void)sendMessage:(NSString *)message;
- (void)inviteNearbyPeersToSessionWithDisplayName:(NSString *)displayName;
- (void)advertiseWithDisplayName:(NSString *)displayName;
- (void)endSession;

@end
