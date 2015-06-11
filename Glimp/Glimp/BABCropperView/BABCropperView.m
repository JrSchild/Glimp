//
//  BABCropperView.m
//  Pods
//
//  Created by Bryn Bodayle on April/17/2015.
//
//

#import "BABCropperView.h"

@import ImageIO;

static const CGFloat BABCropperViewMaximumZoomScale = 4.0f;
static const CGFloat BABCropperViewMaskBackgroundColorAlpha = 0.7f;

static CGSize BABCropperViewScaledSizeToFitSize(CGSize size, CGSize fitSize) {
    
    if(fitSize.width >= size.width && fitSize.height >= size.height) { //already the correct size
        
        return size;
    }
    
    CGSize fittedSize;
    
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    if(width > height) {
        
        CGFloat ratio = height/width;
        fittedSize =  CGSizeMake(fitSize.width, floorf(fitSize.width * ratio));
    }
    else {
        
        CGFloat ratio = height/width;
        fittedSize = CGSizeMake(fitSize.width, floorf(fitSize.width * ratio));
        
    }
    
    if(fittedSize.height > fitSize.height) {
        
        if(width > height) {
            
            CGFloat ratio = width/height;
            
            fittedSize = CGSizeMake(floorf(fitSize.height * ratio), fitSize.height);
        }
        else {
            
            CGFloat ratio = width/height;
            
            fittedSize = CGSizeMake(floorf(fitSize.height * ratio), fitSize.height);
            
        }
    }
    
    return fittedSize;
}

static UIImageOrientation BABCropperViewImageOrientationFromEXIFOrientation(NSUInteger EXIFOrienation) {
 
    switch (EXIFOrienation) {
        case 1:
            return UIImageOrientationUp;
            break;
        case 2:
            return UIImageOrientationUpMirrored;
            break;
        case 3:
            return UIImageOrientationDown;
            break;
        case 4:
            return UIImageOrientationDownMirrored;
            break;
        case 5:
            return UIImageOrientationLeftMirrored;
            break;
        case 6:
            return UIImageOrientationRight;
            break;
        case 7:
            return UIImageOrientationRightMirrored;
            break;
        case 8:
            return UIImageOrientationLeft;
            break;
        default:
            return UIImageOrientationUp;
            break;
    }
}

static UIImage* BABCropperViewCroppedAndScaledImageWithCropRect(UIImage *image, CGRect cropRect, CGSize scaleSize) {
    
    NSData *imageJPEGData = UIImageJPEGRepresentation(image, 1.0f);
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)(imageJPEGData), NULL);
    
    NSDictionary *options = @{(NSString *)kCGImageSourceShouldCache: @NO};
    CFDictionaryRef imagePropertiesRef = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, (__bridge CFDictionaryRef)options);

    NSUInteger EXIFOrientation = [(NSNumber *)CFDictionaryGetValue(imagePropertiesRef, kCGImagePropertyOrientation) unsignedIntegerValue];
    
    UIImageOrientation imageOrientation = BABCropperViewImageOrientationFromEXIFOrientation(EXIFOrientation);
    CGSize imageSize = image.size;
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();

    CFRelease(imagePropertiesRef);
    
    CGFloat scale = 1.0f;
    
    if(cropRect.size.width > cropRect.size.height) {
        
        scale = scaleSize.width/cropRect.size.width;
    }
    else {
        
        scale = scaleSize.height/cropRect.size.height;
    }
    
    CGContextRef bitmap = CGBitmapContextCreate(NULL, scaleSize.width, scaleSize.height, 8, scaleSize.width * 4, colorspace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGFloat cropScaleFactor = cropRect.size.width/scaleSize.width;
    
    CGSize scaledSize;
    
    switch (imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored: {
            
            CGFloat scale = imageSize.width / scaleSize.width;
            scaledSize = CGSizeMake(scaleSize.width, imageSize.height/scale);
        }
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored: {
            CGFloat scale = imageSize.height / scaleSize.width;
            scaledSize = CGSizeMake(imageSize.width/scale, scaleSize.width);
        }
            break;
            
        default:
            break;
    }
    
    CGFloat maxPixelSize = 0;
    
    if(cropScaleFactor < 1.0) {
        
        maxPixelSize = MAX(scaledSize.width / cropScaleFactor, scaledSize.height / cropScaleFactor);
    }
    else {
        
        maxPixelSize = MAX(scaledSize.width * cropScaleFactor, scaledSize.height *cropScaleFactor);
    }
    
    
    NSDictionary *thumbnailOptions = @{(id)kCGImageSourceCreateThumbnailWithTransform: (id)kCFBooleanTrue,
                                       (id)(id)kCGImageSourceCreateThumbnailFromImageAlways: (id)kCFBooleanTrue,
                                       (id)kCGImageSourceThumbnailMaxPixelSize: @(maxPixelSize)};
    
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSourceRef, 0, (__bridge CFDictionaryRef)thumbnailOptions);
    
    switch (imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            imageSize = CGSizeMake(imageSize.height, imageSize.width);
            break;
        default:
            break;
    }
    
    CGRect drawRect = CGRectMake(-cropRect.origin.x, -cropRect.origin.y, imageSize.width, imageSize.height);
    drawRect = CGRectApplyAffineTransform(drawRect, CGAffineTransformMakeScale(scale, scale));
    CGAffineTransform rectTransform = CGAffineTransformConcat(CGAffineTransformMakeScale(1.0, -1.0), CGAffineTransformMakeTranslation(0, scaleSize.height));
    drawRect = CGRectApplyAffineTransform(drawRect, rectTransform);
    drawRect = CGRectIntegral(drawRect);
    
    if(scaleSize.width - drawRect.size.width > 0) {
        drawRect.origin.x+= (scaleSize.width - drawRect.size.width)/2;
    }
    
    if(scaleSize.height - drawRect.size.height > 0) {
        drawRect.origin.y-= (scaleSize.height - drawRect.size.height)/2;
    }
    
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
    CGContextFillRect(bitmap, CGRectMake(0, 0, cropRect.size.width, cropRect.size.height));
    
    CGContextDrawImage(bitmap, drawRect, thumbnail);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    CGImageRelease(thumbnail);
    CGColorSpaceRelease(colorspace);
    CFRelease(imageSourceRef);
    
    return newImage;
}

