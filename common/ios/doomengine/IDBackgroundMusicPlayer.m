//
//  IDBackgroundMusicPlayer.m
//  doomengine
//
//  Created by Andrew Podrugin on 31.05.2020.
//

#import "IDBackgroundMusicPlayer.h"
#import "IDAudioPlayer.h"
#import "IDMIDIPlayer.h"
#import "IDHighQualityAudioPlayer.h"


NS_ASSUME_NONNULL_BEGIN

@interface IDBackgroundMusicPlayer()

@property (nonatomic, strong, nullable) IDMIDIPlayer *midiPlayer;
@property (nonatomic, strong, nullable) IDHighQualityAudioPlayer *highQualityPlayer;
@property (nonatomic, weak) id<IDAudioPlayer> currentPlayer;

@end


@implementation IDBackgroundMusicPlayer

#pragma mark - Properties -

- (BOOL)playing {
    return nil != self.currentPlayer && self.currentPlayer.playing;
}

- (BOOL)paused {
    return self.currentPlayer.paused;
}

#pragma mark - Memory management -

- (void)dealloc {
    [self tearDownAndReturnError:nil];
}

#pragma mark - Player interface -

- (BOOL)playMusicAtPath:(NSString *)musicPath ofType:(IDAudioType)type error:(NSError **)error {
    [self stopAndReturnError:nil];
    
    self.currentPlayer = [self audioPlayerForAudioType:type error:error];
    if (nil == self.currentPlayer) {
        return NO;
    }
    
    return [self.currentPlayer playMusicAtPath:musicPath error:error];
}

- (BOOL)pauseAndReturnError:(NSError **)error {
    return [self.currentPlayer pauseAndReturnError:error];
}

- (BOOL)resumeAndReturnError:(NSError **)error {
    return [self.currentPlayer resumeAndReturnError:error];
}

- (BOOL)setVolume:(float)volume error:(NSError **)error {
    __block BOOL result = YES;
    
    [self enumerateAllPlayers:^(id<IDAudioPlayer> _Nonnull player) {
        result &= [player setVolume:volume error:error];
    }];
    
    return result;
}

- (BOOL)stopAndReturnError:(NSError **)error {
    return [self.currentPlayer stopAndReturnError:error];
}

- (BOOL)tearDownAndReturnError:(NSError **)error {
    __block BOOL result = YES;
    
    [self enumerateAllPlayers:^(id<IDAudioPlayer> _Nonnull player) {
        result &= [player tearDownAndReturnError:error];
    }];
    
    [self releaseAllPlayers];
    
    return result;
}

#pragma mark - Managing players -

- (nullable id<IDAudioPlayer>)audioPlayerForAudioType:(IDAudioType)type error:(NSError **)error {
    switch (type) {
        case IDAudioTypeMIDI: {
            if (nil == self.midiPlayer) {
                self.midiPlayer = [[IDMIDIPlayer alloc] initAndReturnError:error];
            }
            
            return self.midiPlayer;
        }
            
        case IDAudioTypeHighQuality: {
            if (nil == self.highQualityPlayer) {
                self.highQualityPlayer = [[IDHighQualityAudioPlayer alloc] initAndReturnError:error];
            }
            
            return self.highQualityPlayer;
        }
    }
}

- (void)enumerateAllPlayers:(void (^)(id<IDAudioPlayer> player))enumerator {
    if (nil != self.midiPlayer) {
        enumerator(self.midiPlayer);
    }
    
    if (nil != self.highQualityPlayer) {
        enumerator(self.highQualityPlayer);
    }
}

- (void)releaseAllPlayers {
    self.midiPlayer = nil;
    self.highQualityPlayer = nil;
}

@end

NS_ASSUME_NONNULL_END
