//
//  CvT3dSpiralView.h
//  CveTka
//
//  Created by tomaz stupnik on 9/13/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CC3Scene.h"
#import "CC3Layer.h"
#import "CvTSpiralSynthController.h"


@interface CvT3dSpiralScene : CC3Scene
@end


@interface CvT3dSpiralLayer : CC3Layer
@end


@interface CvT2dSpiralLayer : CCNode
@end


@interface CvT2dSpiralScene : CCScene
@end


@interface CvTSpiralView : CCGLView<CvTAirplayJamDelegate>
{
    CvT3dSpiralLayer *C3Layer;
    
    UIButton *SetupButton;
    UILabel *ChordName;
    UIButton *ResetButton;
}

@property (nonatomic, readonly) CCScene *C2Scene;
@property (nonatomic, readonly) CvT3dSpiralScene *C3Scene;
@property (nonatomic, readonly) CvTSpiralSynthController *SynthController;

+(CvTSpiralView*)Spiral;
-(id)initWithFrame:(CGRect)frame;

-(void)Initialize;
//-(id<CvTAnimationDelegate>)Animation:(CvTSynthChord*)chord;

-(void)Play:(CvTSynthChord*)chord;
-(void)Slide:(CvTSynthChord*)chord;
-(void)Slide:(float)tone ident:(long)ident;
-(void)Release:(long)ident;
@end
