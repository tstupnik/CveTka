//
//  CvtSpiral.m
//  CveTest
//
//  Created by tomaz stupnik on 4/25/14.
//  Copyright (c) 2014 tomaz stupnik. All rights reserved.
//

#import "CvTScale.h"
#import "CvTSpiralView.h"
#import "CvTViewController.h"
#import "CvTPersonality.h"
#import "CvTAppDelegate.h"
#import "../Airplay/CvTMidiPacketList.h"
#import "../CvTViewController.h"

#define BORDER 25

CGPolarPoint CGPolarPointMake(float radius, float angle)
{
    CGPolarPoint p;
    p.Radius = radius;
    p.Angle = angle;
    return p;
}

CGPolarPoint CGPolarVectorMake(CGPolarPoint p1, CGPolarPoint p2)
{
    float x1 = -p1.Radius * sin(p1.Angle);
    float y1 = -p1.Radius * cos(p1.Angle);
    float x2 = -p2.Radius * sin(p2.Angle);
    float y2 = -p2.Radius * cos(p2.Angle);
    float angle = M_PI - atan2(-(x2 - x1), y2 - y1);
    return CGPolarPointMake(sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)), angle);
}

CC3Vector CGPointToCC3Vector(CGPoint point)
{
    return cc3v(point.x, -point.y, 0);
}


@implementation CvTSpiralTouch

-(id)init:(UITouchPhase)phase key:(long)key point:(CGPoint)point
{
    self = [super init];
    _Phase = phase;
    _Key = [NSNumber numberWithLong:key];
    _Point = point;
    return self;
}

@end


@implementation CvTSpiralSynthController

-(id)initWithFrame:(CGRect)frame
{
    self = [super init];
    ArrayLock = [[NSLock alloc] init];
    [self Initialize];
    [self Resize:CGRectMake(0, BORDER, frame.size.width, frame.size.height - 2 * BORDER)];
    return self;
}

-(void)Initialize
{
    int midiRoot = ([CvTAppSettings Current].RootTone + [CvTAppSettings Current].RootOctave);
    _StartTone = midiRoot - 5;
    _EndTone = midiRoot + [CvTAppSettings Current].TonalSpan - 5;
    [CvTSynth Synth].Scale = [[CvTScale alloc] initWithScale:midiRoot tonalCentre:[CvTAppSettings Current].TonalCentre scale:[CvTAppSettings Current].Scale];
    
    int d = (_EndTone - midiRoot) % 12;
    _CenterTone = _EndTone + 12 - d + ((d > 6) ? 12 : 0);
    
    TouchIdents = [[NSMutableDictionary alloc] init];
}

-(void)Resize:(CGRect)bounds
{
    Dimension = 1;
    Center = CGPointMake(0, 0);
    CGRect r = CGRectMake(0, 0, 0, 0);
    for (float i = -0.5; i < 12; i += 0.5)
    {
        CGPolarPoint polarPoint = [self ToneToPolarPoint:(i + _StartTone)];
        polarPoint.Radius += 0.5;
        CGPoint point = [self PolarToRect:polarPoint];
        r = CGRectUnion(r, CGRectMake(point.x, point.y, 0, 0));
    }
    Dimension = fminf(bounds.size.height / (r.size.height), bounds.size.width / (r.size.width));
    Center = CGPointMake(bounds.origin.x + bounds.size.width * (-r.origin.x) / r.size.width, bounds.origin.y + bounds.size.height * (-r.origin.y) / r.size.height);
}

-(CGPoint)ToneToPoint:(float)tone {
    return [self PolarToRect:[self ToneToPolarPoint:tone]];
}

-(CGPolarPoint)ToneToPolarPoint:(float)tone
{
    CGPolarPoint p;
    p.Angle = +(float)(_CenterTone - tone) / 12 * 2 * M_PI;
    p.Radius = p.Angle / 2 / M_PI;
    return p;
}

