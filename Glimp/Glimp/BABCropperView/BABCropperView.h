//
//  BABCropperView.h
//  Pods
//
//  Created by Bryn Bodayle on April/17/2015.
//
//

#import <UIKit/UIKit.h>

@interface BABCropperView : UIView

@property (nonatomic, assign) CGSize cropSize;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIView *cropMaskView;
@property (nonatomic, readonly) UIView *borderView;
@property (nonatomic, assign) CGFloat cropDisplayScale; //defaults to 1.0f
@property (nonatomic, assign) UIOffset cropDisplayOffset; //defaults to UIOffsetZero

- (void)renderCroppedImage:(void (^)(UIImage *croppedImage))completionBlock;

@end
