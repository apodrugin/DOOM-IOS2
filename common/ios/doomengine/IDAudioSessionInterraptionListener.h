//
//  IDAudioSessionInterraptionListener.h
//  doomengine
//
//  Created by Andrew Podrugin on 25.05.2020.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


NS_ASSUME_NONNULL_BEGIN

typedef void (^IDAudioSessionInterraptionListenerHandler)(AVAudioSessionInterruptionType interruptionType);


@interface IDAudioSessionInterraptionListener : NSObject

+ (instancetype)sharedListener;

- (void)addAudioSessionInterraptionHandler:(IDAudioSessionInterraptionListenerHandler)handler;

@end

NS_ASSUME_NONNULL_END
