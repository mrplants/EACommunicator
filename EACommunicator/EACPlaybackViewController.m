//
//  EACPlaybackViewController.m
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#define kPLAYBACK_USER_DEFAULTS (@"playback_info") //Dictionary of playback information

//keys for user defaults information
#define kIS_PREP_ADVENTURE (@"is_prep_adventure") //BOOL. YES if adventure is a prep adventure.
#define kADVENTURE_NUMBER (@"adventure_number") //int. The adventure number for that adenture unit.
#define kALREADY_PLAYED (@"already_played") //BOOL. YES if the adventure has been played before.
#define kADVENTURE_ID (@"adventure identifier") //NSString *. Two letter identifier for the type of adventure unit

#import "EACPlaybackViewController.h"
#import "EACScannerViewController.h"
#import "Constants.h"
#import "EACInstructionViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface EACPlaybackViewController () <AVAudioPlayerDelegate>

//the audio player for the adventure files and associated properties
@property (nonatomic, strong) AVAudioPlayer * player;
@property (nonatomic, strong) NSTimer * playerTimer;
@property (nonatomic, strong) NSTimer * playbackMeteringTimer;
@property (nonatomic, strong) NSArray * audioCodes;

//current playback information for the track most recently scanned
@property (nonatomic, strong) NSString* adventure_ID;
@property BOOL isPrepAdventure;
@property int adventureNumber;

//background
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *resizeView;

//buttons
@property (weak, nonatomic) IBOutlet UIImageView *scanButtonImageView;
@property (weak, nonatomic) IBOutlet UIImageView *playButtonImageView;

//info. visuals
@property (weak, nonatomic) IBOutlet UIImageView *elapsedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *browserWindowImageView;
@property (weak, nonatomic) IBOutlet UIImageView *trackNumberImageView;

//dynamic visuals
@property (weak, nonatomic) IBOutlet UIImageView *animatedBarsImageView;
@property (weak, nonatomic) IBOutlet UIImageView *animatedConcentricImageView;

//view
@property (nonatomic, strong) NSArray * animatedBarsImageArray;
@property (nonatomic, strong) UIImage * flatBarImage;
@property (nonatomic, strong) NSArray * animatedConcentricImageArray;
@property (nonatomic, strong) NSArray * elapsedVisualImageArray;
@property (nonatomic, strong) NSArray * browserElements;

@end

@implementation EACPlaybackViewController

-(void)viewDidLoad
{
	
	//load the images
	self.flatBarImage = [UIImage imageNamed:@"bars-vis-0.png"];
	
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
	self.animatedBarsImageView.image = self.flatBarImage;
	
	self.animatedConcentricImageView.image = self.animatedConcentricImageArray[0];
	
	[super viewDidLoad];
}

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	[self applyElapsedTime];
	if (IS_IPHONE_5)
	{
		[self iPhone5Setup];
	}
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	//prepare the player so it runs faster
	[self.player prepareToPlay];
	self.player.delegate = self;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if(![defaults boolForKey:@"hasBeenLaunchedBefore"]) {		
		[self performSegueWithIdentifier:@"Instructions Segue"
															sender:self];
			
		[defaults setBool:YES forKey:@"hasBeenLaunchedBefore"];
		[defaults synchronize];
	}
}

-(void)iPhone5Setup
{//The iphone 5 has a longer screen, which cannot be accounted for in the storyboard setup, so we need to give it a different image and lay out the sub-images differently
	self.backgroundImageView.image = [UIImage imageNamed:@"main screen-tall@2x.png"];
	self.resizeView.frame = CGRectMake(0, 44, self.resizeView.frame.size.width, self.resizeView.frame.size.height);
}

-(void) loadAudioCSV
{
	NSString* pathT = [[NSBundle mainBundle] pathForResource:@"EACommunicatorAudioDataModel"
																										ofType:@"csv"];
	NSString* contentT = [NSString stringWithContentsOfFile:pathT
																								 encoding:NSUTF8StringEncoding
																										error:NULL];
	self.audioCodes = [contentT componentsSeparatedByString:@"\r"];
}

-(NSArray *)browserElements
{
	if (!_browserElements) _browserElements = [[NSArray alloc] init];
	return _browserElements;
}

-(void)loadAudioFile
{
	NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource:self.audioFileName
																																											 ofType:@"mp3"]];
	self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
	self.player.meteringEnabled = YES;
	
}

-(void) updateBrowser
{
#warning needs to be finished
	if (!self.player)
		self.browserWindowImageView.hidden = YES;
	else
	{
		[self updateBrowserTime];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		NSDictionary* playbackInfo = [defaults dictionaryForKey:kPLAYBACK_USER_DEFAULTS];
		
	}
}

-(void) updateBrowserTime
{
#warning needs to be finished

}

-(void) setCurrentTrackPlayed
{
#warning needs to be finished
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[defaults synchronize];
}

-(void)applyElapsedTime
{
	//NSTimeInterval timeLeft = self.player.duration - self.player.currentTime;
	
	[self updateBrowser];
	
	int elapsedTimeIncrement = (self.player) ? (self.player.currentTime / self.player.duration * 8) : (0);
	
	self.elapsedImageView.image = self.elapsedVisualImageArray[elapsedTimeIncrement];
}

