//
//  VPViewController.h
//  VPImageCropperDemo
//
//  Created by Vinson.D.Warm on 1/13/14.
//  Copyright (c) 2014 Vinson.D.Warm. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VPViewController;

@protocol VPViewControllerDelegate <NSObject>

- (void)imageCropper:(VPViewController *)cropperViewController didFinished:(UIImage *)editedImage;

@end


@interface VPViewController : UIViewController

@property (nonatomic, assign) id<VPViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *method;

@end