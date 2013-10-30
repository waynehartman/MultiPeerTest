//
//  MPTChatMessage.h
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MPTChatUser;

@interface MPTChatMessage : NSManagedObject

@property (nonatomic, retain) NSString * messageText;
@property (nonatomic, retain) NSString * attachmentUri;
@property (nonatomic, retain) NSDate * receivedTime;
@property (nonatomic, retain) MPTChatUser *user;

@end
