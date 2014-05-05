//
//  NRAppDelegate.m
//  TW048
//
//  Created by Niklas Riekenbrauck on 20.03.14.
//  Copyright (c) 2014 Niklas Riekenbrauck & Georg Zänker. All rights reserved.
//

#import "NRAppDelegate.h"
#import "UMSocialWechatHandler.h"
#import <UMengAnalytics/MobClick.h>
#import <UMSocial.h>
#import "SoundPlayer.h"

@implementation NRAppDelegate

- (void)umengTrack {
    [MobClick setCrashReportEnabled:YES]; // 如果不需要捕捉异常，注释掉此行
#if DEBUG
    [MobClick setLogEnabled:YES];  // 打开友盟sdk调试，注意Release发布时需要注释掉此行,减少io消耗
#endif
    
    [MobClick setAppVersion:XcodeAppVersion]; //参数为NSString * 类型,自定义app版本信息，如果不设置，默认从CFBundleVersion里取
    
    [MobClick startWithAppkey:UMENG_APPKEY reportPolicy:(ReportPolicy) REALTIME channelId:nil];
    [UMSocialData setAppKey:UMENG_APPKEY];
    [UMSocialWechatHandler setWXAppId:WECHAT_APPKEY url:nil];
    
    //   reportPolicy为枚举类型,可以为 REALTIME, BATCH,SENDDAILY,SENDWIFIONLY几种
    //   channelId 为NSString * 类型，channelId 为nil或@""时,默认会被被当作@"App Store"渠道
    
    [MobClick updateOnlineConfig];  //在线参数配置
    [MobClick checkUpdate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onlineConfigCallBack:) name:UMOnlineConfigDidFinishedNotification object:nil];
    
}

- (void)onlineConfigCallBack:(NSNotification *)note {
    LOG(@"online config has fininshed and note = %@", note.userInfo);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self umengTrack];
    //Create a Highscore Integer in the Defaults in case is doesnt yet exist
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:@"Highscore"] == 0) {
        NSInteger highscore = 0;
        [defaults setInteger:highscore forKey:@"Highscore"];
    }
    [defaults synchronize];
    
    // 设置适合的背景图片
    // Set background image
    NSString *defaultImgName = @"LaunchImage";
    CGFloat offset = 0.0f;
    CGSize adSize;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        adSize = DOMOB_AD_SIZE_768x576;
        offset = 374.0f;
    } else {
        adSize = DOMOB_AD_SIZE_320x400;
    }
    
    BOOL isCacheSplash = NO;
    // 选择测试缓存开屏还是实时开屏，NO为实时开屏。
    // Choose NO or YES for RealTimeSplashView or SplashView
    // 初始化开屏广告控制器，此处使用的是测试ID，请登陆多盟官网（www.domob.cn）获取新的ID
    // Get your ID from Domob website
    NSString* splashPlacementID = @"16TLuUqoAph11NUkHO3jMbLs";
    UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage imageNamed:defaultImgName]];
    if (isCacheSplash) {
        _splashAd = [[DMSplashAdController alloc] initWithPublisherId:kDomobPublisherID
                                                          placementId:splashPlacementID
                                                                 size:adSize
                                                               offset:offset
                                                               window:self.window
                                                           background:bgColor
                                                            animation:YES];
        self.splashAd.delegate = self;
        if (_splashAd.isReady)
        {
            [_splashAd present];
        }
    } else {
        DMRTSplashAdController* rtsplashAd = nil;
        rtsplashAd = [[DMRTSplashAdController alloc] initWithPublisherId:kDomobPublisherID
                                                             placementId:splashPlacementID
                                                                    size:adSize
                                                                  offset:offset
                                                                  window:self.window
                                                              background:bgColor
                                                               animation:YES];
        
        
        rtsplashAd.delegate = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [rtsplashAd present];
        });
        
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[SoundPlayer defualtPlayer] stopBackgroundSound];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[SoundPlayer defualtPlayer] playBackgroundSound];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [UMSocialSnsService  applicationDidBecomeActive];
    [[SoundPlayer defualtPlayer] playBackgroundSound];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[SoundPlayer defualtPlayer] stopBackgroundSound];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return  [UMSocialSnsService handleOpenURL:url wxApiDelegate:nil];
}
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return  [UMSocialSnsService handleOpenURL:url wxApiDelegate:nil];
}

#pragma mark -
#pragma makr Domob Splash Ad Delegate
//成功加开屏广告后调用
//This method will be used after load splash advertisement successfully
- (void)dmSplashAdSuccessToLoadAd:(DMSplashAdController *)dmSplashAd
{
    NSLog(@"[Domob Splash] success to load ad.");
}

// 当开屏广告加载失败后，回调该方法
// This method will be used after load splash advertisement faild
- (void)dmSplashAdFailToLoadAd:(DMSplashAdController *)dmSplashAd withError:(NSError *)err
{
    NSLog(@"[Domob Splash] fail to load ad.");
}

// 当插屏广告要被呈现出来前，回调该方法
// This method will be used before the splashView will show
- (void)dmSplashAdWillPresentScreen:(DMSplashAdController *)dmSplashAd
{
    NSLog(@"[Domob Splash] will appear on screen.");
}

// 当插屏广告被关闭后，回调该方法
// This method will be used after the splashView dismiss
- (void)dmSplashAdDidDismissScreen:(DMSplashAdController *)dmSplashAd
{
    NSLog(@"[Domob Splash] did disappear on screen.");
}


@end
