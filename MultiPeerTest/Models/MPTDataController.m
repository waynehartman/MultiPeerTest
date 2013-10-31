//
//  MPTDataController.m
//  MultiPeerTest
//
//  Created by Wayne on 10/29/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTDataController.h"

@interface MPTDataController ()

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation MPTDataController

#pragma mark - Instance Methods

- (MPTChatUser *)chatUserWithPeerID:(NSString *)peerID inManagedObjectContext:(NSManagedObjectContext *)context{
    return [self managedObjectForEntityName:NSStringFromClass([MPTChatUser class])
                              withPredicate:[NSPredicate predicateWithFormat:@"username == %@", peerID]
                     inManagedObjectContext:context];
}

- (MPTChatMessage *)createChatMessageWithMapping:(ChatMessageMapper)mapper inManagedObjectContext:(NSManagedObjectContext *)context {
    return [self createInstanceForEntityName:NSStringFromClass([MPTChatMessage class])
                                 withMapping:mapper
                      inManagedObjectContext:context];
}

- (MPTChatUser *)createChatUserWithMapping:(ChatUserMapper)mapper inManagedObjectContext:(NSManagedObjectContext *)context {
    return [self createInstanceForEntityName:NSStringFromClass([MPTChatUser class])
                                 withMapping:mapper
                      inManagedObjectContext:context];
}

#pragma mark - Singleton

static MPTDataController *sharedController;

+ (instancetype)sharedController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[MPTDataController alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:sharedController
                                                 selector:@selector(contextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
    });

    return sharedController;
}

- (void)deleteAllChatMessagesInManagedObjectContext:(NSManagedObjectContext *)context {
    if (context == nil) {
        context = self.managedObjectContext;
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([MPTChatMessage class])];

    NSArray *messages =[context executeFetchRequest:request error:nil];

    for (MPTChatMessage *message in messages) {
        [context deleteObject:message];
    }

    [context save:nil];
}

#pragma mark - Generic CRUD

- (id)createInstanceForEntityName:(NSString *)entityName withMapping:(void(^__strong)(id))mapping inManagedObjectContext:(NSManagedObjectContext *)context {
    if (context == nil) {
        context = self.managedObjectContext;
    }
    
    NSManagedObject *item = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
    
    if (mapping) {
        mapping(item);
    }
    
    return item;
}

- (id)managedObjectForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate inManagedObjectContext:(NSManagedObjectContext *)context {
    if (context == nil) {
        context = self.managedObjectContext;
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = predicate;
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    if (results == nil) {
        NSLog(@"error fetching!!!\n\n%@", error);
        return nil;
    } else if (results.count > 0) {
        return results[0];
    } else {
        return nil;
    }
}

#pragma mark - Core Data Boilerplate Code

/*
 *  There really isn't anything interesting in this section because this is standard boilerplate Core Data code
 */

- (NSManagedObjectContext *)createManagedObjectContextForBackgroundThread {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = self.persistentStoreCoordinator;
    context.mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSOverwriteMergePolicyType];
    
    return context;
}

+ (NSManagedObject *)managedObjectWithId:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext == nil) {
        NSLog(@"Seriosly? You're going to try and get a managed object in a context that is nil?");
    }
    
    NSManagedObject *managedObject = nil;
    NSURL *objectURI = [NSURL URLWithString:identifier];
    NSPersistentStoreCoordinator *storeCoordinator =  [managedObjectContext persistentStoreCoordinator];
    NSManagedObjectID *objectID = [storeCoordinator managedObjectIDForURIRepresentation:objectURI];
    if (objectID) {
        NSError *objectRetrievalError = nil;
        managedObject = [managedObjectContext existingObjectWithID:objectID error:&objectRetrievalError];
        
        if (objectRetrievalError) {
            NSLog(@"error fetching object by ID: %@", objectRetrievalError);
        }
    }
    return managedObject;
}

- (NSURL *)managedObjectModelUrl {
    return nil;
}

- (void)contextDidSave:(NSNotification *)notification {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self contextDidSave:notification];
        });
    } else {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }
}

- (NSManagedObjectModel*) managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *momURL = [self managedObjectModelUrl];
    
    if (momURL) {
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    } else {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator*) persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSError *error = nil;

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext*) managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

@end
