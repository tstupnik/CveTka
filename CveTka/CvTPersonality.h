//
//  CvTPersonality.h
//  CveTka
//
//  Created by tomaz stupnik on 9/6/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CvTPersonality : NSObject

+(UIColor*)BackgroundColor;
+(UIColor*)ToneColor:(int)octave isScaleTone:(BOOL)isScaleTone;
+(float)LineThickness:(int)octave isScaleTone:(BOOL)isScaleTone;
+(BOOL)Use3d;

@end
