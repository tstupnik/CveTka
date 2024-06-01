//
//  CvtSpiral.h
//  CveTest
//
//  Created by tomaz stupnik on 4/25/14.
//  Copyright (c) 2014 tomaz stupnik. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CC3MeshNode.h"

#include "CvTScale.h"
#include "CvTSynth.h"
#include "CvTAnimation.h"
#include "CvTAirplayJam.h"
#include "../Airplay/CvTPlayback.h"


struct CGPolarPoint {
    CGFloat Radius;
    CGFloat Angle;
};
typedef struct CGPolarPoint CGPolarPoint;
CGPolarPoint CGPolarPointMake(float radius, float angle);
CGPolarPoint CGPolarVectorMake(CGPolarPoint p1, CGPolarPoint p2);

@protocol CvTAnimationDelegate;

@interface CvTSpiralTouch : NSObject

@property(nonatomic, readonly) UITouchPhase Phase;
@property(nonatomic, readonly) NSNumber *Key;
@property(nonatomic, readonly) CGPoint Point;

-(id)init:(UITouchPhase)phase key:(long)key point:(CGPoint)point;

@end


@interface CvTSpiralSynthController : NSObject
{
@public
    float Dimension;
    CGPoint Center;
    
    int _CenterTone;
    int _StartTone;
    int _EndTone;
    
    BOOL SetupMode;
    NSLock *ArrayLock;
    NSMutableDictionary *TouchIdents;
}

-(id)initWithFrame:(CGRect)frame;
-(void)Initialize;
-(void)Resize:(CGRect)bounds;

-(CGPoint)PolarToRect:(CGPolarPoint)point;
-(CGPolarPoint)RectToPolar:(CGPoint)point;
-(CGPoint)ToneToPoint:(float)tone;
-(CGPolarPoint)ToneToPolarPoint:(float)tone;

-(float)MidiTone:(CGPoint)point;

-(CC3MeshNode*)ToneSurfaceCC3Node:(int)midiTone Count:(int)Count;
-(UIBezierPath*)ToneSurfaceBezier:(int)midiTone Count:(int)Count;
-(UIBezierPath*)ChordSurface:(int)midiTone;
-(CGRect)ToneSurfaceCircleRect:(float)tone;

-(void)touches:(NSArray*)spiralTouches spiral:(CvTSpiralView*)spiral;
@end