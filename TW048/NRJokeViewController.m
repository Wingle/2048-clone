//
//  NRJokeViewController.m
//  TW048
//
//  Created by WingleWong on 14-4-22.
//  Copyright (c) 2014年 Niklas Riekenbrauck. All rights reserved.
//

#import "NRJokeViewController.h"
#import "DMAdView.h"

@interface NRJokeViewController () <DMAdViewDelegate>
@property(nonatomic, strong) DMAdView *adBanner;

@end

@implementation NRJokeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.textView.text = self.text;
    
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
