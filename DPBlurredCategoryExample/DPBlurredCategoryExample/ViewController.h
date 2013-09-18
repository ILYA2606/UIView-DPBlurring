//
//  ViewController.h
//  DPBlurredCategoryExample
//
//  Created by ILYA SHKOLNIK on 17.09.13.
//  Copyright (c) 2013 ILYA SHKOLNIK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController{
    CGPoint beginCenter;
    CGSize beginSize;
}
@property (weak, nonatomic) IBOutlet UIView *blurringView;
@property (weak, nonatomic) IBOutlet UISlider *sl_radius;

- (IBAction)radiusChanged:(id)sender;
- (IBAction)startBlurring:(id)sender;
- (IBAction)stopBlurring:(id)sender;

@end
