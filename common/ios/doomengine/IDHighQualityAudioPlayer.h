//
//  IDHighQualityAudioPlayer.h
//  doomengine
//
//  Created by Andrew Podrugin on 31.05.2020.
//

#import <Foundation/Foundation.h>
#import "IDAudioPlayer.h"


NS_ASSUME_NONNULL_BEGIN

@interface IDHighQualityAudioPlayer : NSObject<IDAudioPlayer>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initAndReturnError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
