//
//  UIView+DPBlurring.m
//  DPBlurredCategoryExample
//
//  Created by ILYA SHKOLNIK on 17.09.13.
//  Copyright (c) 2013 ILYA SHKOLNIK. All rights reserved.
//

#import "UIView+DPBlurring.h"
#import <objc/runtime.h>

static char const * const timerForBlurringKey = "timerForBlurring";
static char const * const blurringRadiusKey = "blurringRadius";
static char const * const blurringFPSKey = "blurringFPS";

@implementation UIView (DPBlurring)

#pragma mark - Getters

- (NSTimer*) timerForBlurring
{
    NSTimer *object = objc_getAssociatedObject(self, timerForBlurringKey);
    return object;
}
- (float) blurringRadius
{
    float object = [objc_getAssociatedObject(self, blurringRadiusKey) floatValue];
    return object;
}
- (float) blurringFPS
{
    float object = [objc_getAssociatedObject(self, blurringFPSKey) floatValue];
    return object;
}

#pragma mark - Setters

- (void) setTimerForBlurring:(NSTimer*) property
{
    objc_setAssociatedObject(self, timerForBlurringKey, property , OBJC_ASSOCIATION_RETAIN);
}

- (void) setBlurringRadius:(float) property
{
    objc_setAssociatedObject(self, blurringRadiusKey, @(property) , OBJC_ASSOCIATION_RETAIN);
}

- (void) setBlurringFPS:(float) property
{
    objc_setAssociatedObject(self, blurringFPSKey, @(property) , OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Public Methods

//starting timer for blurring
-(void)startBlurring{
    UIImageView *blurringImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    blurringImageView.tag = 2606;
    blurringImageView.contentMode = UIViewContentModeScaleToFill;
    blurringImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self insertSubview:blurringImageView atIndex:0];
    //fix FPS for blurring
    if(self.blurringFPS <= 0) self.blurringFPS = 30;
    self.timerForBlurring = [NSTimer scheduledTimerWithTimeInterval:1/self.blurringFPS target:self selector:@selector(timerLoop) userInfo:nil repeats:YES];
}

//stopping timer for blurring (freeze background color)
-(void)stopBlurring{
    [[self viewWithTag:2606] removeFromSuperview];
    [self.timerForBlurring invalidate];
    self.timerForBlurring = nil;
}

#pragma mark - Logic Methods

-(void)timerLoop{
    UIImage *imageFromSuperview = [self imageFromSuperview];
    UIImage *blurredImage = [self blurredImageWithImage:imageFromSuperview andRadius:self.blurringRadius tintColor:nil saturationDeltaFactor:1.8 maskImage:nil];
    self.backgroundColor = [UIColor clearColor];
    [(UIImageView*)[self viewWithTag:2606] setImage:blurredImage];
}

-(UIImage*)imageFromSuperview{
    //getting rect for superview under our view
    CGRect rectSuperview = [self convertRect:self.bounds toView:self.superview];
    //hide our view before capturing superview
    self.hidden = YES;
    //capturing superview
    CGSize miniSize = {rectSuperview.size.width/3, rectSuperview.size.height/3};
    UIGraphicsBeginImageContextWithOptions(rectSuperview.size, NO, 1.0/20);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -rectSuperview.origin.x, -rectSuperview.origin.y);
    CALayer *layer = self.superview.layer;
    [layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //show our view after capturing superview
    self.hidden = NO;
    UIImage *scaledImage = [self scaleImage:image withRatio:0.1];
    //NSLog(@"scaledImage = %@, image = %@", NSStringFromCGSize(scaledImage.size), NSStringFromCGSize(image.size));
    return scaledImage;
}
-(UIImage*)scaleImage:(UIImage*)image withRatio:(float) scaleRatio
{
    CGSize scaledSize = CGSizeMake(image.size.width * scaleRatio, image.size.height * scaleRatio);
    
    //The output context.
    UIGraphicsBeginImageContext(scaledSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //Percent (101%)
#define SCALE_OVER_A_BIT 1.01
    
    //Scale.
    CGContextScaleCTM(context, scaleRatio * SCALE_OVER_A_BIT, scaleRatio * SCALE_OVER_A_BIT);
    [image drawAtPoint:CGPointZero];
    
    //End?
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

//Apple-based blurring method
- (UIImage *)blurredImageWithImage:(UIImage*)image andRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage
{
    if (image.size.width < 1 || image.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", image.size.width, image.size.height, self);
        return nil;
    }
    if (!image.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }
    CGRect imageRect = { CGPointZero, image.size };
    UIImage *effectImage = image;
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(image.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -image.size.height);
        CGContextDrawImage(effectInContext, imageRect, image.CGImage);
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        UIGraphicsBeginImageContextWithOptions(image.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1;
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -image.size.height);
    CGContextDrawImage(outputContext, imageRect, image.CGImage);
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}
@end