-(CGPoint)PolarToRect:(CGPolarPoint)polar
{
    CGPoint point;
    point.x = Center.x + sin(polar.Angle) * polar.Radius * Dimension;
    point.y = Center.y + cos(polar.Angle) * polar.Radius * Dimension;
    return point;
}

-(CGPolarPoint)RectToPolar:(CGPoint)point
{
    float dx = point.x - Center.x;
    float dy = point.y - Center.y;
    CGPolarPoint polar;
    polar.Angle = atan2(-dx, dy);
    polar.Radius = sqrt(dx * dx + dy * dy) / Dimension;
    return polar;
}

-(float)MidiTone:(CGPoint)point
{
    CGPolarPoint tonePoint = [self RectToPolar:point];
    
    float tone = [CvTSynth Synth].Scale.MidiRootTone + tonePoint.Angle / 2 / M_PI * 12;
    return tone + 12 * lroundf(((_CenterTone - [CvTSynth Synth].Scale.MidiRootTone)/ 12) - tonePoint.Radius - tonePoint.Angle / 2 / M_PI);
}

-(CC3MeshNode*)ToneSurfaceCC3Node:(int)midiTone Count:(int)Count
{
    CGPoint *points = [self ToneSurface:midiTone Count:Count];
    CC3Vector vert[Count + 1];
    
    for (int i = 0; i < Count; i++)
        vert[i] = CGPointToCC3Vector(points[i]);
    vert[Count] = vert[0];
    
    CC3MeshNode *mesh = [[CC3MeshNode alloc] init];
    [mesh populateAsLineStripWith:Count + 1 vertices:vert andRetain:TRUE];
    return mesh;
}

-(UIBezierPath*)ToneSurfaceBezier:(int)midiTone Count:(int)Count
{
    CGPoint *points = [self ToneSurface:midiTone Count:Count];
    UIBezierPath *bezier = [[UIBezierPath alloc] init];
    [bezier moveToPoint:points[0]];
    for (int i = 1; i < Count; i++)
        [bezier addLineToPoint:points[i]];
    [bezier closePath];
    return bezier;
}

-(CGPoint*)ToneSurface:(int)midiTone Count:(int)Count
{
    int pointCount = 0;
    CGPoint *points = (CGPoint*)malloc(sizeof(CGPoint) * Count);
    
    float emboss = ((([[CvTSynth Synth].Scale MidiSolNumber:midiTone] == [CvTSynth Synth].Scale.TonalCentre) && ((midiTone - _StartTone) < 12)) ? 0.2 : 0);
    
    for (int i = 0, stepCount = (Count - 2) / 2; i <= stepCount; i++)
    {
        float bezierTone = midiTone - 0.5f + (float)i / stepCount;
        CGPolarPoint pp = [self ToneToPolarPoint:bezierTone];pp.Radius -= 0.5;
        points[pointCount++] = [self PolarToRect:pp];
    }
    for (int i = 0, stepCount = Count - 2 - (Count - 2) / 2; i <= stepCount; i++)
    {
        float bezierTone = midiTone + 0.5f - (float)i / stepCount;
        CGPolarPoint pp = [self ToneToPolarPoint:bezierTone]; pp.Radius += 0.5 + emboss;
        points[pointCount++] = [self PolarToRect:pp];
    }
    
    return points;
}

-(UIBezierPath*)ChordSurface:(int)midiTone
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    midiTone = (midiTone + 12 * 12 - _StartTone) % 12 + _StartTone;
    
    CGPolarPoint p = [self ToneToPolarPoint:midiTone - 0.5];p.Radius += 0.5;
    [path moveToPoint:[self PolarToRect:p]];
    for (float bezierTone = midiTone - 0.375; bezierTone <= midiTone + 0.5; bezierTone += 0.125)
    {
        CGPolarPoint pp = [self ToneToPolarPoint:bezierTone];pp.Radius += 0.5;
        [path addLineToPoint:[self PolarToRect:pp]];
    }
    [path addLineToPoint:Center];
    [path addLineToPoint:[self PolarToRect:p]];
    return path;
}

