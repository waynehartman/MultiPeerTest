//
//  MPTChatBar.m
//  MultiPeerTest
//
//  Created by Wayne on 10/30/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTChatBar.h"

@interface MPTChatBar () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *sendButton;

@end

@implementation MPTChatBar

+ (instancetype)chatBarWithNibName:(NSString *)nibName {
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil];

    MPTChatBar *chatBar = nil;

    for (id object in objects) {
        if ([object isKindOfClass:[MPTChatBar class]]) {
            chatBar = object;
            break;
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:chatBar
                                             selector:@selector(textFieldTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:chatBar.textField];

    return chatBar;
}

- (IBAction)didSelectSendButton:(id)sender {
    if (self.chatHandler) {
        self.chatHandler([self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
    }

    self.textField.text = @"";
    self.sendButton.enabled = NO;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)resignFirstResponder {
    return [self.textField resignFirstResponder];
}

- (BOOL)becomeFirstResponder {
    BOOL becameFirstResponder = [self.textField becomeFirstResponder];

    return becameFirstResponder;
}

- (BOOL)isValidMessage {
    BOOL isValid = YES;

    NSString *message = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    isValid = message.length > 0;

    return isValid;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self isValidMessage]) {
        [self didSelectSendButton:textField];
    }

    return NO;
}

#pragma mark - Notifications

- (void)textFieldTextDidChange:(NSNotification *)notification {
    self.sendButton.enabled = [self isValidMessage];
}

#pragma mark - Memory Management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
