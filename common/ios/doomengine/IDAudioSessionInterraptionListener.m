//
//  IDAudioSessionInterraptionListener.m
//  doomengine
//
//  Created by Andrew Podrugin on 25.05.2020.
//

#import "IDAudioSessionInterraptionListener.h"


NS_ASSUME_NONNULL_BEGIN

@interface IDAudioSessionInterraptionListener()

@property (nonatomic, readonly) NSMutableArray<IDAudioSessionInterraptionListenerHandler> *handlers;

@end


@implementation IDAudioSessionInterraptionListener

#pragma mark - Initialization -

+ (instancetype)sharedListener {
    static dispatch_once_t onceToken;
    static IDAudioSessionInterraptionListener *sharedListener = nil;
    
    dispatch_once(&onceToken, ^{
        sharedListener = [self new];
    });
    
    return sharedListener;
}

- (instancetype)init {
    if (nil == (self = [super init])) {
        return nil;
    }
    
    _handlers = [NSMutableArray new];
    [self startListening];
    
    return self;
}

#pragma mark - Memory management -

- (void)dealloc {
    [self stopListening];
}

#pragma mark - Notifications handling -

- (void)startListening {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionDidChangeInterruptionType:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
}

- (void)stopListening {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)audioSessionDidChangeInterruptionType:(NSNotification *)notification {
    const AVAudioSessionInterruptionType interruptionType = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    NSArray<IDAudioSessionInterraptionListenerHandler> *handlers;
    
    @synchronized (self.handlers) {
        handlers = [self.handlers copy];
    }
    
    for (IDAudioSessionInterraptionListenerHandler handler in handlers) {
        handler(interruptionType);
    }
}

#pragma mark - Managing handlers -

- (void)addAudioSessionInterraptionHandler:(IDAudioSessionInterraptionListenerHandler)handler {
    @synchronized (self.handlers) {
        [self.handlers addObject:handler];
    }
}

@end

NS_ASSUME_NONNULL_END
