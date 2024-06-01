//
//  CvTAnimation.h
//  CveTka
//
//  Created by tomaz stupnik on 7/15/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CC3Node.h"
#import "CvTAppSettings.h"

@class CvTSpiralView;
@class CvTSynthChord;

@protocol CvTAnimationDelegate<NSObject>

-(void)Slide:(CvTSynthChord*)newChord;
-(void)Release;

@end


@interface CvTAnimationSymbol : UIView
{
    AirplaySymbol Symbol;
}

-(id)init:(AirplaySymbol)symbol;

@end


@interface CvT2dAnimation : UIView<CvTAnimationDelegate>
{
    BOOL Released;
    CvTSynthChord *Chord;
    
    UIView *Symbol;
}

-(id)init:(CvTSynthChord*)chord;
-(void)Slide:(CvTSynthChord*)newChord;
-(void)Release;

@end


@interface CvT3dAnimation : NSObject<CvTAnimationDelegate>
{
    CvTSynthChord *Chord;
    CC3Node *Node;
}

-(id)init:(CvTSynthChord*)chord;
-(void)Slide:(CvTSynthChord*)newChord;
-(void)Release;

@end