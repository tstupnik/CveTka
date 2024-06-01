//
//  CvTAppDelegate.m
//  CveTka
//
//  Created by tomaz stupnik on 5/23/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <HockeySDK/HockeySDK.h>

#import "CvTAppDelegate.h"
#import "CvTViewController.h"
#import "CvTSpiralView.h"

@interface CvTAppDelegate()
@end


@implementation CvTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSUUID *iZixId = [[NSUUID alloc] initWithUUIDString:@"084F1672-D583-42A6-883F-C65EBC4E76AF"];
    if (![iZixId isEqual:[[UIDevice currentDevice] identifierForVendor]])
    {
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"4dc869ee0fed17e8c898084e1799cf21" delegate: nil];
        [[BITHockeyManager sharedHockeyManager].authenticator setAuthenticationSecret:@"7011d2446e99d63c6c43841048231f52"];
        [[BITHockeyManager sharedHockeyManager].authenticator setIdentificationType:BITAuthenticatorIdentificationTypeHockeyAppEmail];
        [[BITHockeyManager sharedHockeyManager] startManager];
        [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
        //[[BITHockeyManager sharedHockeyManager] setDisableUpdateManager: YES];
    }

    application.statusBarHidden = YES;
    
    [[CvTSynth Synth] start];
    [CvTSynth Synth].AudiobusController.stateIODelegate = self;
    
    [(CvTViewController*)self.window.rootViewController initialize];
    return YES;
}

-(NSDictionary *)audiobusStateDictionaryForCurrentState
{
    return @{ @"Waveform": @"W",
              @"Attack": @"A",
              @"Decay": @"D" };
}

-(void)loadStateFromAudiobusStateDictionary:(NSDictionary *)dictionary responseMessage:(NSString *__autoreleasing *)outResponseMessage
{
    //_audioEngine.waveform = (ABSenderWaveform)[dictionary[@"Waveform"] integerValue];
    //_audioEngine.attack = [dictionary[@"Attack"] doubleValue];
    //_audioEngine.decay = [dictionary[@"Decay"] doubleValue];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [(CvTViewController*)self.window.rootViewController applicationDidBecomeActive];
    [CCDirector.sharedDirector resume];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [CCDirector.sharedDirector pause];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [CCDirector.sharedDirector stopAnimation];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [CCDirector.sharedDirector startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [CC3OpenGL terminateOpenGL];
}

-(void) applicationSignificantTimeChange: (UIApplication*) application {
    [CCDirector.sharedDirector setNextDeltaTimeZero: YES];
}

@end
