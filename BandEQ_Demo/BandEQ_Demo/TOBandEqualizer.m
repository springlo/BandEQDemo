//
//  TOBandEqualizer.m
//  TheEngineSample
//
//  Created by lc on 13-4-9.
//  Copyright (c) 2013年 A Tasty Pixel. All rights reserved.
//

//
//  TOBandEqualizer.h
//  EqualizerTest
//
//  Created by Tobias Ottenweller on 17.08.12.
//  Copyright (c) 2012 Tobias Ottenweller. All rights reserved.
//

#import "TOBandEqualizer.h"

@interface TOBandEqualizer()
{
    AUGraph graph;
    
    AudioUnit equalizerUnit;
    AudioUnit filePlayerUnit;
    AudioUnit rioUnit;
    
    AudioFileID audioFile;
}



@end


void TOThrowOnError(OSStatus status)
{
    if (status != noErr) {
        @throw [NSException exceptionWithName:@"TOAudioErrorException"
                                       reason:[NSString stringWithFormat:@"Status is not 'noErr'! Status is %ld).", status]
                                     userInfo:nil];
    }
}


OSStatus TOAUGraphAddNode(OSType inComponentType, OSType inComponentSubType, AUGraph inGraph, AUNode *outNode)
{
    AudioComponentDescription desc;
	desc.componentType = inComponentType;
	desc.componentSubType = inComponentSubType;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    return AUGraphAddNode(inGraph, &desc, outNode);
}



@implementation TOBandEqualizer


- (void)setUp
{
    //............................................................................
    // Create AUGraph
    
    TOThrowOnError(NewAUGraph(&graph));
    
    
    
    //............................................................................
    // Add Audio Units (Nodes) to the graph
    AUNode filePlayerNode, rioNode, eqNode;
    
    // file player unit
    TOThrowOnError(TOAUGraphAddNode(kAudioUnitType_Generator,
                                    kAudioUnitSubType_AudioFilePlayer,
                                    graph,
                                    &filePlayerNode));
    
    
    // remote IO unit
    TOThrowOnError(TOAUGraphAddNode(kAudioUnitType_Output,
                                    kAudioUnitSubType_RemoteIO,
                                    graph,
                                    &rioNode));
    
    // EQ unit
    TOThrowOnError(TOAUGraphAddNode(kAudioUnitType_Effect,
                                    kAudioUnitSubType_NBandEQ,
                                    graph,
                                    &eqNode));
    
    
    //............................................................................
    // Open the processing graph.
    
    TOThrowOnError(AUGraphOpen(graph));
    
    
    //............................................................................
    // Obtain the audio unit instances from its corresponding node.
    
    TOThrowOnError(AUGraphNodeInfo(graph,
                                   filePlayerNode,
                                   NULL,
                                   &filePlayerUnit));
    
    TOThrowOnError(AUGraphNodeInfo(graph,
                                   eqNode,
                                   NULL,
                                   &equalizerUnit));
    
    TOThrowOnError(AUGraphNodeInfo(graph,
                                   rioNode,
                                   NULL,
                                   &rioUnit));
    
    
    //............................................................................
    // Connect the nodes of the audio processing graph
    
    TOThrowOnError(AUGraphConnectNodeInput(graph,
                                           filePlayerNode,      // source node
                                           0,                   // source bus
                                           eqNode,              // destination node
                                           0));                 // destination bus
    
    TOThrowOnError(AUGraphConnectNodeInput(graph,
                                           eqNode,
                                           0,
                                           rioNode,
                                           0));
    
    //............................................................................
    // Set properties/parameters of the units inside the graph
    
    // Set number of bands for the EQ unit
    // Set the frequencies for each band of the EQ unit
    NSArray *eqFrequencies = @[ @32, @64, @125, @250, @500, @1000, @2000, @4000, @8000, @16000 ];
    self.numBands = eqFrequencies.count;
    self.bands = eqFrequencies;
    
    
    
    //............................................................................
    // Initialize Graph
    TOThrowOnError(AUGraphInitialize(graph));
    
    
    //............................................................................
    // other audio unit setup
    [self setUpFilePlayerUnit];
    
    
    //............................................................................
    // Start the Graph
    TOThrowOnError(AUGraphStart(graph));
}


