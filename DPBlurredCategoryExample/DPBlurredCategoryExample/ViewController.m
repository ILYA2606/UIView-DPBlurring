//
//  ViewController.m
//  DPBlurredCategoryExample
//
//  Created by ILYA SHKOLNIK on 17.09.13.
//  Copyright (c) 2013 ILYA SHKOLNIK. All rights reserved.
//

#import "ViewController.h"
#import "UIView+DPBlurring.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //configure blurredView
    _blurringView.blurringFPS = 200;
    _blurringView.blurringRadius = _sl_radius.value;
    [_blurringView startBlurring];
    
    //set up pan gesture
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    pan.maximumNumberOfTouches = 1;
    [_blurringView addGestureRecognizer:pan];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)didPan:(UIPanGestureRecognizer*)pan{
    if(pan.state == UIGestureRecognizerStateBegan){
        beginCenter = _blurringView.center;
    }
    else if(pan.state == UIGestureRecognizerStateChanged){
        CGPoint translation = [pan translationInView:_blurringView];
        CGPoint futureCenterPoint = CGPointMake(beginCenter.x+translation.x, beginCenter.y+translation.y);
        if(futureCenterPoint.x - _blurringView.frame.size.width/2 < 0)
            futureCenterPoint.x = _blurringView.frame.size.width/2;
        else if(futureCenterPoint.x + _blurringView.frame.size.width/2 > self.view.bounds.size.width)
            futureCenterPoint.x = self.view.bounds.size.width - _blurringView.frame.size.width/2;
        if(futureCenterPoint.y - _blurringView.frame.size.height/2 < 0)
            futureCenterPoint.y = _blurringView.frame.size.height/2;
        else if(futureCenterPoint.y + _blurringView.frame.size.height/2 > self.view.bounds.size.height)
            futureCenterPoint.y = self.view.bounds.size.height - _blurringView.frame.size.height/2;
        _blurringView.center = futureCenterPoint;
    }
}

#pragma mark - IBActions

- (IBAction)radiusChanged:(id)sender {
    _blurringView.blurringRadius = _sl_radius.value;
}

- (IBAction)startBlurring:(id)sender {
    [_blurringView startBlurring];
}

- (IBAction)stopBlurring:(id)sender {
    [_blurringView stopBlurring];
}

@end
