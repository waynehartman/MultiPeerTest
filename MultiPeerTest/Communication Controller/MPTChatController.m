//
//  MPTChatController.m
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTChatController.h"
#import "MPTDataController.h"

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MPTChatController () <MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, MCNearbyServiceBrowserDelegate>

@property (nonatomic, strong) MCSession *currentSession;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MPTChatUser *currentUser;

@end

#define SERVICE_TYPE @"whartman-chat"
#define MESSAGE_KEY_MESSAGE @"MESSAGE_KEY_MESSAGE"

@implementation MPTChatController

static MPTChatController *singleton;

+ (instancetype)sharedController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[MPTChatController alloc] init];
    });

    return singleton;
}

- (MPTChatUser *)currentUser {
    if (!_currentUser) {
        MPTChatUser *currentUser = [[MPTDataController sharedController] chatUserWithPeerID:self.peerID.displayName inManagedObjectContext:nil];

        if (!currentUser) {
            currentUser = [[MPTDataController sharedController] createChatUserWithMapping:^(MPTChatUser *chatUser) {
                chatUser.username = self.peerID.displayName;
                chatUser.isLocalUser = @(YES);
            } inManagedObjectContext:nil];

            [currentUser.managedObjectContext save:nil];
        }

        _currentUser = currentUser;
    }

    return _currentUser;
}

- (void)advertiseWithDisplayName:(NSString *)displayName {
    [self endSession];

    self.peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    
    NSLog(@"current user: %@", self.currentUser);
    
    self.currentSession = [[MCSession alloc] initWithPeer:self.peerID];
    self.currentSession.delegate = self;
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID
                                                        discoveryInfo:nil
                                                          serviceType:SERVICE_TYPE];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
}

- (void)inviteNearbyPeersToSessionWithDisplayName:(NSString *)displayName {
    [self endSession];

    self.peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    NSLog(@"current user: %@", self.currentUser);
    self.currentSession = [[MCSession alloc] initWithPeer:self.peerID];
    self.currentSession.delegate = self;
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID
                                                    serviceType:SERVICE_TYPE];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
}

- (void)endSession {
    [self.advertiser stopAdvertisingPeer];
}

- (void)sendMessage:(NSString *)message {
    if (message == nil) {
        return;
    }

    [self ingestMessage:message fromPeer:self.peerID];

    if (self.currentSession.connectedPeers > 0) {
        NSDictionary *messageDict = @{ MESSAGE_KEY_MESSAGE : message };
        NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDict options:0 error:nil];

        NSError *error = nil;

        BOOL queued = [self.currentSession sendData:messageData
                                            toPeers:self.currentSession.connectedPeers
                                           withMode:MCSessionSendDataReliable
                                              error:&error];

        if (!queued) {
            NSLog(@"Error enqueuing the message! %@", error);
        }
    }
}

- (void)ingestMessage:(NSString *)message fromPeer:(MCPeerID *)peerID {
    NSManagedObjectContext *context = [[MPTDataController sharedController] createManagedObjectContextForBackgroundThread];

    [context performBlock:^{
        MPTChatUser *user = nil;

        if (peerID != nil) {
            user = [[MPTDataController sharedController] chatUserWithPeerID:peerID.displayName inManagedObjectContext:context];

            if (user == nil) {
                user = [[MPTDataController sharedController] createChatUserWithMapping:^(MPTChatUser *chatUser) {
                    chatUser.username = peerID.displayName;
                } inManagedObjectContext:context];
            }
        }

        [[MPTDataController sharedController] createChatMessageWithMapping:^(MPTChatMessage *chatMessage) {
            chatMessage.user = user;
            chatMessage.messageText = message;
            chatMessage.receivedTime = [NSDate date];
        } inManagedObjectContext:context];

        NSError *error = nil;
        BOOL saved = [context save:&error];
        
        if (!saved) {
            NSLog(@"error ingesting message! %@", error);
        }
    }];
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"recieved invitation from peer.");
    invitationHandler(YES, self.currentSession);    // In most cases you might want to give users an option to connect or not.
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"unable to advertise! %@", error);
}

#pragma mark - MCSessionDelegate

// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSLog(@"Peer did change state: %i", state);
    NSString *action = nil;

    switch (state) {
        case MCSessionStateConnected: {
            action = @"is now connected";
        }
        break;
        case MCSessionStateConnecting: {
            action = @"is connecting";
        }
        case MCSessionStateNotConnected: {
            action = @"disconnected.";
        }
        break;
    }

    NSString *message = [NSString stringWithFormat:@"%@ %@...", peerID.displayName, action];

    [self ingestMessage:message fromPeer:nil];
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSLog(@"Received Message...");
    NSError *error = nil;

    NSDictionary *recievedData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (!recievedData) {
        NSLog(@"error decoding message! %@", error);
    } else {
        [self ingestMessage:recievedData[MESSAGE_KEY_MESSAGE] fromPeer:peerID];
    }
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"found peer! %@", peerID);
    [browser invitePeer:peerID
              toSession:self.currentSession
            withContext:nil
                timeout:5.0];
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSString *message = [NSString stringWithFormat:@"%@ was disconnected...", peerID.displayName];

    [self ingestMessage:message fromPeer:nil];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"error browsing!!! %@", error);
}

@end
