//
//  MPTChatController.m
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTChatController.h"
#import "MPTDataController.h"
#import "UIImage+Resize.h"

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MPTChatController () <MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, MCNearbyServiceBrowserDelegate>

@property (nonatomic, strong) MCSession *currentSession;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MPTChatUser *currentUser;
@property (nonatomic, strong) MCPeerID *browserPeerID;

@end

#define SERVICE_TYPE @"whartman-chat"
#define MESSAGE_KEY_MESSAGE @"MESSAGE_KEY_MESSAGE"

@implementation MPTChatController

#pragma mark - External Methods

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

    [self ingestMessage:@"Waiting to be invited to a session..." attachmentURL:nil thumbnailURL:nil fromPeer:nil];
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

    [self ingestMessage:@"Looking for peers..." attachmentURL:nil thumbnailURL:nil fromPeer:nil];
}

- (void)endSession {
    [self.advertiser stopAdvertisingPeer];
    [self.currentSession disconnect];
}

- (void)sendMessage:(NSString *)message {
    if (message == nil) {
        return;
    }

    [self ingestMessage:message attachmentURL:nil thumbnailURL:nil fromPeer:self.peerID];

    if (self.currentSession.connectedPeers.count > 0) {
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

- (void)sendImage:(UIImage *)image {
    //  Block we'll call for sending the message when it has been prepared
    void(^sendImage)(NSURL *) = ^(NSURL *imageURL) {
        for (MCPeerID *peer in self.currentSession.connectedPeers) {
            [self.currentSession sendResourceAtURL:imageURL
                                          withName:@"image.jpg"
                                            toPeer:peer
                             withCompletionHandler:^(NSError *error) {
                                 if (error) {
                                     NSLog(@"Error sending image! %@", error);
                                 }
                             }];
        }
    };

    //  Do all our work on a background thread
    dispatch_async(dispatch_queue_create("com.waynehartman.multipeertest.imageprocessing", NULL), ^{
        NSURL *thumbnailURL = [self createFileURL];
        NSURL *scaledURL = [self createFileURL];

        CGFloat scaleFactor = 0.33f;

        NSData *thumbnailData = nil;
        NSData *scaledImageData = nil;

        //  Using an autorelease pool to flush memory we don't need anymore
        @autoreleasepool {
            UIImage *scaledImage = [image resizedImage:CGSizeMake(image.size.width * scaleFactor, image.size.height * scaleFactor)
                                  interpolationQuality:kCGInterpolationHigh];
            UIImage *thumbnail = [image thumbnailImage:150
                                     transparentBorder:0
                                          cornerRadius:0
                                  interpolationQuality:kCGInterpolationMedium];
            thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.75f);
            scaledImageData = UIImageJPEGRepresentation(scaledImage, 0.75f);
        }

        //  Write everything to disk so we can reference it later
        NSFileManager *fm = [NSFileManager defaultManager];

        [fm createFileAtPath:scaledURL.path
                    contents:scaledImageData
                  attributes:nil];
        [fm createFileAtPath:thumbnailURL.path
                    contents:thumbnailData
                  attributes:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self ingestMessage:nil attachmentURL:scaledURL thumbnailURL:thumbnailURL fromPeer:self.peerID];
            sendImage(scaledURL);
        });
    });
}

#pragma mark - Internal Methods

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

- (NSURL *)createFileURL {
    NSString *fileName = [[NSUUID UUID] UUIDString];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", NSTemporaryDirectory(), fileName];

    return [NSURL fileURLWithPath:filePath];
}

- (void)ingestMessage:(NSString *)message attachmentURL:(NSURL *)attachmentURL thumbnailURL:(NSURL *)thumbnailURL fromPeer:(MCPeerID *)peerID {
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
            chatMessage.attachmentUri = attachmentURL.path;
            chatMessage.attachmentThumbnailUri = thumbnailURL.path;
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
    NSString *message = [NSString stringWithFormat:@"Received invitation from %@. Joining...", peerID.displayName];
    [self ingestMessage:message attachmentURL:nil thumbnailURL:nil fromPeer:nil];

    invitationHandler(YES, self.currentSession);    // In most cases you might want to give users an option to connect or not.
    [self.advertiser stopAdvertisingPeer];  //  Once invited, stop advertising
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"unable to advertise! %@", error);
}

#pragma mark - MCSessionDelegate

// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSLog(@"Peer did change state: %li", state);
    NSString *action = nil;

    switch (state) {
        case MCSessionStateConnected: {
            action = @"is now connected";
        }
            break;
        case MCSessionStateConnecting: {
            action = @"is connecting";
        }
            break;
        case MCSessionStateNotConnected: {
            action = @"disconnected";
            
            //  If I'm not the browser and the peer that dropped is the browser...
            if (![peerID isEqual:self.peerID] &&
                [peerID isEqual:self.browserPeerID])
            {
                [self.advertiser startAdvertisingPeer]; //  start advertising so the browser can find us again.
            }
        }
            break;
    }

    NSString *message = [NSString stringWithFormat:@"%@ %@...", peerID.displayName, action];

    [self ingestMessage:message attachmentURL:nil thumbnailURL:nil fromPeer:nil];
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSLog(@"Received Message...");
    NSError *error = nil;

    NSDictionary *recievedData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (!recievedData) {
        NSLog(@"error decoding message! %@", error);
    } else {
        [self ingestMessage:recievedData[MESSAGE_KEY_MESSAGE]
              attachmentURL:nil
               thumbnailURL:nil
                   fromPeer:peerID];
    }
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    NSLog(@"downloading file: %f%%", progress.fractionCompleted);
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    NSLog(@"finished receiving file...");
    
    if (error) {
        NSLog(@"Error when receiving file! %@", error);
    } else {
        dispatch_async(dispatch_queue_create("com.waynehartman.multipeertest.imagereception", NULL), ^{
            NSData *imageData = nil;
            NSData *thumbnailData = nil;

            @autoreleasepool {
                UIImage *image = [UIImage imageWithContentsOfFile:localURL.path];
                UIImage *thumbnail = [image thumbnailImage:150
                                         transparentBorder:0
                                              cornerRadius:0
                                      interpolationQuality:kCGInterpolationMedium];
                imageData = UIImageJPEGRepresentation(image, 1.0f);
                thumbnailData = UIImageJPEGRepresentation(thumbnail, 1.0f);
            }

            NSURL *imageURL = [self createFileURL];
            NSURL *thumbnailURL = [self createFileURL];

            NSFileManager *fm = [NSFileManager defaultManager];
            [fm createFileAtPath:imageURL.path contents:imageData attributes:nil];
            [fm createFileAtPath:thumbnailURL.path contents:thumbnailData attributes:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self ingestMessage:nil attachmentURL:imageURL thumbnailURL:thumbnailURL fromPeer:peerID];
            });
        });
    }
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSString *message = [NSString stringWithFormat:@"Sending an invitation to %@ to join the chat...", peerID.displayName];

    [self ingestMessage:message attachmentURL:nil thumbnailURL:nil fromPeer:nil];

    [browser invitePeer:peerID
              toSession:self.currentSession
            withContext:nil
                timeout:3.0];
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSString *message = [NSString stringWithFormat:@"%@ was disconnected...", peerID.displayName];

    [self ingestMessage:message attachmentURL:nil thumbnailURL:nil fromPeer:nil];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"error browsing!!! %@", error);
}

- (void)dealloc {
    [self endSession];
    [self.advertiser stopAdvertisingPeer];
    [self.browser stopBrowsingForPeers];
}

@end