@interface BABCropperView()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *borderView;

@property (nonatomic, assign) CGSize scaledCropSize;
@property (nonatomic, assign) CGSize displayCropSize;
@property (nonatomic, assign) CGRect displayCropRect;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation BABCropperView

- (void)dealloc {
    
    [_operationQueue cancelAllOperations];
    _scrollView.delegate = nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self sharedInit];
    }
    return self;
}

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    [self sharedInit];
}

- (void)sharedInit {
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.cropDisplayScale = 1.0f;
    self.cropDisplayOffset = UIOffsetZero;
    
    self.backgroundColor = [UIColor blackColor];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];
    
    self.imageView = [[UIImageView alloc] init];
    [self.scrollView addSubview:self.imageView];
    
    self.cropMaskView = [[UIView alloc] initWithFrame:self.bounds];
    self.cropMaskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.cropMaskView.userInteractionEnabled = NO;
    self.cropMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:BABCropperViewMaskBackgroundColorAlpha];
    [self addSubview:self.cropMaskView];
    
    self.borderView = [[UIView alloc] initWithFrame:self.cropMaskView.bounds];
    self.borderView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.borderView.layer.borderWidth = [UIScreen mainScreen].scale/4.0f;
    self.borderView.userInteractionEnabled = NO;
    [self addSubview:self.borderView];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.cropMaskView.frame;
    maskLayer.fillColor = self.cropMaskView.backgroundColor.CGColor;
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    self.cropMaskView.layer.mask = maskLayer;
}


#pragma mark - Setters & Getters

- (void)setImage:(UIImage *)image {
    
    _image = image;
    _imageView.image = image;
    [_imageView sizeToFit];
    
    [self setNeedsLayout];
}

- (void)setCropSize:(CGSize)cropSize {
    
    _cropSize = cropSize;
    
    [self setNeedsLayout];
}

#pragma mark - View Configuration

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    if(self.cropSize.width > 0 && self.cropSize.height > 0) {
        
        CGSize scaledSize = BABCropperViewScaledSizeToFitSize(self.cropSize, self.bounds.size);
        self.scaledCropSize = scaledSize;
        
        CGAffineTransform cropDisplayScaleTransform = CGAffineTransformMakeScale(self.cropDisplayScale, self.cropDisplayScale);
        self.displayCropSize = CGSizeApplyAffineTransform(scaledSize, cropDisplayScaleTransform);
        
        CGRect displayCropRect = CGRectMake(CGRectGetMidX(self.bounds) - self.displayCropSize.width/2.0f, CGRectGetMidY(self.bounds) - self.displayCropSize.height/2.0f, self.displayCropSize.width, self.displayCropSize.height);
        displayCropRect.origin.x += self.cropDisplayOffset.horizontal;
        displayCropRect.origin.y += self.cropDisplayOffset.vertical;
        self.displayCropRect = displayCropRect;
        
        [self updateScrollViewZoomScales];
        [self updateMaskView];
        [self updateScrollViewContentInset];
        [self centerImageInScrollView:self.scrollView];
    }
}

