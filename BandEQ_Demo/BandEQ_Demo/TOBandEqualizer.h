//
//  TOBandEqualizer.h
//  TheEngineSample
//
//  Created by lc on 13-4-9.
//  Copyright (c) 2013年 A Tasty Pixel. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface TOBandEqualizer : NSObject
@property ( nonatomic) UInt32 maxNumberOfBands;
@property ( nonatomic) UInt32 numBands; // Can only be set if the equalizer unit is uninitialized.
@property ( nonatomic,retain) NSArray *bands;

- (void)setUp;
- (void)setUpFilePlayerUnit;

- (AudioUnitParameterValue)gainForBandAtPosition:(NSUInteger)bandPosition;
- (void)setGain:(AudioUnitParameterValue)gain forBandAtPosition:(NSUInteger)bandPosition;

@end
