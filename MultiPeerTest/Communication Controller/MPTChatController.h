//
//  MPTChatController.h
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPTChatController : NSObject

- (void)sendMessage:(NSString *)message;
- (void)sendImage:(UIImage *)image;

- (void)inviteNearbyPeersToSessionWithDisplayName:(NSString *)displayName;
- (void)advertiseWithDisplayName:(NSString *)displayName;
- (void)endSession;

@end