-(void) applyPlaybackMeteringLevel
{
	[self.player updateMeters];
	//returns how loud the left speaker is. 0 is quiet 1 is loud
	float channelRatio = 1 - [self.player peakPowerForChannel:0] / [self.player averagePowerForChannel:0];
	
	int concentricCircleLevel = [self.animatedConcentricImageArray count] * channelRatio;
	self.animatedConcentricImageView.image = self.animatedConcentricImageArray[concentricCircleLevel];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch* touch in touches)
	{
		if ([self pointIsInsidePlayPauseButton:[touch locationInView:self.resizeView]]) [self playButtonTouchDown];
		if ([self pointIsInsideQRScannerButton:[touch locationInView:self.resizeView]]) [self QRButtonTouchDown];
	}
	[super touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch* touch in touches)
	{
		if (![self pointIsInsidePlayPauseButton:[touch locationInView:self.resizeView]]) [self playButtonTouchUpOutside];
		if (![self pointIsInsideQRScannerButton:[touch locationInView:self.resizeView]]) [self QRButtonTouchUpOutside];
	}
	[super touchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch* touch in touches)
	{
		if ([self pointIsInsidePlayPauseButton:[touch locationInView:self.resizeView]]) [self playButtonTouchUpInside];
		if ([self pointIsInsideQRScannerButton:[touch locationInView:self.resizeView]]) [self QRButtonTouchUpInside];
	}
	[super touchesEnded:touches withEvent:event];
}



-(BOOL)pointIsInsidePlayPauseButton:(CGPoint)point
{
	if ((point.x <= PLAYPAUSE_X + PLAYPAUSE_RADIUS &&
			 point.x >= PLAYPAUSE_X - PLAYPAUSE_RADIUS) &&
			(point.y <= PLAYPAUSE_Y + PLAYPAUSE_RADIUS &&
			 point.y >= PLAYPAUSE_Y - PLAYPAUSE_RADIUS))
	{
		return YES;
	}
	return NO;
}

-(BOOL)pointIsInsideQRScannerButton:(CGPoint)point
{
	if ((point.x <= QR_X + QR_RADIUS &&
			 point.x >= QR_X - QR_RADIUS) &&
			(point.y <= QR_Y + QR_RADIUS &&
			 point.y >= QR_Y - QR_RADIUS))
	{
		return YES;
	}
	return NO;
}

- (void)QRButtonTouchDown
{
	self.scanButtonImageView.image = [UIImage imageNamed:@"scan-button-on.png"];
}

- (void)QRButtonTouchUpOutside
{
	self.scanButtonImageView.image = [UIImage imageNamed:@"scan-button-off.png"];
}

- (void)QRButtonTouchUpInside
{
	[self performSegueWithIdentifier:@"switchToScanner" sender:self];
	self.scanButtonImageView.image = [UIImage imageNamed:@"scan-button-off.png"];
	[self.player pause];
}

- (void)playButtonTouchDown
{
	self.playButtonImageView.image = [UIImage imageNamed:@"play-pause-on.png"];
}

- (void)playButtonTouchUpOutside
{
	self.playButtonImageView.image = [UIImage imageNamed:@"play-pause-off.png"];
}

- (void)playButtonTouchUpInside
{
	if (!self.player.isPlaying && self.player)
	{
		[self startPlaybackAnimations];
		[self.player play];
	}
	else
	{
		[self stopPlaybackAnimations];
		[self.player pause];
	}
}

-(void)stopPlaybackAnimations
{
	[self.playerTimer invalidate];
	[self.playbackMeteringTimer invalidate];
	[self.animatedBarsImageView stopAnimating];
	self.animatedConcentricImageView.image = self.animatedConcentricImageArray[0];
	self.playButtonImageView.image = [UIImage imageNamed:@"play-pause-off.png"];
}

-(void)startPlaybackAnimations
{
	[self.animatedBarsImageView startAnimating];
	// enable a timer to watch how far along the video is
	self.playerTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
																											target:self
																										selector:@selector(applyElapsedTime)
																										userInfo:nil
																										 repeats:YES];
	self.playbackMeteringTimer = [NSTimer scheduledTimerWithTimeInterval:0.001
																																target:self
																															selector:@selector(applyPlaybackMeteringLevel)
																															userInfo:nil
																															 repeats:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];

	if ([[segue identifier] isEqualToString:@"switchToScanner"])
	{
		// Get reference to the destination view controller
		EACScannerViewController * scannerViewController = [segue destinationViewController];
		scannerViewController.delegate = self;
	}
	
}

//AVAudioPlayer delegate methods
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	[self stopPlaybackAnimations];
	[self.player setCurrentTime:0];
	self.animatedConcentricImageView.image = self.animatedConcentricImageArray[0];
	self.elapsedImageView.image = self.elapsedVisualImageArray[[self.elapsedVisualImageArray count]-1];
}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
	[self stopPlaybackAnimations];
}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags
{
	[self startPlaybackAnimations];
}

@end
