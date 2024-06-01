//
//  CvT3dSpiralView.m
//  CveTka
//
//  Created by tomaz stupnik on 9/13/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"
#import "CC3UtilityMeshNodes.h"
#import "Cocos2d.h"

#import "CvTSpiralView.h"
#import "CvTPersonality.h"


@implementation CvT3dSpiralScene

-(void)initializeScene:(CvTSpiralSynthController*)synthController
{
    self.backdrop = [CC3Backdrop nodeWithColor:CCC4FFromCGColor([CvTPersonality.BackgroundColor CGColor])];
    self.ambientLight = ccc4f(0.6, 0.6, 0.6, 1);
    
	CC3Camera* cam = [CC3Camera nodeWithName: @"Camera"];
	cam.location = cc3v( 0.0, 0.0, 6);
    cam.fieldOfView = 30;
	[self addChild: cam];
    
	CC3Light* lamp = [CC3Light nodeWithName: @"Lamp"];
	lamp.location = cc3v( -2.0, 0.0, 0.0 );
	lamp.isDirectionalOnly = YES;
    lamp.shadowIntensityFactor = 0.75;
	[cam addChild:lamp];
    
    for (float tone = synthController->_StartTone; tone <= synthController->_EndTone; tone += 1.0f)
    {
        CC3MeshNode *spiralSegment = [synthController ToneSurfaceCC3Node:tone Count:24];
        spiralSegment.lineWidth = 3;
        [self addChild:spiralSegment];
    }
    
	self.opacity = 255;
    [self selectShaders];
	[self createBoundingVolumes];
	[self createGLBuffers];
	[self releaseRedundantContent];
}

@end


@implementation CvT3dSpiralLayer
@end


@implementation CvT2dSpiralLayer
@end


@implementation CvT2dSpiralScene

-(id)init:(CvTSpiralSynthController*)synthController
{
    self = [super init];
    
    CCNodeColor* colorLayer = [CCNodeColor nodeWithColor:[CCColor colorWithUIColor:[CvTPersonality BackgroundColor]]];
    [self addChild:colorLayer];

    CvT2dSpiralLayer *layer = [[CvT2dSpiralLayer alloc] init];
    [self addChild:layer];
    
    UIGraphicsBeginImageContext([CCDirector sharedDirector].view.bounds.size);
    for (float tone = synthController->_StartTone; tone <= synthController->_EndTone; tone += 1.0f)
    {
        //spiral
        UIBezierPath *spiralSegment = [synthController ToneSurfaceBezier:tone Count:16];
        int octave = (synthController->_CenterTone - tone - 1) / 12 - 1;
        [[CvTPersonality ToneColor:octave isScaleTone:[[CvTSynth Synth].Scale ContainsMidiTone:tone]] set];
        [spiralSegment fill];
        if ([[CvTSynth Synth].Scale MidiSolNumber:tone] == [CvTSynth Synth].Scale.TonalCentre)
        {
            [[[UIColor blackColor] colorWithAlphaComponent:0.5f] set];
            [spiralSegment fill];
        }
        [[[UIColor blackColor] colorWithAlphaComponent:1.0f] set];
        [spiralSegment setLineWidth:[CvTPersonality LineThickness:octave isScaleTone:[[CvTSynth Synth].Scale ContainsMidiTone:tone]]];
        [spiralSegment stroke];
        
        //circle
        if ([[CvTSynth Synth].Scale ContainsMidiTone:tone])
        {
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, [[[UIColor redColor] colorWithAlphaComponent:0.5f] CGColor]);
            CGContextFillEllipseInRect(context, [synthController ToneSurfaceCircleRect:tone]);
        }
        
        //text
        NSString *name = ((tone - synthController->_StartTone) < 12) ? [[CvTSynth Synth].Scale MidiSolName:tone] : @"";
        if (tone == (synthController->_EndTone - (12 - (synthController->_CenterTone - synthController->_EndTone) % 12)))
            name = [[CvTSynth Synth].Scale ContainsMidiTone:tone] ? [CvTScale MidiToneName:tone] : NULL;
        
        if (name != NULL)
        {
            int r = 20;
            CGPoint point = [synthController ToneToPoint:tone];
            CGRect circleRect = CGRectMake(point.x - r, point.y - r, r * 2, r * 2);
            NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
            paragraphStyle.alignment = NSTextAlignmentCenter;
            
            NSDictionary *textAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:20.0], NSParagraphStyleAttributeName: paragraphStyle };
            NSAttributedString *attributedName = [[NSAttributedString alloc] initWithString:name attributes:textAttributes];
            CGRect rect = [attributedName boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
            circleRect.origin.y += (circleRect.size.height - rect.size.height)/2;
            [attributedName drawInRect:circleRect];
        }
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CCSprite *sprite = [[CCSprite alloc] initWithCGImage:image.CGImage key:NULL];
    sprite.anchorPoint = ccp(0, 0);
    sprite.position = ccp(0, 0);
    [layer addChild:sprite];
    
    return self;
}

@end


@implementation CvTSpiralView

static CvTSpiralView *_Spiral;
+(CvTSpiralView*)Spiral {
    return _Spiral;
}