- (void)updateScrollViewZoomScales {
    
    if(self.image) {
        
        CGFloat scrollViewWidth = CGRectGetWidth(self.scrollView.bounds);
        CGFloat scrollViewHeight = CGRectGetHeight(self.scrollView.bounds);
        CGFloat imageViewWidth = CGRectGetWidth(self.imageView.bounds);
        CGFloat imageViewHeight = CGRectGetHeight(self.imageView.bounds);
        CGFloat imageWidth = self.image.size.width;
        CGFloat imageHeight = self.image.size.height;
        
        CGFloat scaleBasedOnHeight = self.displayCropSize.height/imageHeight;
        CGFloat scaleBasedOnWidth = self.displayCropSize.width/imageWidth;
        
        if(imageViewHeight > imageViewWidth) { //portrait image
            
            if(scrollViewHeight > scrollViewWidth && self.cropSize.width/self.cropSize.height < imageViewWidth/imageViewHeight) {
                
                self.scrollView.minimumZoomScale = scaleBasedOnHeight;
            }
            else {
                
                self.scrollView.minimumZoomScale = scaleBasedOnWidth;
            }
        }
        else { //landscape image
            
            if((scrollViewHeight >= scrollViewWidth) || (self.cropSize.width/self.cropSize.height < imageViewWidth/imageViewHeight)) {
                
                self.scrollView.minimumZoomScale = scaleBasedOnHeight;
            }
            else {
                
                self.scrollView.minimumZoomScale = scaleBasedOnWidth;
            }
        }
        
        self.scrollView.maximumZoomScale = BABCropperViewMaximumZoomScale;
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    }
}

- (void)updateScrollViewContentInset {
    
    CGFloat verticalInset = (CGRectGetHeight(self.bounds) - self.displayCropSize.height)/2.0f;
    CGFloat horizontalInset = (CGRectGetWidth(self.bounds) - self.displayCropSize.width)/2.0f;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(verticalInset + self.cropDisplayOffset.vertical, horizontalInset + self.cropDisplayOffset.horizontal, verticalInset - self.cropDisplayOffset.vertical, horizontalInset - self.cropDisplayOffset.horizontal);
}

- (void)updateMaskView {
    
    self.borderView.frame = self.displayCropRect;

    CAShapeLayer *maskLayer = (CAShapeLayer *)self.cropMaskView.layer.mask;
    maskLayer.frame = self.cropMaskView.bounds;

    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.displayCropRect];
    [path appendPath:[UIBezierPath bezierPathWithRect:maskLayer.frame]];
    maskLayer.path = path.CGPath;
}

- (void)centerImageInScrollView:(UIScrollView *)scrollView {
    
    CGFloat contentSizeWidth = scrollView.contentSize.width + scrollView.contentInset.left + scrollView.contentInset.right;
    CGFloat contentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.top + scrollView.contentInset.bottom;

    CGFloat offsetX = (scrollView.bounds.size.width > contentSizeWidth)? (scrollView.bounds.size.width - contentSizeWidth) * 0.5f : 0.0f;
    CGFloat offsetY = (scrollView.bounds.size.height > contentSizeHeight)? (scrollView.bounds.size.height - contentSizeHeight) * 0.5f : 0.0f;
    
    self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}


#pragma mark - Public Methods

- (void)renderCroppedImage:(void (^)(UIImage *croppedImage))completionBlock {
 
    CGRect cropFrameRect;
    cropFrameRect.origin.x = self.scrollView.bounds.origin.x + self.scrollView.contentInset.left;
    cropFrameRect.origin.y = self.scrollView.bounds.origin.y + self.scrollView.contentInset.top;
    cropFrameRect.size.width = self.displayCropRect.size.width;
    cropFrameRect.size.height = self.displayCropRect.size.height;
    
    CGRect scrollViewRect = [self.scrollView convertRect:cropFrameRect toView:self.imageView];

    CGRect cropRect = CGRectIntegral(scrollViewRect);
    
    UIImage *image = self.image;
    CGSize cropSize = self.cropSize;
    
    [self.operationQueue addOperationWithBlock:^{
        
        UIImage *croppedImage = BABCropperViewCroppedAndScaledImageWithCropRect(image, cropRect, cropSize);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            completionBlock(croppedImage);
        });
    }];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
    [self centerImageInScrollView:scrollView];
}

@end