-(CGRect)ToneSurfaceCircleRect:(float)tone
{
    CGPoint p1 = [self PolarToRect:[self ToneToPolarPoint:tone - 0.5]];
    CGPoint p2 = [self PolarToRect:[self ToneToPolarPoint:tone + 0.5]];
    float r = fmin(Dimension / 2, sqrt (pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2)) / 2);
    p1 = [self PolarToRect:[self ToneToPolarPoint:tone]];
    return CGRectMake(p1.x - r, p1.y - r, 2 * r, 2 * r);
}

-(void)touches:(NSArray*)spiralTouches spiral:(CvTSpiralView*)spiral
{
    [ArrayLock lock];
    
    for (CvTSpiralTouch *touch in spiralTouches)
        switch (touch.Phase)
    {
        case UITouchPhaseBegan:
        {
            float tone = [self MidiTone:touch.Point];
            if (SetupMode)
            {
                if (tone >= (_StartTone - 0.5f))
                {
                    [[CvTSynth Synth].Scale ToggleMidiTone:tone];
                    [CvTAppSettings Current].Scale = [[CvTSynth Synth].Scale string];
                    [self Initialize];
                }
                else
                {
                    if ([[CvTSynth Synth].Scale ContainsMidiTone:tone])
                    {
                        [CvTAppSettings Current].TonalCentre = [[CvTSynth Synth].Scale MidiSolNumber:tone];
                        [self Initialize];
                    }
                }
            }
            else
            {
                long ident = random();
                
                if ((tone <= (_EndTone + 0.5f)) && (tone > (_StartTone - 0.5f)))
                {
                    CvTSynthChord *chord = [[CvTSynthChord alloc] init:tone chordMode:((CvTViewController*)spiral.window.rootViewController)->DemoController.ChordMode duration:0 source:@""];
                    ident = chord.Ident;
                    [spiral Play:chord];
                }
                
                NSNumber *numIdent = [TouchIdents objectForKey:touch.Key];
                if (numIdent)
                {
                    [[CvTSynth Synth] Release:[numIdent longValue]];
                    [TouchIdents removeObjectForKey:touch.Key];
                }
                [TouchIdents setObject:[NSNumber numberWithLong:ident] forKey:touch.Key];
            }
        } break;
        case UITouchPhaseMoved:
        {
            NSNumber *numIdent = [TouchIdents objectForKey:touch.Key];
            if (numIdent != NULL)
            {
                long ident = [numIdent longValue];
                float tone = [self MidiTone:touch.Point];
                if ((tone <= (_EndTone + 0.5f)) && (tone >= (_StartTone - 0.5f)))
                    [spiral Slide:tone ident:ident];
            }
        } break;
        case UITouchPhaseEnded:
        case UITouchPhaseCancelled:
        {
            NSNumber *numIdent = [TouchIdents objectForKey:touch.Key];
            if (numIdent != NULL)
            {
                [spiral Release:[numIdent longValue]];
                [TouchIdents removeObjectForKey:touch.Key];
            }
        } break;
        case UITouchPhaseStationary:
            break;
    }
    [self VerifyTouchIdents:spiralTouches];
    
    [ArrayLock unlock];
}

-(void)VerifyTouchIdents:(NSArray*)spiralTouches
{
    if (!SetupMode)
    {
        for (NSNumber *key in TouchIdents.allKeys)
        {
            BOOL touchFound = FALSE;
            for (CvTSpiralTouch *touch in spiralTouches)
                if (key == touch.Key)
                {
                    touchFound = TRUE;
                    break;
                }
            if (!touchFound)
            {
                NSNumber *numIdent = [TouchIdents objectForKey:key];
                if (numIdent != NULL)
                {
                    [[CvTSynth Synth] Release:[numIdent longValue]];
                    [TouchIdents removeObjectForKey:key];
                }
            }
        }
    }
}

@end