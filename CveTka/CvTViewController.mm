//
//  CvTViewController.m
//  CveTka
//
//  Created by tomaz stupnik on 5/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTAppDelegate.h"
#import "CvTViewController.h"
#import "CvTAppSettings.h"
#import "CvTPersonality.h"


@implementation CvTViewController

-(void)initialize {
    [CvTAppSettings Current];
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotate {
    return TRUE;
}

-(void)applicationDidBecomeActive
{
    if (![CvTSpiralView Spiral])
    {
        int radius = MIN(self.view.bounds.size.width, self.view.bounds.size.height)/2;
        CGRect spiralRect = CGRectMake(CGRectGetMaxX(self.view.bounds) - 2 * radius, CGRectGetMaxY(self.view.bounds) - 2 * radius, radius * 2, radius * 2);

        CvTSpiralView *spiralView = [[CvTSpiralView alloc] initWithFrame:spiralRect];

        DemoController = [self.storyboard instantiateViewControllerWithIdentifier:@"Demo"];
        [CvTPlaybackThread Playback].Delegate = DemoController;
        
        DemoController.view.frame = CGRectMake(0, 0, spiralRect.origin.x, spiralRect.size.height);
        [self.view addSubview:DemoController.view];
        [DemoController didMoveToParentViewController:self];
        [self addChildViewController:DemoController];
        
        [self.view addSubview:spiralView];
    }
    
    DemoController.view.backgroundColor = [CvTPersonality BackgroundColor];
    [[CvTSpiralView Spiral] Initialize];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    int radius = MIN(self.view.bounds.size.width, self.view.bounds.size.height)/2;
    CGRect spiralRect = CGRectMake(CGRectGetMaxX(self.view.bounds) - 2 * radius, CGRectGetMaxY(self.view.bounds) - 2 * radius, radius * 2, radius * 2);
    [CvTSpiralView Spiral].frame = spiralRect;
    
    if (DemoController != NULL)
        DemoController.view.frame = CGRectMake(0, 0, spiralRect.origin.x, spiralRect.size.height);
}

@end