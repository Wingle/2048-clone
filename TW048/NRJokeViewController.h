//
//  NRJokeViewController.h
//  TW048
//
//  Created by WingleWong on 14-4-22.
//  Copyright (c) 2014年 Niklas Riekenbrauck. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NRJokeViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, copy) NSString *text;


- (IBAction)closeView:(id)sender;

@end
