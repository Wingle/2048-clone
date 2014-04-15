//
//  NRViewController.m
//  TW048
//
//  Created by Niklas Riekenbrauck on 20.03.14.
//  Copyright (c) 2014 Niklas Riekenbrauck & Georg Zänker. All rights reserved.
//

#import "NRGameViewController.h"
#import "NRGameScene.h"
#import <QuartzCore/QuartzCore.h>
#import "SoundPlayer.h"
#import "NRGameOverSheetViewController.h"
#import <Google-AdMob-Ads-SDK/GADBannerView.h>
#import <Google-AdMob-Ads-SDK/GADRequest.h>
#import <UMengAnalytics/MobClick.h>

@interface NRGameViewController () <GADBannerViewDelegate>

@property(nonatomic, strong) GADBannerView *adBanner;

@end

@implementation NRGameViewController {
    NRGameScene *scene;
}
@synthesize scoreLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    //Setup Highscore Label
    NSInteger highscore = [[NSUserDefaults standardUserDefaults] integerForKey:@"Highscore"];
    self.bestLabel.text = [NSString stringWithFormat:@"%i",(int)highscore];
    
    // Configure form sheet
    [[MZFormSheetBackgroundWindow appearance] setBackgroundBlurEffect:YES];
    [[MZFormSheetBackgroundWindow appearance] setBlurRadius:5.0];
    [[MZFormSheetBackgroundWindow appearance] setBackgroundColor:[UIColor clearColor]];
    
    // SoundPlayer
    

    //Make round corners
    self.scoreBackgroundView.layer.cornerRadius = 4.0;
    self.scoreBackgroundView.layer.masksToBounds = YES;
    self.bestBackgroundView.layer.cornerRadius = 4.0;
    self.bestBackgroundView.layer.masksToBounds = YES;
    self.gamepadView.layer.cornerRadius = 8.0;
    self.gamepadView.layer.masksToBounds = YES;
    
    [self prepareGame];
    
    
    // admob
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGPoint origin = CGPointMake(0.0,
                                 bounds.size.height - 50.f);
    // Use predefined GADAdSize constants to define the GADBannerView.
    self.adBanner = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner origin:origin];
    
    // Note: Edit SampleConstants.h to provide a definition for kSampleAdUnitID before compiling.
    self.adBanner.adUnitID = kSampleAdUnitID;
    self.adBanner.delegate = self;
    self.adBanner.rootViewController = self;
    [self.view addSubview:self.adBanner];
    [self.adBanner loadRequest:[self request]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"游戏页面"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"游戏页面"];
}

-(void)viewDidDisappear:(BOOL)animated {
    [[SoundPlayer defualtPlayer] stopBackgroundSound];
}

- (GADRequest *)request {
    GADRequest *request = [GADRequest request];
    
    // Make the request for a test ad. Put in an identifier for the simulator as well as any devices
    // you want to receive test ads.
    request.testDevices = @[
                            // TODO: Add your device/simulator test identifiers here. Your device identifier is printed to
                            // the console when the app is launched.
                            GAD_SIMULATOR_ID,
                            @"672e13ff37a8c1e99a51375df44e9f4c9f610d7f",
                            @"5ea83bfbbab6d8e72c936fa4888757666a28a4c0"
                            ];
    return request;
}

-(void)prepareGame {

    self.scoreLabel.text = @"0";

    // Configure the view.
    SKView * skView = (SKView *)self.gamepadView;
//    skView.showsFPS = YES;
//    skView.showsNodeCount = YES;
//    skView.showsPhysics = YES;
//    skView.showsDrawCount = YES;
    
    //make property weak to use it in blocks
    __weak typeof(self) weakSelf = self;

    // Create and configure the scene.
    scene = [NRGameScene sceneWithSize:skView.bounds.size];
    
    scene.scaleMode = SKSceneScaleModeAspectFill;
    [scene.mapTiles setNewScoreBlock:^(NSInteger newScore, NSInteger offset) {
        //Actions for new score
        [weakSelf updateScore:newScore withScoreOffset:offset];
    }];
    [scene.mapTiles setGameWonBlock: ^(NSInteger score, NSInteger gameWonType){
        //[soundPlayer stopBackgroundSound];
        [weakSelf showPopUpWithScore:score andGameOverType:kGameWon];
    }];
    [scene.mapTiles setGameLostBlock:^(NSInteger score){
        //[soundPlayer stopBackgroundSound];
        [weakSelf showPopUpWithScore:score andGameOverType:kGameLost];
    }];

    // Present the scene.
    [skView presentScene:scene];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(void)showPopUpWithScore:(NSInteger)score andGameOverType:(GameOverType)gameOverType {
    
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"sheet"];
    
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:vc];
    
    formSheet.shouldCenterVertically = YES;
    //formSheet.shouldDismissOnBackgroundViewTap = YES;
    
    formSheet.willPresentCompletionHandler = ^(UIViewController *presentedFSViewController) {
        NRGameOverSheetViewController *viewController = (NRGameOverSheetViewController *)presentedFSViewController;
        viewController.score = score;
        if (gameOverType == kGameWon) {
            viewController.statusTextLabel.text = @"哇，万人景仰!";
            [scene runAction:[SKAction playSoundFileNamed:[[SoundPlayer defualtPlayer] soundNameOfType:kSuccess]
                                        waitForCompletion:NO]];
        } else {
            [scene runAction:[SKAction playSoundFileNamed:[[SoundPlayer defualtPlayer] soundNameOfType:kFailure]
                                        waitForCompletion:NO]];
            viewController.statusTextLabel.text = @"游戏结束!";
        }
        viewController.scoreTextLabel.text = [NSString stringWithFormat:@"我本次得分: %i\n最高记录: %@",(int)score, self.bestLabel.text];
    };
    
    __weak typeof(self) weakSelf = self;
    [self mz_presentFormSheetController:formSheet animated:YES completionHandler:^(MZFormSheetController *formSheetController) {
        [weakSelf prepareGame];
    }];
    
}

-(void)updateScore:(NSInteger)score withScoreOffset:(NSInteger)offset {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (score > [defaults integerForKey:@"Highscore"]) {
        [defaults setInteger:score forKey:@"Highscore"];
        self.bestLabel.text = [NSString stringWithFormat:@"%i",(int)score];
    }
    self.scoreLabel.text = [NSString stringWithFormat:@"%i",(int)score];
}

- (IBAction)madeSwipeGesture:(UISwipeGestureRecognizer *)sender {
    
    //[self showPopUpWithScore:100 andSuccess:YES];
    
    for (UISwipeGestureRecognizer *recognizer in self.swipeGestureRecognizerCollection)
        if (sender.direction == recognizer.direction)
            [scene.mapTiles performedSwipeGestureInDirection:sender.direction];
}

@end
