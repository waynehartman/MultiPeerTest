//
//  MPTChatDataSource.m
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTChatDataSource.h"
#import "MPTDataController.h"
#import "MPTChatCell.h"

@interface MPTChatDataSource () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *messagesFRC;

@property (nonatomic, strong) MPTChatCell *systemCell;
@property (nonatomic, strong) MPTChatCell *peerCell;
@property (nonatomic, strong) MPTChatCell *userCell;

@end

@implementation MPTChatDataSource

- (instancetype)init {
    if ((self = [super init])) {
        [self.messagesFRC performFetch:nil];
    }
    
    return self;
}

- (NSFetchedResultsController *)messagesFRC {
    if (!_messagesFRC) {
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([MPTChatMessage class])];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"receivedTime" ascending:YES]];

        NSFetchedResultsController *resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                            managedObjectContext:[MPTDataController sharedController].managedObjectContext
                                                                                              sectionNameKeyPath:nil
                                                                                                       cacheName:nil];
        resultsController.delegate = self;
        _messagesFRC = resultsController;
    }

    return _messagesFRC;
}

#pragma mark - UITableViewDataSource

static NSString *userChatCellID = @"userChatCell";
static NSString *peerChatCellID = @"peerChatCell";
static NSString *systemChateCellID = @"systemChatCell";


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [self.messagesFRC.sections[section] numberOfObjects];
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MPTChatMessage *message = [self.messagesFRC objectAtIndexPath:indexPath];
    
    NSString *cellID = [self cellIdForMessage:message];

    MPTChatCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    cell.message = message;
    
    return cell;
}

- (NSString *)cellIdForMessage:(MPTChatMessage *)message {
    NSString *cellID = nil;
    if (message.user == nil) {
        cellID = systemChateCellID;
    } else if ([[message.user isLocalUser] boolValue]) {
        cellID = userChatCellID;
    } else {
        cellID = peerChatCellID;
    }

    return cellID;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MPTChatMessage *message = [self.messagesFRC objectAtIndexPath:indexPath];
    
    MPTChatCell *cell = [tableView dequeueReusableCellWithIdentifier:[self cellIdForMessage:message]];
    cell.message = message;
    
    CGSize size = [cell.sizingView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

    return size.height + 20;
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
            [self.tableView scrollToRowAtIndexPath:newIndexPath
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:YES];
        }
        break;
        case NSFetchedResultsChangeDelete: {
            //  DO NOTHING
        }
        break;
        case NSFetchedResultsChangeUpdate: {
            //  DO NOTHING
        }
        break;
        case NSFetchedResultsChangeMove: {
            //  DO NOTHING
        }
        break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

@end