-(id)initWithFrame:(CGRect)frame
{
    self = _Spiral = [super initWithFrame:frame pixelFormat:kEAGLColorFormatRGBA8 depthFormat:GL_DEPTH24_STENCIL8_OES preserveBackbuffer:NO numberOfSamples:1];
    self.multipleTouchEnabled = TRUE;
    self.AutoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    [CvTAirplayJam AirplayJam].Delegate = self;
    
    CCDirectorIOS *director = (CCDirectorIOS *) [CCDirector sharedDirector];
    [director setView:self];
    [director setAnimationInterval:1.0/60];
    director.displayStats = TRUE;
    
    _SynthController = [[CvTSpiralSynthController alloc] initWithFrame:self.bounds];
    
    SetupButton = [UIButton buttonWithType:UIButtonTypeCustom];
    SetupButton.frame = CGRectMake(self.bounds.size.width - 50, self.bounds.size.height - 50, 50, 50);
    SetupButton.alpha = 0.8;
    [SetupButton setBackgroundImage:[UIImage imageNamed:@"lock.png"] forState:UIControlStateNormal];
    SetupButton.adjustsImageWhenHighlighted = FALSE;
    [self addSubview:SetupButton];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ToggleSetup)];
    doubleTap.numberOfTapsRequired = 2;
    [SetupButton addGestureRecognizer:doubleTap];
    
    ResetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    ResetButton.frame = CGRectMake(self.bounds.size.width - 50, 0, 50, 50);
    ResetButton.alpha = 0.3;
    [ResetButton addTarget:self action:@selector(Initialize) forControlEvents:UIControlEventTouchUpInside];
    [ResetButton setBackgroundImage:[UIImage imageNamed:@"wand.png"] forState:UIControlStateNormal];
    [self addSubview:ResetButton];
    
    CGPolarPoint p;
    p.Radius = 0;
    p.Angle = 0;
    CGPoint midPoint = [_SynthController PolarToRect:p];
    ChordName = [[UILabel alloc] initWithFrame:CGRectMake(midPoint.x - 250 / 2, midPoint.y - 50 / 2, 250, 50)];
    ChordName.textAlignment = NSTextAlignmentCenter;
    ChordName.backgroundColor = [UIColor clearColor];
    ChordName.textColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
    ChordName.font = [UIFont systemFontOfSize:40];
    [self addSubview:ChordName];
    
    return self;
}

-(void)Initialize
{
    [_SynthController Initialize];
    
    if ([CvTPersonality Use3d])
    {
        C3Layer = [[CvT3dSpiralLayer alloc] init];
        _C3Scene = [[CvT3dSpiralScene alloc] init];
        [_SynthController Resize:CGRectMake(-1, -1, 2, 2)];
        [_C3Scene initializeScene:_SynthController];
        C3Layer.cc3Scene = _C3Scene;
        _C2Scene = C3Layer.asCCScene;
    }
    else
    {
        _C2Scene = [[CvT2dSpiralScene alloc] init:_SynthController];
    }
    
    [[CvTSynth Synth] reset];
    [[CvTAirplayJam AirplayJam] Setup];

    if (![CCDirector sharedDirector].runningScene)
        [[CCDirector sharedDirector] runWithScene:_C2Scene];
    else
        [[CCDirector sharedDirector] replaceScene:_C2Scene];
}

-(void)ToggleSetup
{
    _SynthController->SetupMode = !_SynthController->SetupMode;
    [SetupButton setBackgroundImage:[UIImage imageNamed:_SynthController->SetupMode ? @"unlock.png" :  @"lock.png"] forState:UIControlStateNormal];
}

-(void)Receive:(CvTAirplayMessage*)message;
{
    switch (message.Type)
    {
        case kAirplayMessage_ChordOn:
            [self Play:message.Chord];
            break;
        case kAirplayMessage_ChordOff:
            [self Release:message.Chord.Ident];
            break;
        case kAirplayMessage_ChordSlide:
            [self Slide:message.Chord];
            break;
        case kAirplayMessage_Setup:
            [self Initialize];
            break;
        case kAirplayMessage_ChordNone:
            //remove all mute chords from source
            break;
    }
    ChordName.text = [[CvTSynth Synth] CurrentChord];
}

-(void)Play:(CvTSynthChord*)chord
{
    [[CvTSynth Synth] Play:chord];
    chord.Animation = C3Layer ? [[CvT3dAnimation alloc] init:chord] : [[CvT2dAnimation alloc] init:chord];
}

-(void)Slide:(float)tone ident:(long)ident
{
    [[CvTSynth Synth] Slide:tone ident:ident];
    [[[CvTSynth Synth] Animation:ident] Slide:NULL];
}

-(void)Slide:(CvTSynthChord*)chord
{
    [[[CvTSynth Synth] Animation:chord.Ident] Slide:chord];
}

-(void)Release:(long)ident
{
    [[CvTSynth Synth] Release:ident];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    int touchCount = 0;
    CvTSpiralTouch *spiralTouches[32];
    if (C3Layer)
    {
        CC3Camera *camera = _C3Scene.activeCamera;
        CC3Plane spiralPlane = { 0, 0, 1, 0 };
        
        for (UITouch* touch in [[event touchesForView:self] allObjects])
        {
            CC3Vector4 p = [camera unprojectPoint:[touch locationInView:self] ontoPlane:spiralPlane];
            spiralTouches[touchCount++] = [[CvTSpiralTouch alloc] init:touch.phase key:(uintptr_t)touch point:CGPointMake(p.x, p.y)];
        }
    }
    else
        for (UITouch* touch in [[event touchesForView:self] allObjects])
            spiralTouches[touchCount++] = [[CvTSpiralTouch alloc] init:touch.phase key:(uintptr_t)touch point:[touch locationInView:self]];
    
    [_SynthController touches:[[NSArray alloc] initWithObjects:spiralTouches count:touchCount] spiral:self];
    
    if (_SynthController->SetupMode)
        [self Initialize];
        
    ChordName.text = [[CvTSynth Synth] CurrentChord];
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesBegan:touches withEvent:event];
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesBegan:touches withEvent:event];
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesBegan:touches withEvent:event];
}

@end