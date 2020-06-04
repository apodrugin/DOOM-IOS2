/*
 
 Copyright (C) 2011 Id Software, Inc.
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 */
 
 
/*
===============================

iOS implementation of our SDL_Mixer shim for playing MIDI files.

===============================
*/

#include <stddef.h>
#include "SDL_Mixer.h"
#import "IDBackgroundMusicPlayer.h"


static IDBackgroundMusicPlayer *_backgroundMusicPlayer = nil;
static NSError *_lastError = nil;


/* Open the mixer with a certain audio format */
int Mix_OpenAudio(int frequency, uint16_t format, int channels, int chunksize) {
    _backgroundMusicPlayer = [IDBackgroundMusicPlayer new];
	return 0;
}

/* Close the mixer, halting all playing audio */
void Mix_CloseAudio(void) {
    NSError *error = nil;
    
    [_backgroundMusicPlayer tearDownAndReturnError:&error];
    _lastError = error;
    _backgroundMusicPlayer = nil;
}

/* Set a function that is called after all mixing is performed.
   This can be used to provide real-time visual display of the audio stream
   or add a custom mixer filter for the stream data.
*/
void Mix_SetPostMix(void (*mix_func)(void *udata, uint8_t *stream, int len), void *arg) {
}

/* Fade in music or a channel over "ms" milliseconds, same semantics as the "Play" functions */
int Mix_FadeInMusic(Mix_Music *music, int loops, int ms) {
    NSString *musicPath = [NSString stringWithUTF8String:music->path];
    NSError *error = nil;

    if (NO == [_backgroundMusicPlayer playMusicAtPath:musicPath ofType:music->type error:&error]) {
        _lastError = error;
        return -1;
    }
    
	return 0;
}

/* Pause/Resume the music stream */
void Mix_PauseMusic(void) {
    NSError *error = nil;
    
    [_backgroundMusicPlayer pauseAndReturnError:&error];
    _lastError = error;
}

void Mix_ResumeMusic(void) {
    NSError *error = nil;
    
    [_backgroundMusicPlayer resumeAndReturnError:&error];
    _lastError = error;
}

/* Halt a channel, fading it out progressively till it's silent
   The ms parameter indicates the number of milliseconds the fading
   will take.
 */
int Mix_FadeOutMusic(int ms) {
    NSError *error = nil;
    
    if (NO == [_backgroundMusicPlayer stopAndReturnError:&error]) {
        _lastError = error;
        return -1;
    }
    
	return 0;
}

/* Free an audio chunk previously loaded */
void Mix_FreeMusic(Mix_Music *music) {
	free(music);
}

Mix_Music * Mix_LoadMusic(IDAudioType type, const char *file) {
	Mix_Music *music = malloc( sizeof(Mix_Music) );
    
    music->type = type;
    strncpy(music->path, file, sizeof(music->path));
	return music;
}

const char * Mix_GetError(void) {
    return _lastError.localizedDescription.UTF8String;
}

/* Set the volume in the range of 0-128. */
void Mix_VolumeMusic(int volume) {
    if (volume < 0) {
        volume = 0;
    }
    else if (volume > 128) {
        volume = 128;
    }
    NSError *error = nil;
    
    [_backgroundMusicPlayer setVolume:volume / 128.f error:&error];
    _lastError = error;
}
