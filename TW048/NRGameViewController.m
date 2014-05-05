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
#import "DMAdView.h"
#import <UMengAnalytics/MobClick.h>
#import <ASIHTTPRequest/ASIHTTPRequest.h>
#import "NSObject+NSJSONSerialization.h"
#import "NRJokeViewController.h"

#define JokeTitle   @"段子："


@interface NRGameViewController () <DMAdViewDelegate, ASIHTTPRequestDelegate>

@property(nonatomic, strong) DMAdView *adBanner;
@property(nonatomic, strong) NSMutableArray *jokesArray;

@end

@implementation NRGameViewController {
    NRGameScene *scene;
    NSInteger jokeCount;
}
@synthesize scoreLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    self.jokesArray = [NSMutableArray array];
    jokeCount = 0;
    
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
    // 创建广告视图，此处使用的是测试ID，请登陆多盟官网（www.domob.cn）获取新的ID
    self.adBanner = [[DMAdView alloc] initWithPublisherId:kDomobPublisherID
                                              placementId:@"16TLuUqoAph11NUkHf-ri1Wk"
                                                     size:DOMOB_AD_SIZE_320x50
                                              autorefresh:YES];
    // 设置广告视图的位置
    self.adBanner.frame = CGRectMake(0, bounds.size.height - 50.f,
                                     DOMOB_AD_SIZE_320x50.width,
                                     DOMOB_AD_SIZE_320x50.height);
    
    self.adBanner.delegate = self; // 设置 Delegate
    self.adBanner.rootViewController = self; // 设置 RootViewController
    [self.view addSubview:self.adBanner];
    [self.adBanner loadAd]; // 开始加载广告
    
    // load joke.
    NSString *strURL = @"http://ic.snssdk.com/2/essay/ugc/hesitate/essay/v10/?tag=joke&iid=238687279&count=50&app_name=joke_essay";
    LOG(@"request url = %@",strURL);
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:strURL]];
    [request setUserAgentString:@"Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko"];
    [request setDelegate:self];
    [request setTimeOutSeconds:5];
    [request startAsynchronous];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"游戏页面"];
    
    if (jokeCount == 0) {
        return;
    }
    NSInteger randon = arc4random() % jokeCount;
    self.jokeLabel.text = [NSString stringWithFormat:@"%@%@", JokeTitle, self.jokesArray[randon]];
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
    
    NRGameOverSheetViewController *vc = (NRGameOverSheetViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"sheet"];
    vc.preViewController = self;
    
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
        viewController.scoreTextLabel.text = [NSString stringWithFormat:@"本次得分: %i\n最高记录: %@",(int)score, self.bestLabel.text];
    };
    
    __weak typeof(self) weakSelf = self;
    [self mz_presentFormSheetController:formSheet animated:YES completionHandler:^(MZFormSheetController *formSheetController) {
        NSInteger randon = arc4random() % jokeCount;
        weakSelf.jokeLabel.text = [NSString stringWithFormat:@"%@%@", JokeTitle, weakSelf.jokesArray[randon]];;
        
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

- (IBAction)displayJokeView:(id)sender {
    NRJokeViewController *jokeViewContoller = [[NRJokeViewController alloc] initWithNibName:@"NRJokeViewController" bundle:nil];
    jokeViewContoller.text = [self.jokeLabel.text substringFromIndex:3];
    LOG(@"%@",self.jokeLabel.text);
    [self presentViewController:jokeViewContoller animated:YES completion:nil];
    [MobClick event:@"jokeViewClicked"];
}

#pragma mark - ASIHTTPDelegate
- (void)requestFinished:(ASIHTTPRequest *)request {
    if (request.responseStatusCode != 200) {
        LOG(@"responseStatusCode = %d",request.responseStatusCode);
        return;
    }
    
    NSDictionary *responseDic = [request.responseString JSONValue];
    if (![[responseDic objectForKey:@"message"] isEqualToString:@"success"]) {
        return;
    }
    
    NSArray *data = [responseDic objectForKey:@"data"];
    for (NSDictionary *joke in data) {
        NSString *jokeText = [joke objectForKey:@"content"];
        if (jokeText == nil || [jokeText isEqualToString:@""]) {
            continue;
        }
        [self.jokesArray addObject:jokeText];
    }
    jokeCount = [self.jokesArray count];
    if (jokeCount > 0) {
        self.jokeLabel.text = [NSString stringWithFormat:@"%@%@", JokeTitle, self.jokesArray[0]];
    }
    
}


@end
