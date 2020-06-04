//
//  IDAudioPlayer.h
//  doomengine
//
//  Created by Andrew Podrugin on 31.05.2020.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@protocol IDAudioPlayer<NSObject>

@property (nonatomic, readonly) BOOL playing;
@property (nonatomic, readonly) BOOL paused;
@property (nonatomic, readonly) float volume;

- (BOOL)playMusicAtPath:(NSString *)musicPath error:(NSError **)error;

- (BOOL)pauseAndReturnError:(NSError **)error;
- (BOOL)resumeAndReturnError:(NSError **)error;
- (BOOL)setVolume:(float)volume error:(NSError **)error;

- (BOOL)stopAndReturnError:(NSError **)error;

- (BOOL)tearDownAndReturnError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
