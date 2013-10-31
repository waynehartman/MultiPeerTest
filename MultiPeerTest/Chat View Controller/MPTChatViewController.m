//
//  MPTChatViewController.m
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTChatViewController.h"
#import "MPTChatDataSource.h"
#import "MPTChatBar.h"
#import "MPTChatController.h"
#import "MPTDataController.h"

@interface MPTChatViewController () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet MPTChatDataSource *dataSource;
@property (strong, nonatomic) IBOutlet UITextField *firstResponderField;
@property (nonatomic, strong) MPTChatBar *chatBar;

@end

@implementation MPTChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.chatBar = [MPTChatBar chatBarWithNibName:@"MPTChatBar"];
    self.firstResponderField.inputAccessoryView = self.chatBar;

    self.chatBar.chatHandler = ^(NSString *message) {
        [[MPTChatController sharedController] sendMessage:message];
    };
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.navigationController.view insertSubview:self.firstResponderField atIndex:0];
    [self.firstResponderField becomeFirstResponder];
}

#pragma mark - Actions

- (IBAction)didSelectClearButton:(id)sender {
    [[MPTDataController sharedController] deleteAllChatMessagesInManagedObjectContext:nil];
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    double delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.firstResponderField.hidden = YES;
        [self.chatBar becomeFirstResponder];
    });
}

@end
