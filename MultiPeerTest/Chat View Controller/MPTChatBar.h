//
//  MPTChatBar.h
//  MultiPeerTest
//
//  Created by Wayne on 10/30/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ChatHandler)(NSString *message);
typedef void(^CameraHandler)(void);

@interface MPTChatBar : UIToolbar

@property (nonatomic, copy) ChatHandler chatHandler;
@property (nonatomic, copy) CameraHandler cameraHandler;

+ (instancetype)chatBarWithNibName:(NSString *)nibName;

@end
