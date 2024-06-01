//
//  CvTPersonality.m
//  CveTka
//
//  Created by tomaz stupnik on 9/6/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTPersonality.h"
#import "CvTAppSettings.h"


@implementation CvTPersonality

+(NSArray*)Current{
    NSDictionary *dictionary = @{
                            @(kAppPersonality_Bach) :
  @[[UIColor blackColor],
    @[[UIColor purpleColor], @[@1.0f]],
    @[[UIColor yellowColor], @[@0.0f]],
    @[@2, @1],
    @0],
                            @(kAppPersonality_Sibelius) :
  @[[UIColor blueColor],
    @[[UIColor purpleColor], @[@0.25f, @0.5f, @0.75f, @1.0f]],
    @[[UIColor yellowColor], @[@0.35f, @0.55f, @0.80f, @1.0f]],
    @[@2, @1],
    @1],
                            @(kAppPersonality_Dvorak) :
  @[[UIColor redColor],
    @[[UIColor purpleColor], @[@0.25f, @0.5f, @0.75f, @1.0f]],
    @[[UIColor yellowColor], @[@0.35f, @0.55f, @0.80f, @1.0f]],
    @[@2, @1],
    @0],
                            @(kAppPersonality_Mercury) :
  @[[UIColor blackColor],
    @[[UIColor yellowColor], @[@0.25f, @0.5f, @0.75f, @1.0f]],
    @[[UIColor whiteColor], @[@0.35f, @0.55f, @0.80f, @1.0f]],
    @[@2, @1],
    @0]
                            };
    return [dictionary objectForKey:[NSNumber numberWithInt:[CvTAppSettings Current].Personality]];
}

+(UIColor*)BackgroundColor{
    return [self Current][0];
}

+(UIColor*)ToneColor:(int)octave isScaleTone:(BOOL)isScaleTone
{
    NSArray *array = [self Current][isScaleTone ? 1 : 2];
    return [array[0] colorWithAlphaComponent:[array[1][octave % ((NSArray*)array[1]).count] floatValue]];
}

+(float)LineThickness:(int)octave isScaleTone:(BOOL)isScaleTone {
    return [[self Current][3][isScaleTone ? 0 : 1] floatValue];
}

+(BOOL)Use3d {
     return [[self Current][4] boolValue];
}

@end
