//
//  IDMIDIPlayer.m
//  doomengine
//
//  Created by Andrew Podrugin on 31.05.2020.
//

#import "IDMIDIPlayer.h"
#import <AudioToolbox/AudioToolbox.h>


NS_ASSUME_NONNULL_BEGIN

@interface IDMIDIPlayer()

@property (nonatomic, assign, nullable) AUGraph processingGraph;
@property (nonatomic, assign) MIDIEndpointRef virtualEndpoint;
@property (nonatomic, assign, nullable) MusicPlayer player;
@property (nonatomic, assign, nullable) MusicSequence currentMusicSequence;

@end


@implementation IDMIDIPlayer

#pragma mark - Properties -

@synthesize playing = _playing;
@synthesize paused = _paused;
@synthesize volume = _volume;

#pragma mark - Initialization -

- (instancetype)initAndReturnError:(NSError **)error {
    if (nil == (self = [super init])) {
        return nil;
    }
    
    _volume = 1;
    
    NSLog (@"Configuring and then initializing audio processing graph");
    OSStatus result = noErr;
    
    // Instantiate an audio processing graph
    if (noErr != (result = NewAUGraph(&_processingGraph))) {
        NSAssert(NO, @"Unable to create an AUGraph object. Error code: %d", (int)result);
        return nil;
    }
    
    // Specify the common portion of an audio unit's identify, used for both audio units
    // in the graph.
    // Setup the manufacturer - in this case Apple
    AudioComponentDescription componentDescription = {};
    
    componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    //Specify the Sampler unit, to be used as the first node of the graph
    componentDescription.componentType = kAudioUnitType_MusicDevice; // type - music device
    componentDescription.componentSubType = kAudioUnitSubType_Sampler; // sub type - sampler to convert our MIDI
    
    // Add the Sampler unit node to the graph
    AUNode samplerNode;
    
    if (noErr != (result = AUGraphAddNode(_processingGraph, &componentDescription, &samplerNode))) {
        NSAssert(NO, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d", (int)result);
        return nil;
    }
    
    // Specify the Output unit, to be used as the second and final node of the graph
    componentDescription.componentType = kAudioUnitType_Output;  // Output
    componentDescription.componentSubType = kAudioUnitSubType_RemoteIO;  // Output to speakers
    
    // Add the Output unit node to the graph
    AUNode ioNode;
    
    if (noErr != (result = AUGraphAddNode(_processingGraph, &componentDescription, &ioNode))) {
        NSAssert(NO, @"Unable to add the Output unit to the audio processing graph. Error code: %d", (int)result);
        return nil;
    }
    
    // Open the graph
    if (noErr != (result = AUGraphOpen(_processingGraph))) {
        NSAssert(NO, @"Unable to open the audio processing graph. Error code: %d", (int)result);
        return nil;
    }
    
    // Connect the Sampler unit to the output unit
    if (noErr != (result = AUGraphConnectNodeInput(_processingGraph, samplerNode, 0, ioNode, 0))) {
        NSAssert(NO, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d", (int)result);
        return nil;
    }
    
    // Obtain a reference to the Sampler unit from its node
    AudioUnit samplerUnit;
    
    if (noErr != (result = AUGraphNodeInfo(_processingGraph, samplerNode, 0, &samplerUnit))) {
        NSAssert(NO, @"Unable to obtain a reference to the Sampler unit. Error code: %d", (int)result);
        return nil;
    }
    
    // Obtain a reference to the I/O unit from its node
    AudioUnit ioUnit;
    
    if (noErr != (result = AUGraphNodeInfo(_processingGraph, ioNode, 0, &ioUnit))) {
        NSAssert(NO, @"Unable to obtain a reference to the I/O unit. Error code: %d", (int)result);
        return nil;
    }
    
    // Diagnostic code
    // Call CAShow if you want to look at the state of the audio processing
    //    graph.
    NSLog(@"Audio processing graph state immediately before initializing it:");
    CAShow(_processingGraph);
    
    NSLog (@"Initializing the audio processing graph");
    
    // Initialize the audio processing graph, configure audio data stream formats for
    //    each input and output, and validate the connections between audio units.
    if (noErr != (result = AUGraphInitialize(_processingGraph))) {
        NSAssert(NO, @"Failed to initialize AUGraph. Error code: %d", (int)result);
        return nil;
    }
    
    // Create a client
    MIDIClientRef virtualMidi;
    
    if (noErr != (result = MIDIClientCreate(CFSTR("Virtual Client"), NULL, NULL, &virtualMidi))) {
        NSAssert(NO, @"Failed to create MIDI client. Error code: %d", (int)result);
        return nil;
    }
    
    // Create an endpoint
    if (noErr != (result = MIDIDestinationCreate(virtualMidi,
                                                 CFSTR("Virtual Destination"),
                                                 MIDIReadHandler,
                                                 samplerUnit,
                                                 &_virtualEndpoint)))
    {
        NSAssert(NO, @"MIDIDestinationCreate failed. Error code: %d", (int)result);
        return nil;
    }
    
    // Initialise the music player
    if (noErr != (result = NewMusicPlayer(&_player))) {
        NSAssert(NO, @"Failed to create music player. Error code: %d", (int)result);
        return nil;
    }
    
    return self;
}

#pragma mark - Memory management -

- (void)dealloc {
    [self tearDownAndReturnError:nil];
}

- (BOOL)playMusicAtPath:(NSString *)musicPath error:(NSError **)error {
    if (self.playing || self.paused) {
        if (NO == [self stopAndReturnError:error]) {
            return NO;
        }
    }
    NSLog (@"Starting audio processing graph");
    OSStatus result = AUGraphStart(self.processingGraph);
    
    if (noErr != result) {
        NSAssert(NO, @"AUGraphStart failed. Error code: %d", (int)result);
        return NO;
    }

    if (noErr != (result = NewMusicSequence(&_currentMusicSequence))) {
        NSAssert(NO, @"Failed to create music sequence. Error code: %d", (int)result);
        return NO;
    }
    
    NSURL *midiFileURL = [NSURL fileURLWithPath:musicPath];
    
    if (noErr != (result = MusicSequenceFileLoad(self.currentMusicSequence,
                                                 (__bridge CFURLRef)midiFileURL,
                                                 kMusicSequenceFile_MIDIType,
                                                 0)))
    {
        NSAssert(NO, @"Failed to load data from file at path %@. Error code: %d", musicPath, (int)result);
        return NO;
    }

    if (noErr != (result = MusicSequenceSetMIDIEndpoint(self.currentMusicSequence, self.virtualEndpoint))) {
        NSAssert(NO, @"Failed to set MIDI endoint. Error code: %d", (int)result);
        return NO;
    }

    if (noErr != (result = MusicPlayerSetSequence(self.player, self.currentMusicSequence))) {
        NSAssert(NO, @"Failed to set music sequence. Error code: %d", (int)result);
        return NO;
    }
    
    if (noErr != (result = MusicPlayerPreroll(self.player))) {
        NSAssert(NO, @"MusicPlayerPreroll failed. Error code: %d", (int)result);
        return NO;
    }
    
    return [self resumeAndReturnError:error];
}

- (BOOL)pauseAndReturnError:(NSError **)error {
    const OSStatus result = MusicPlayerStop(self.player);
    
    if (noErr != result) {
        NSAssert(NO, @"Failed to pause music player. Error code: %d", (int)result);
        return NO;
    }
    
    _paused = YES;
    _playing = NO;
    
    return YES;
}

- (BOOL)resumeAndReturnError:(NSError **)error {
    const OSStatus result = MusicPlayerStart(self.player);
    
    if (noErr != result) {
        NSAssert(NO, @"Failed to resume music player. Error code: %d", (int)result);
        return NO;
    }
    
    _playing = YES;
    _paused = NO;
    
    return YES;
}

- (BOOL)setVolume:(float)volume error:(NSError **)error {
    return YES;
}

- (BOOL)stopAndReturnError:(NSError **)error {
    if (NO == [self pauseAndReturnError:error]) {
        return NO;
    }
    
    OSStatus result = noErr;
    
    if (noErr != (result = DisposeMusicSequence(self.currentMusicSequence))) {
        NSAssert(NO, @"Failed to dispose music sequence. Error code: %d", (int)result);
        return NO;
    }
    
    if (noErr != (result = AUGraphStop(self.processingGraph))) {
        NSAssert(NO, @"Failed to resume music player. Error code: %d", (int)result);
        return NO;
    }
    
    _playing = NO;
    _paused = NO;
    
    return YES;
}

- (BOOL)tearDownAndReturnError:(NSError **)error {
    if (NO == [self stopAndReturnError:error]) {
        return NO;
    }
    
    if (NULL != self.processingGraph) {
        DisposeAUGraph(self.processingGraph);
        self.processingGraph = nil;
    }
    
    if (NULL != self.player) {
        DisposeMusicPlayer(self.player);
        self.player = NULL;
    }
    
    return YES;
}

static void MIDIReadHandler(const MIDIPacketList *pktlist, void *refCon, void *connRefCon) {
    AudioUnit *player = (AudioUnit *)refCon;
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
    
    for (int i = 0; i < pktlist->numPackets; i++) {
        const Byte midiStatus = packet->data[0];
        const Byte midiCommand = midiStatus >> 4;
        
        if (midiCommand == 0x09) {
            const Byte note = packet->data[1] & 0x7F;
            const Byte velocity = packet->data[2] & 0x7F;
            const OSStatus result = MusicDeviceMIDIEvent((void *)player, midiStatus, note, velocity, 0);
            
            if (noErr != result) {
                NSLog(@"Failed to sent MIDI channel message. Error code: %d", (int)result);
            }
        }
        
        packet = MIDIPacketNext(packet);
    }
}

@end

NS_ASSUME_NONNULL_END
