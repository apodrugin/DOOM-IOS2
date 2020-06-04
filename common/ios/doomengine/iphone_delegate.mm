/*
 
 Copyright (C) 2009-2011 id Software LLC, a ZeniMax Media company. 
 
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

#import "iphone_delegate.h"

#import <AudioToolbox/AudioServices.h>
#import <CoreMotion/CoreMotion.h>
#include "doomiphone.h"
#include "iphone_common.h"
#include "ios/InAppStore.h"
#include "ios/GameCenter.h"


@interface iphoneApp()

@property (nonatomic, strong) CMMotionManager *motionManager;

@end


@implementation iphoneApp

@synthesize window;

iphoneApp * gAppDelegate = NULL;
bool inBackgroundProcess = false;

touch_t		sysTouches[MAX_TOUCHES];
touch_t		gameTouches[MAX_TOUCHES];

#define FRAME_HERTZ 30.0f
const static float ACCELEROMETER_UPDATE_INTERVAL = 1.0f / FRAME_HERTZ;

/*
 ========================
 applicationDidFinishLaunching
 ========================
 */
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    gAppDelegate = self;
    inBackgroundProcess = false;
	hasPushedGLView = NO;
    
    // Create the window programmatically instead of loading from a nib file.
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    // Disable Screen Dimming.
    [[ UIApplication sharedApplication] setIdleTimerDisabled: YES ];
    
    // Initial Application Style config.
    [ application setStatusBarHidden: YES ];
    
    self.motionManager = [CMMotionManager new];
    if ([self.motionManager isAccelerometerAvailable]) {
        // start the flow of accelerometer events
        [self.motionManager setAccelerometerUpdateInterval:ACCELEROMETER_UPDATE_INTERVAL];
        [self.motionManager
         startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
         withHandler:^(CMAccelerometerData *accelerometerData, NSError *error)
         {
            float acc[4];
            acc[0] = accelerometerData.acceleration.x;
            acc[1] = accelerometerData.acceleration.y;
            acc[2] = accelerometerData.acceleration.z;
            acc[3] = accelerometerData.timestamp;

            iphoneTiltEvent( acc );
        }];
    }
    
    [self InitializeInterfaceBuilder ];

	CommonSystemSetup( [navigationController topViewController] );
	
    // do all the game startup work
	iphoneStartup();
    
    UIView * view = navigationController.view;
	
    [window addSubview: view];
	[window setRootViewController:navigationController];
    [window setBackgroundColor: [UIColor blackColor] ];
	[window makeKeyAndVisible];
}

/*
 ========================
 applicationWillResignActive
 ========================
 */
- (void)applicationWillResignActive:(UIApplication *)application {
    inBackgroundProcess = YES;
    
	idGameCenter::HandleMoveToBackground();
	
	// If we're in a multiplater game, and showing the OpenGL view,
	// go back to the main menu since the multiplayer game is hosed.
	if ( netgame && navigationController.topViewController == gAppDelegate->openGLViewController ) {
		iphoneMainMenu();
	}
	
	iphonePauseMusic();
    iphoneShutdown();
}

/*
 ========================
 applicationDidBecomeActive
 ========================
 */
- (void)applicationDidBecomeActive:(UIApplication *)application {
	inBackgroundProcess = NO;
}


/*
 ========================
 applicationWillTerminate
 ========================
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	iphoneStopMusic();
	iphoneShutdown();
}


/*
 ========================
 applicationDidReceiveMemoryWarning
 ========================
 */
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	Com_Printf( "applicationDidReceiveMemoryWarning\n" );
}


/*
 ========================
 HACK_PushController  - Removes Flicker from Loading Wads.
  God forgive me.
 
 ========================
 */
- (void) HACK_PushController {
    [navigationController pushViewController:openGLViewController animated:NO];
}

/*
 ========================
 ShowGLView 
 ========================
 */
- (void)ShowGLView {
	
    if( hasPushedGLView == NO ) {
		hasPushedGLView = YES;
		// Hack city.
		[NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(HACK_PushController) userInfo:nil repeats:NO];

		[ openGLViewController StartDisplay ];
    }
}

/*
 ========================
 HideGLView 
 ========================
 */
- (void) HideGLView {
    
    [ navigationController popToRootViewControllerAnimated:NO ];
	hasPushedGLView = NO;
}

/*
 ========================
 PopGLView 
 ========================
 */
- (void) PopGLView {
    [ navigationController popViewControllerAnimated:NO];
    hasPushedGLView = NO;
}


/*
 ========================
 InitializeInterfaceBuilder 
 ========================
 */
- (void) InitializeInterfaceBuilder {
    
}

@end

void ShowGLView( void ) {
	[ gAppDelegate ShowGLView ];
}

