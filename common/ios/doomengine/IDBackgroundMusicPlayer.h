//
//  IDBackgroundMusicPlayer.h
//  doomengine
//
//  Created by Andrew Podrugin on 31.05.2020.
//

#import <Foundation/Foundation.h>
#import "IDAudioType.h"


NS_ASSUME_NONNULL_BEGIN

@interface IDBackgroundMusicPlayer : NSObject

@property (nonatomic, readonly) BOOL playing;
@property (nonatomic, readonly) BOOL paused;
@property (nonatomic, readonly) float volume;

- (BOOL)playMusicAtPath:(NSString *)musicPath ofType:(IDAudioType)type error:(NSError **)error;

- (BOOL)pauseAndReturnError:(NSError **)error;
- (BOOL)resumeAndReturnError:(NSError **)error;
- (BOOL)setVolume:(float)volume error:(NSError **)error;

- (BOOL)stopAndReturnError:(NSError **)error;

- (BOOL)tearDownAndReturnError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
