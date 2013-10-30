//
//  MPTAppDelegate.m
//  MultiPeerTest
//
//  Created by Wayne on 10/24/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTAppDelegate.h"
#import "MPTDataController.h"

@implementation MPTAppDelegate

- (void)createTestData {
    MPTDataController *dataController = [MPTDataController sharedController];
    
    MPTChatUser *wayne = [dataController createChatUserWithMapping:^(MPTChatUser *chatUser) {
        chatUser.username = @"Wayne";
        chatUser.isLocalUser = @(YES);
    } inManagedObjectContext:nil];

    MPTChatUser *erin = [dataController createChatUserWithMapping:^(MPTChatUser *chatUser) {
        chatUser.username = @"Erin";
        chatUser.isLocalUser = @(NO);
    } inManagedObjectContext:nil];

    MPTChatMessage *systemMessage = [dataController createChatMessageWithMapping:^(MPTChatMessage *chatMessage) {
        chatMessage.messageText = @"Erin joined the conversation...";
        chatMessage.receivedTime = [NSDate date];
    } inManagedObjectContext:nil];
    
    MPTChatMessage *localMessage = [dataController createChatMessageWithMapping:^(MPTChatMessage *chatMessage) {
        chatMessage.messageText = @"hello";
        chatMessage.user = wayne;
        chatMessage.receivedTime = [NSDate date];
    } inManagedObjectContext:nil];
    
    MPTChatMessage *remoteMessage = [dataController createChatMessageWithMapping:^(MPTChatMessage *chatMessage) {
        chatMessage.messageText = @"This is a really long message so that I can see that the view is resizing correctly.";
        chatMessage.user = erin;
        chatMessage.receivedTime = [NSDate date];
    } inManagedObjectContext:nil];

    [dataController.managedObjectContext save:nil];

    NSLog(@"%@\n\n%@\n\n%@", systemMessage, localMessage, remoteMessage);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    [self createTestData];

    return YES;
}

@end
