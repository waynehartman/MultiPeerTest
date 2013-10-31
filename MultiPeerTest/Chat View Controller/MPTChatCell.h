//
//  MPTChatCell.h
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPTChatMessage.h"

@protocol MPTChatCellDelegate;

@interface MPTChatCell : UITableViewCell

@property (nonatomic, strong) MPTChatMessage *message;
@property (nonatomic, weak) id<MPTChatCellDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIView *sizingView;

@end


@protocol MPTChatCellDelegate <NSObject>

- (void)chatCell:(MPTChatCell *)cell didSelectAttachmentForMessage:(MPTChatMessage *)message;

@end