- (void)setUpFilePlayerUnit
{
    NSURL *songURL = [[NSBundle mainBundle] URLForResource:@"11" withExtension:@"mp3"];
    TOThrowOnError(AudioFileOpenURL((CFURLRef)CFBridgingRetain(songURL), kAudioFileReadPermission, 0, &audioFile));
    
    TOThrowOnError(AudioUnitSetProperty(filePlayerUnit,
                                        kAudioUnitProperty_ScheduledFileIDs,
                                        kAudioUnitScope_Global,
                                        0,
                                        &audioFile,
                                        sizeof(audioFile)));

    // get input file format
    AudioStreamBasicDescription audioFileASBD;
    UInt32 propSize = sizeof(audioFileASBD);
    TOThrowOnError(AudioFileGetProperty(audioFile,
                                        kAudioFilePropertyDataFormat,
                                        &propSize,
                                        &audioFileASBD));
    
	UInt64 nPackets;
	UInt32 propsize = sizeof(nPackets);
	TOThrowOnError(AudioFileGetProperty(audioFile,
                                        kAudioFilePropertyAudioDataPacketCount,
                                        &propsize,
                                        &nPackets));
    
	// tell the file player AU to play the entire file
	ScheduledAudioFileRegion rgn;
	memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
	rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	rgn.mTimeStamp.mSampleTime = 0;
	rgn.mCompletionProc = NULL;
	rgn.mCompletionProcUserData = NULL;
	rgn.mAudioFile = audioFile;
	rgn.mLoopCount = 0;
	rgn.mStartFrame = 0;
	rgn.mFramesToPlay =(UInt32) nPackets * audioFileASBD.mFramesPerPacket;
	
	TOThrowOnError(AudioUnitSetProperty(filePlayerUnit,
                                        kAudioUnitProperty_ScheduledFileRegion,
                                        kAudioUnitScope_Global,
                                        0,
                                        &rgn,
                                        sizeof(rgn)));
    
	// prime the file player AU with default values
	UInt32 defaultVal = 0;
	TOThrowOnError(AudioUnitSetProperty(filePlayerUnit,
                                        kAudioUnitProperty_ScheduledFilePrime,
                                        kAudioUnitScope_Global,
                                        0,
                                        &defaultVal,
                                        sizeof(defaultVal)));
	
	// tell the file player AU when to start playing (-1 sample time means next render cycle)
	AudioTimeStamp startTime;
	memset (&startTime, 0, sizeof(startTime));
	startTime.mFlags = kAudioTimeStampSampleTimeValid;
	startTime.mSampleTime = -1;
    
	TOThrowOnError(AudioUnitSetProperty(filePlayerUnit,
                                        kAudioUnitProperty_ScheduleStartTimeStamp,
                                        kAudioUnitScope_Global,
                                        0,
                                        &startTime,
                                        sizeof(startTime)));
}

# pragma mark - EQ wrapper methods

- (UInt32)maxNumberOfBands
{
    UInt32 maxNumBands = 0;
    UInt32 propSize = sizeof(maxNumBands);
    TOThrowOnError(AudioUnitGetProperty(equalizerUnit,
                                        kAUNBandEQProperty_MaxNumberOfBands,
                                        kAudioUnitScope_Global,
                                        0,
                                        &maxNumBands,
                                        &propSize));
    
    return maxNumBands;
}


- (UInt32)numBands
{
    UInt32 numBands;
    UInt32 propSize = sizeof(numBands);
    TOThrowOnError(AudioUnitGetProperty(equalizerUnit,
                                        kAUNBandEQProperty_NumberOfBands,
                                        kAudioUnitScope_Global,
                                        0,
                                        &numBands,
                                        &propSize));
    
    return numBands;
}


- (void)setNumBands:(UInt32)numBands
{
    TOThrowOnError(AudioUnitSetProperty(equalizerUnit,
                                        kAUNBandEQProperty_NumberOfBands,
                                        kAudioUnitScope_Global,
                                        0,
                                        &numBands,
                                        sizeof(numBands)));
}


- (void)setBands:(NSArray *)bands
{
    _bands = bands;
    NSLog(@"set bands:%@",bands);
    for (NSUInteger i=0; i<bands.count; i++) {
        TOThrowOnError(AudioUnitSetParameter(equalizerUnit,
                                             kAUNBandEQParam_Frequency+i,
                                             kAudioUnitScope_Global,
                                             0,
                                             (AudioUnitParameterValue)[[bands objectAtIndex:i] floatValue],
                                             0));
        
        
        /* //setting the bypassBand paramter does work!
                TOThrowOnError(AudioUnitSetParameter(equalizerUnit,
                                                     kAUNBandEQParam_BypassBand+i,
                                                     kAudioUnitScope_Global,
                                                     0,
                                                     1,
                                                     0));
        
                TOThrowOnError(AudioUnitSetParameter(equalizerUnit,
                                                     kAUNBandEQParam_FilterType+i,
                                                     kAudioUnitScope_Global,
                                                     0,
                                                     kAUNBandEQFilterType_BandPass,
                                                     0));
        
                TOThrowOnError(AudioUnitSetParameter(equalizerUnit,
                                                     kAUNBandEQParam_Bandwidth+i,
                                                     kAudioUnitScope_Global,
                                                     0,
                                                     5.0,
                                                     0));
         */
    }
}


- (AudioUnitParameterValue)gainForBandAtPosition:(NSUInteger)bandPosition
{
    AudioUnitParameterValue gain;
    AudioUnitParameterID parameterID = kAUNBandEQParam_Gain + bandPosition;
    
    TOThrowOnError(AudioUnitGetParameter(equalizerUnit,
                                         parameterID,
                                         kAudioUnitScope_Global,
                                         0,
                                         &gain));
    
    return gain;
}


- (void)setGain:(AudioUnitParameterValue)gain forBandAtPosition:(NSUInteger)bandPosition
{
    AudioUnitParameterID parameterID = kAUNBandEQParam_Gain + bandPosition;
    
    TOThrowOnError(AudioUnitSetParameter(equalizerUnit,
                                         parameterID,
                                         kAudioUnitScope_Global,
                                         0,
                                         gain,
                                         0));
}


@end