//
//  MPTChatCell.m
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTChatCell.h"
#import "MPTChatUser.h"

@interface MPTChatCell ()

@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UILabel *userLabel;
@property (strong, nonatomic) IBOutlet UIButton *attachmentPreviewButton;

@end

@implementation MPTChatCell

- (void)setMessage:(MPTChatMessage *)message {
    _message = message;

    self.messageLabel.text = message.messageText;
    self.userLabel.text = message.user.username;
}

- (IBAction)didSelectPreviewButton:(id)sender {
    [self.delegate chatCell:self didSelectAttachmentForMessage:self.message];
}

@end
