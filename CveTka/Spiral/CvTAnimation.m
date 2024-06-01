//
//  CvTAnimation.m
//  CveTka
//
//  Created by tomaz stupnik on 7/15/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CC3Actions.h"

#import "CvTAnimation.h"
#import "CvTSpiralView.h"
#import "../Synth/CvTSynthChord.h"

#define SYMBOLSIZE   30

@implementation CvTAnimationSymbol

-(id)init:(AirplaySymbol)symbol
{
    self = [super init];
    Symbol = symbol;
    
    self = [super init];
    self.userInteractionEnabled = FALSE;
    self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.0f];
    return self;
}

-(void)drawRect:(CGRect)rect
{
    rect = CGRectInset(rect, 1.5, 1.5);
    
    UIBezierPath *path;
    switch (Symbol) {
        case kAirplaySymbol_Circle:
            path = [UIBezierPath bezierPathWithOvalInRect:rect];
            break;
            
        case kAirplaySymbol_Square:
            path = [UIBezierPath bezierPathWithRect:rect];
            break;
            
        case kAirplaySymbol_Triangle:
            path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y)];
            [path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)];
            [path addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
            [path closePath];
           break;
    }
    
    [[[UIColor blackColor] colorWithAlphaComponent:1.0f] set];
    [path setLineWidth:3.0f];
    path.lineJoinStyle = kCGLineJoinRound;
    [path stroke];
}

@end


@implementation CvT2dAnimation

-(id)init:(CvTSynthChord*)chord
{
    Chord = chord;
    
    self = [super initWithFrame:[CvTSpiralView Spiral].bounds];
    self.userInteractionEnabled = FALSE;
    self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.0f];
    
    Symbol = [[CvTAnimationSymbol alloc] init:Chord.Symbol];
    Symbol.frame = [[CvTSpiralView Spiral].SynthController ToneSurfaceCircleRect:[Chord.ChordSnappedMidiTones[0] floatValue]];
    [self addSubview:Symbol];
    [self bringSubviewToFront:Symbol];

    [[CvTSpiralView Spiral] addSubview:self];
    
    Released = FALSE;
    if (chord.Duration > 0)
        [self Release];
    
    return self;
}

-(void)drawRect:(CGRect)rect
{
    if (!Released)
        Symbol.frame = [[CvTSpiralView Spiral].SynthController ToneSurfaceCircleRect:[Chord.ChordSnappedMidiTones[0] floatValue]];
    
    for (NSNumber *tone in Chord.ChordSnappedMidiTones)
    {
        if (fmod([tone floatValue], 1.0f) == 0)
        {
            [[[UIColor whiteColor] colorWithAlphaComponent:0.20f] set];
            [[[CvTSpiralView Spiral].SynthController ChordSurface:[tone intValue]] fill];
            
            [[[UIColor whiteColor] colorWithAlphaComponent:0.35f] set];
            //[[Spiral.SynthController ToneSurface:[tone intValue]] fill];
        }
        [[[UIColor whiteColor] colorWithAlphaComponent:0.50f] set];
        CGContextFillEllipseInRect(UIGraphicsGetCurrentContext(), [[CvTSpiralView Spiral].SynthController ToneSurfaceCircleRect:[tone floatValue]]);
    }
}

-(void)Slide:(CvTSynthChord*)newChord
{
    if (newChord)
        [Chord SlideChord:newChord.ChordSnappedMidiTones];
    
    [self setNeedsDisplay];
}

-(void)Release
{
    if (!Released)
    {
        float spotTime = 1.0f;
        float delay = (Chord.Duration - spotTime / 2);
        if (delay < 0)
        {
            spotTime /= 2;
            delay = 0;
        }
        
        Released = TRUE;
        [UIView animateWithDuration:spotTime delay:delay options: UIViewAnimationOptionCurveEaseIn animations:^{
            Symbol.transform = CGAffineTransformMakeScale(0, 0);
            self.alpha = 0.0f;
        } completion:^(BOOL finished){
            Chord = NULL;
            [Symbol removeFromSuperview];
            [self removeFromSuperview];
        }];
    }
}

@end


@implementation CvT3dAnimation

-(id)init:(CvTSynthChord*)chord
{
    self = [super init];
    Chord = chord;
    
    CGRect r = [[CvTSpiralView Spiral].SynthController ToneSurfaceCircleRect:[Chord.ChordSnappedMidiTones[0] floatValue]];
    
    Node = [[CC3MeshNode alloc] init];
    [(CC3MeshNode*)Node populateAsSphereWithRadius:r.size.height / 2 andTessellation:CC3TessellationMake(20, 20)];
    
    Node.color = CCColorRefFromCCC4F(ccc4f(0.8, 0.8, 0.8, 0.1));
    CGPoint point = [[CvTSpiralView Spiral].SynthController ToneToPoint:[Chord.ChordSnappedMidiTones[0] floatValue]];
    Node.location = cc3v(point.x, -point.y, 0);
    Node.opacity = 0.5;
    [[CvTSpiralView Spiral].C3Scene addChild:Node];
    
    return self;
}

-(void)Slide:(CvTSynthChord*)newChord
{
}

-(void)Release
{
    CCActionCallFunc *callAction = [CCActionCallFunc actionWithTarget:self selector:@selector(RemoveNode)];
    
    [Node runAction:[CCActionSequence actionOne:[CC3ActionMoveBy actionWithDuration:20.0f moveBy:cc3v(0, 0, -50)] two:callAction]];
}

-(void)RemoveNode
{
    Node.opacity = 0;
}

@end
