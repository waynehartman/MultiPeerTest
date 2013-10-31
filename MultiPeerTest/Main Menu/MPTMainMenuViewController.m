//
//  MPTMainMenuViewController.m
//  MultiPeerTest
//
//  Created by Wayne on 10/30/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTMainMenuViewController.h"
#import "MPTChatController.h"
#import "UIAlertView+Blocks.h"

typedef NS_ENUM(NSInteger, TableRow) {
    TableRowAdvertise = 0,
    TableRowBrowse
};

@interface MPTMainMenuViewController ()

@end

#define SEGUE_SHOW_CHAT_VIEW @"SEGUE_SHOW_CHAT_VIEW"

@implementation MPTMainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    void(^action)(NSString *displayName) = NULL;

    TableRow row = indexPath.row;

    switch (row) {
        case TableRowAdvertise: {
            action = ^(NSString *displayName) {
                [[MPTChatController sharedController] advertiseWithDisplayName:displayName];
                [self performSegueWithIdentifier:SEGUE_SHOW_CHAT_VIEW sender:nil];
            };
        }
        break;
        case TableRowBrowse: {
            action = ^(NSString *displayName) {
                [[MPTChatController sharedController] inviteNearbyPeersToSessionWithDisplayName:displayName];
                [self performSegueWithIdentifier:SEGUE_SHOW_CHAT_VIEW sender:nil];
            };
        }
        break;
    }

    RIButtonItem *item = [RIButtonItem itemWithLabel:@"OK"];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Display Name"
                                                    message:nil
                                           cancelButtonItem:[RIButtonItem itemWithLabel:@"Cancel"]
                                           otherButtonItems:item, nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    item.action = ^{
        NSString *displayName = [[[alert textFieldAtIndex:0] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if (displayName.length > 0) {
            action(displayName);
        } else {
            [self tableView:tableView didSelectRowAtIndexPath:indexPath];
        }
    };

    [alert show];
}

@end
