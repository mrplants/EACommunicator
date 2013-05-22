//
//  EACPlaybackViewController.m
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#import "EACPlaybackViewController.h"

@interface EACPlaybackViewController ()
//background
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

//buttons
@property (weak, nonatomic) IBOutlet UIImageView *scanButtonImageView;
@property (weak, nonatomic) IBOutlet UIImageView *playButtonImageView;

//info. visuals
@property (weak, nonatomic) IBOutlet UIImageView *elapsedImageView;

//dynamic visuals
@property (weak, nonatomic) IBOutlet UIImageView *animatedBarsImageView;
@property (weak, nonatomic) IBOutlet UIImageView *animatedConcentricImageView;

//models
//animated
@property (nonatomic, strong) NSArray * animatedBarsImageArray;
@property (nonatomic, strong) NSArray * animatedConcentricImageArray;
//nonanimated
@property (nonatomic, strong) NSArray * elapsedVisualImageArray;

//physical objects
@property (weak, nonatomic) IBOutlet UISlider *elapsedTimeSlider;


@end

@implementation EACPlaybackViewController

-(void)viewDidLoad
{
	
	//load the images
	self.animatedBarsImageArray =
	@[[UIImage imageNamed:@"bars-vis-1.png"],
	 [UIImage imageNamed:@"bars-vis-2.png"],
	 [UIImage imageNamed:@"bars-vis-3.png"],
	 [UIImage imageNamed:@"bars-vis-4.png"],
	 [UIImage imageNamed:@"bars-vis-5.png"],
	 [UIImage imageNamed:@"bars-vis-6.png"]
	 ];
	
	self.animatedConcentricImageArray =
	@[[UIImage imageNamed:@"concentricvis0.png"],
	 [UIImage imageNamed:@"concentricvis1.png"],
	 [UIImage imageNamed:@"concentricvis2.png"],
	 [UIImage imageNamed:@"concentricvis3.png"],
	 [UIImage imageNamed:@"concentricvis4.png"],
	 [UIImage imageNamed:@"concentricvis5.png"],
	 [UIImage imageNamed:@"concentricvis6.png"],
	 [UIImage imageNamed:@"concentricvis5.png"],
	 [UIImage imageNamed:@"concentricvis4.png"],
	 [UIImage imageNamed:@"concentricvis3.png"],
	 [UIImage imageNamed:@"concentricvis2.png"],
	 [UIImage imageNamed:@"concentricvis1.png"],
	 [UIImage imageNamed:@"concentricvis0.png"]
	 ];
	
	self.elapsedVisualImageArray =
	@[[UIImage imageNamed:@"elapsed0.png"],
	 [UIImage imageNamed:@"elapsed1.png"],
	 [UIImage imageNamed:@"elapsed2.png"],
	 [UIImage imageNamed:@"elapsed3.png"],
	 [UIImage imageNamed:@"elapsed4.png"],
	 [UIImage imageNamed:@"elapsed5.png"],
	 [UIImage imageNamed:@"elapsed6.png"],
	 [UIImage imageNamed:@"elapsed7.png"],
	 [UIImage imageNamed:@"elapsed8.png"],
	 ];
	
	//setup the animations
	self.animatedBarsImageView.animationImages = self.animatedBarsImageArray;
	self.animatedBarsImageView.animationDuration = 0.5;
	self.animatedConcentricImageView.animationImages = self.animatedConcentricImageArray;
	self.animatedConcentricImageView.animationDuration = 0.5;
	
	[super viewDidLoad];
}

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	[self applyElapsedTime];
	[self.animatedBarsImageView startAnimating];
	[self.animatedConcentricImageView startAnimating];
}

-(void)applyElapsedTime
{
	int elapsedTimeIncrement = self.elapsedTimeSlider.value * 8;
	self.elapsedImageView.image = self.elapsedVisualImageArray[elapsedTimeIncrement];
}
- (IBAction)elapsedTimeSliderValueChanged:(id)sender
{
	[self applyElapsedTime];
}

- (IBAction)QRButtonTouchDown
{
	self.scanButtonImageView.image = [UIImage imageNamed:@"scan-button-on.png"];
}

- (IBAction)QRButtonTouchUpOutside
{
	self.scanButtonImageView.image = [UIImage imageNamed:@"scan-button-off.png"];
}

- (IBAction)QRButtonTouchUpInside
{
	self.scanButtonImageView.image = [UIImage imageNamed:@"scan-button-off.png"];
}

- (IBAction)playButtonTouchDown
{
	self.playButtonImageView.image = [UIImage imageNamed:@"play-pause-on.png"];
}

- (IBAction)playButtonTouchUpOutside
{
	self.playButtonImageView.image = [UIImage imageNamed:@"play-pause-off.png"];
}

- (IBAction)playButtonTouchUpInside
{
	self.playButtonImageView.image = [UIImage imageNamed:@"play-pause-off.png"];
}


@end
