//
//  MPTImageViewController.m
//  MultiPeerTest
//
//  Created by Wayne on 10/31/13.
//  Copyright (c) 2013 Wayne Hartman. All rights reserved.
//

#import "MPTImageViewController.h"

@interface MPTImageViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation MPTImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.image = self.image;
}

@end
