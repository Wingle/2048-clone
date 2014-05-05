//
//  NRAppDelegate.h
//  TW048
//
//  Created by Niklas Riekenbrauck on 20.03.14.
//  Copyright (c) 2014 Niklas Riekenbrauck & Georg Zänker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DMSplashAdController.h"
#import "DMRTSplashAdController.h"

#define UMENG_APPKEY @"534b5d6856240b1b0c1a4fd2"
#define WECHAT_APPKEY @"wx844b563facdcfec5"

@interface NRAppDelegate : UIResponder <DMSplashAdControllerDelegate, UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) DMSplashAdController *splashAd;

@end
