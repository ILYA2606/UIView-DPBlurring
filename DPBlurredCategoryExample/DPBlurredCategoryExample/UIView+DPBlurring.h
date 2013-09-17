//
//  UIView+DPBlurring.h
//  DPBlurredCategoryExample
//
//  Created by ILYA SHKOLNIK on 17.09.13.
//  Copyright (c) 2013 ILYA SHKOLNIK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>
#import <QuartzCore/QuartzCore.h>

@interface UIView (DPBlurring)

@property (nonatomic) float blurringRadius;
@property (nonatomic) float blurringFPS;
@property (nonatomic, retain) NSTimer *timerForBlurring;

-(void)startBlurring;
-(void)stopBlurring;

@end
