//
//  MPTChatViewController.m
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTChatViewController.h"
#import "MPTImageViewController.h"
#import "MPTChatDataSource.h"
#import "MPTChatBar.h"
#import "MPTChatController.h"
#import "MPTDataController.h"

#import "UIActionSheet+Blocks.h"

@interface MPTChatViewController () <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) IBOutlet MPTChatDataSource *dataSource;
@property (strong, nonatomic) IBOutlet UITextField *firstResponderField;
@property (nonatomic, strong) MPTChatBar *chatBar;

@end

#define SEGUE_IMAGE_PREVIEW @"SEGUE_IMAGE_PREVIEW"

@implementation MPTChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.chatBar = [MPTChatBar chatBarWithNibName:@"MPTChatBar"];
    self.firstResponderField.inputAccessoryView = self.chatBar;

    __weak MPTChatViewController *weakSelf = self;

    self.chatBar.chatHandler = ^(NSString *message) {
        [weakSelf.chatController sendMessage:message];
    };

    self.chatBar.cameraHandler = ^{
        UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
        pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        pickerController.delegate = weakSelf;

        [weakSelf presentViewController:pickerController animated:YES completion:NULL];
    };
    
    self.dataSource.attachmentPreviewHandler = ^(NSString *path) {
        [weakSelf performSegueWithIdentifier:SEGUE_IMAGE_PREVIEW sender:path];
    };
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.navigationController.view insertSubview:self.firstResponderField atIndex:0];
    [self.firstResponderField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.chatBar resignFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:SEGUE_IMAGE_PREVIEW]) {
        MPTImageViewController *imageVC = segue.destinationViewController;
        imageVC.image = [UIImage imageWithContentsOfFile:sender];
    }
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

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:NULL];

    [self.chatController sendImage:info[UIImagePickerControllerOriginalImage]];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
