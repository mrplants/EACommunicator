//
//  EACPlaybackViewController.m
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#define kPLAYBACK_USER_DEFAULTS (@"playback_info") //Array of Dictionaries of playback information

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
		
	[self loadAudioCSV];
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
	
	if(![defaults boolForKey:@"hasBeenLaunchedBefore"])
	{
		[self loadUserDefaults];
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

-(void)loadTrackData:(NSString*) scannedCode
{
	int indexOfAdventure_ID = [scannedCode rangeOfString:@"_"].location + 1;
	
	self.adventure_ID = [scannedCode substringWithRange:NSMakeRange(indexOfAdventure_ID, 2)];
	NSLog(@"%@", self.adventure_ID);
	
	self.isPrepAdventure = [self.adventure_ID isEqualToString:@"PA"];
	NSLog(@"%d", self.isPrepAdventure);
	
	self.adventureNumber = [[scannedCode substringToIndex:indexOfAdventure_ID + 2] intValue];
	NSLog(@"%d", self.adventureNumber);
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
	if (!self.player)
	{
		self.browserWindowImageView.hidden = YES;
		self.trackNumberImageView.hidden = YES;
	}
	else
	{
		for (UIView * view in self.browserWindowImageView.subviews)
			[view removeFromSuperview];
		self.browserWindowImageView.image = nil;
		self.browserWindowImageView.hidden = NO;
		//show the "now playing:" text
		[self showNowPlayingView];
		
		//update the time on the screen
		[self updateBrowserTime];
		
		//show the tracks-completed circles
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSArray* playbackInfo = [defaults arrayForKey:kPLAYBACK_USER_DEFAULTS];
		NSMutableArray* tracksHaveBeenPlayedInfo = [[NSMutableArray alloc] init];
		for (NSDictionary* track in playbackInfo)
		{
			if(track[kALREADY_PLAYED] && ([(NSString*)track[kADVENTURE_ID] isEqualToString:self.adventure_ID] || [(NSString*)track[kADVENTURE_ID] isEqualToString:@"PA"]))
				[tracksHaveBeenPlayedInfo addObject:[NSNumber numberWithBool:YES]];
			else
				[tracksHaveBeenPlayedInfo addObject:[NSNumber numberWithBool:NO]];
		}
		[self applyPreviouslyPlayedTracks:tracksHaveBeenPlayedInfo];
		
		//show the title
		if ([self.adventure_ID isEqualToString:@"PA"])
			[self showPrepAdventureTitle];
		else
			[self showNonPrepAdventureTitle];
		
		//show the big adventure number
		[self showAdventureNumber];
	}
}

-(void) showAdventureNumber
{
	//set the center after analyzing the browser layout image in photoshop
	CGPoint adventureNumberImageViewCenter = CGPointMake(139, 113);
	CGPoint smallerAdventureNumberImageViewOrigin = CGPointMake(220, 182);
	
	//create the name of the image based on the data that was loaded from the QR code
	NSString * adventureNumberImageName;
	NSString * smallerAdventureNumberImageName;
	if (self.isPrepAdventure) adventureNumberImageName = [NSString stringWithFormat:@"trackP%d.png", self.adventureNumber];
	else adventureNumberImageName = [NSString stringWithFormat:@"track%d.png", self.adventureNumber];
	
	smallerAdventureNumberImageName = [NSString stringWithFormat:@"big%d.png", self.adventureNumber];
	
	//get the image with the correct name
	UIImage * adventureNumberImage = [UIImage imageNamed:adventureNumberImageName];
	UIImage * smallerAdventureNumberImage = [UIImage imageNamed:smallerAdventureNumberImageName];
	
	//init the image inside the imageView
	UIImageView * adventureNumberImageView = [[UIImageView alloc] initWithImage:adventureNumberImage];
	UIImageView * smallerAdventureNumberImageView = [[UIImageView alloc] initWithImage:smallerAdventureNumberImage];

	//set the correct frame for the iamge.
	adventureNumberImageView.frame = CGRectMake(0,
																							0,
																							adventureNumberImage.size.width / 2,
																							adventureNumberImage.size.height / 2);
	smallerAdventureNumberImageView.frame = CGRectMake(smallerAdventureNumberImageViewOrigin.x,
																										 smallerAdventureNumberImageViewOrigin.y,
																										 smallerAdventureNumberImage.size.width / 2,
																										 smallerAdventureNumberImage.size.height / 2);
	
	//put the imageView in the correct position
	adventureNumberImageView.center = adventureNumberImageViewCenter;
	
	//set the correct content mode for the imageView
	adventureNumberImageView.contentMode = UIViewContentModeScaleAspectFit;
	adventureNumberImageView.layer.masksToBounds = YES;
	smallerAdventureNumberImageView.contentMode = UIViewContentModeScaleAspectFit;
	smallerAdventureNumberImageView.layer.masksToBounds = YES;
	
	//add the imageView to the browser imageView
	[self.browserWindowImageView addSubview:adventureNumberImageView];
	[self.browserWindowImageView addSubview:smallerAdventureNumberImageView];
}

-(void) showNowPlayingView
{
	//create the point that will be the origin of the image
	CGPoint nowPlayingImageViewOrigin = CGPointMake(69, 158);
	
	//fetch the image of the Now Playing text
	UIImage * nowPlayingImage = [UIImage imageNamed:@"nowplaying.png"];
	
	//init the image inside the imageView
	UIImageView * nowPlayingImageView = [[UIImageView alloc] initWithImage:nowPlayingImage];
	
	//set the correct frame for the imageView
	//set the correct frame for the iamge.
	nowPlayingImageView.frame = CGRectMake(nowPlayingImageViewOrigin.x,
																				 nowPlayingImageViewOrigin.y,
																				 nowPlayingImage.size.width / 2,
																				 nowPlayingImage.size.height / 2);
	
	//set the correct content mode for the imageView
	nowPlayingImageView.contentMode = UIViewContentModeScaleAspectFit;
	nowPlayingImageView.layer.masksToBounds = YES;
	
	//add the imageView to the browser imageView
	[self.browserWindowImageView addSubview:nowPlayingImageView];
}

-(void) showNonPrepAdventureTitle
{
	//create the point that will be the origin of the image
	CGPoint adventureImageViewOrigin = CGPointMake(119, 182);
	
	//fetch the image of the Now Playing text
	UIImage * adventureImage = [UIImage imageNamed:@"Adventure.png"];
	
	//init the image inside the imageView
	UIImageView * adventureImageView = [[UIImageView alloc] initWithImage:adventureImage];
	
	//set the correct frame for the imageView
	//set the correct frame for the iamge.
	adventureImageView.frame = CGRectMake(adventureImageViewOrigin.x,
																				adventureImageViewOrigin.y,
																				adventureImage.size.width / 2,
																				adventureImage.size.height / 2);
	
	//set the correct content mode for the imageView
	adventureImageView.contentMode = UIViewContentModeScaleAspectFit;
	adventureImageView.layer.masksToBounds = YES;
	
	//add the imageView to the browser imageView
	[self.browserWindowImageView addSubview:adventureImageView];
}

-(void) showPrepAdventureTitle
{
	//create the point that will be the origin of the image
	CGPoint prepAdventureImageViewOrigin = CGPointMake(69, 182);
	
	//fetch the image of the Now Playing text
	UIImage * prepAdventureImage = [UIImage imageNamed:@"prepadventure.png"];
	
	//init the image inside the imageView
	UIImageView * prepAdventureImageView = [[UIImageView alloc] initWithImage:prepAdventureImage];
	
	//set the correct frame for the imageView
	//set the correct frame for the iamge.
	prepAdventureImageView.frame = CGRectMake(prepAdventureImageViewOrigin.x,
																						prepAdventureImageViewOrigin.y,
																						prepAdventureImage.size.width / 2,
																						prepAdventureImage.size.height / 2);
	
	//set the correct content mode for the imageView
	prepAdventureImageView.contentMode = UIViewContentModeScaleAspectFit;
	prepAdventureImageView.layer.masksToBounds = YES;
	
	//add the imageView to the browser imageView
	[self.browserWindowImageView addSubview:prepAdventureImageView];
}

-(void) applyPreviouslyPlayedTracks:(NSArray*)tracksHaveBeenPlayedInfo
{
#warning needs to be finished
	
}

-(void) updateBrowserTime
{
#warning needs to be finished
	NSLog(@"%f / %f", self.player.currentTime, self.player.duration);
	
	float currentTime = self.player.currentTime;
	
	int minutes = currentTime / 60;
	int firstNumber = minutes / 10;
	int secondNumber = minutes - firstNumber * 10;
	
	int seconds = currentTime - minutes * 60;
	int thirdNumber = seconds  / 10;
	int fourthNumber = seconds - thirdNumber * 10;
	
	UIImage * firstNumberImage = [UIImage imageNamed:[NSString stringWithFormat:@"big%d.png", firstNumber]];
	UIImage * secondNumberImage = [UIImage imageNamed:[NSString stringWithFormat:@"big%d.png", secondNumber]];
	UIImage * colonImage = [UIImage imageNamed:@"bigcolon.png"];
	UIImage * thirdNumberImage = [UIImage imageNamed:[NSString stringWithFormat:@"big%d.png", thirdNumber]];
	UIImage * fourthNumberImage = [UIImage imageNamed:[NSString stringWithFormat:@"big%d.png", fourthNumber]];
	UIImage * ofImage = [UIImage imageNamed:@"of.png"];
	
	float totalTime = self.player.duration;
	
	int totalMinutes = totalTime / 60;
	int fifthNumber = totalMinutes / 10;
	int sixthNumber = totalMinutes - fifthNumber * 10;
	
	int totalSeconds = totalTime - totalMinutes * 60;
	int seventhNumber = totalSeconds  / 10;
	int eighthNumber = totalSeconds - seventhNumber * 10;
	
	NSLog(@"%d%d:%d%d of %d%d:%d%d",
				firstNumber,
				secondNumber,
				thirdNumber,
				fourthNumber,
				fifthNumber,
				sixthNumber,
				seventhNumber,
				eighthNumber);
	
	UIImage * fifthNumberImage = [UIImage imageNamed:[NSString stringWithFormat:@"big%d.png", fifthNumber]];
	UIImage * sixthNumberImage = [UIImage imageNamed:[NSString stringWithFormat:@"big%d.png", sixthNumber]];
	UIImage * secondColonImage = [UIImage imageNamed:@"bigcolon.png"];
	UIImage * seventhNumberImage = [UIImage imageNamed:[NSString stringWithFormat:@"big%d.png", seventhNumber]];
	UIImage * eighthNumberImage = [UIImage imageNamed:[NSString stringWithFormat:@"big%d.png", eighthNumber]];

	UIImageView * firstNumberImageView = [[UIImageView alloc] initWithImage:firstNumberImage];
	UIImageView * secondNumberImageView = [[UIImageView alloc] initWithImage:secondNumberImage];
	UIImageView * firstColonImageView = [[UIImageView alloc] initWithImage:colonImage];
	UIImageView * thirdNumberImageView = [[UIImageView alloc] initWithImage:thirdNumberImage];
	UIImageView * fourthNumberImageView = [[UIImageView alloc] initWithImage:fourthNumberImage];
	UIImageView * ofImageView = [[UIImageView alloc] initWithImage:ofImage];
	UIImageView * fifthNumberImageView = [[UIImageView alloc] initWithImage:fifthNumberImage];
	UIImageView * sixthNumberImageView = [[UIImageView alloc] initWithImage:sixthNumberImage];
	UIImageView * secondColonImageView = [[UIImageView alloc] initWithImage:secondColonImage];
	UIImageView * seventhNumberImageView = [[UIImageView alloc] initWithImage:seventhNumberImage];
	UIImageView * eightNumberImageView = [[UIImageView alloc] initWithImage:eighthNumberImage];
	
	NSArray* numberImageViewArray = @[firstNumberImageView,
															 secondNumberImageView,
															 
															 firstColonImageView,
															 
															 thirdNumberImageView,
															 fourthNumberImageView,
															 
															 ofImageView,
															 
															 fifthNumberImageView,
															 sixthNumberImageView,
															 
															 secondColonImageView,
															 
															 seventhNumberImageView,
															 eightNumberImageView];
	
	int imageIndex = 0;
	for (UIImageView * imageView in numberImageViewArray)
	{
		CGPoint origin;
		switch (imageIndex) {
			case 0:
			case 6:
				origin = CGPointMake(71 + imageIndex / 6 * 84, 205);
				break;
			case 1:
			case 7:
				origin = CGPointMake(87 + imageIndex / 6 * 84, 205);
				break;
			case 2:
			case 8:
				origin = CGPointMake(103 + imageIndex / 6 * 84, 207);
				break;
			case 3:
			case 9:
				origin = CGPointMake(111 + imageIndex / 6 * 84, 205);
				break;
			case 4:
			case 10:
				origin = CGPointMake(127 + imageIndex / 6 * 84, 205);
				break;
			case 5:
				origin = CGPointMake(140 + imageIndex / 6 * 84, 206);
				break;
				
			default:
				break;
		}
		
    imageView.frame = CGRectMake(origin.x,
																 origin.y,
																 imageView.image.size.width / 2,
																 imageView.image.size.height / 2);
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.layer.masksToBounds = YES;
		[self.browserWindowImageView addSubview:imageView];
		imageIndex++;
	}
}

-(void) setCurrentTrackPlayed
{
	//apply the NSUserDefaults that will set this track to "isPlayed = YES"
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSArray* playbackInfo = [defaults arrayForKey:kPLAYBACK_USER_DEFAULTS];

	if (!playbackInfo)
	{//No tracks are stored (probably the first time opening the app)
		NSMutableArray * tempPlaybackInfo = [[NSMutableArray alloc] init];
		
		for (NSString* code in self.audioCodes)
		{
			//load the track data
			NSString * adventureID = [code substringWithRange:NSMakeRange(code.length - 3, code.length - 1)];
			NSNumber * adventureNumber = [NSNumber numberWithInt:[[code substringFromIndex:code.length - 1] intValue]];
			NSNumber * alreadyPlayed = [NSNumber numberWithBool:NO];
			NSNumber * isPrepAdventure = [NSNumber numberWithBool:[adventureID isEqualToString:@"PA"]];
			
			//check the track data
			NSLog(@"adventure ID: %@", adventureID);
			NSLog(@"adventure number: %@", adventureNumber);
			NSLog(@"already played: %@", alreadyPlayed);
			NSLog(@"is prep adventure: %@", isPrepAdventure);
			
			//assemble the track data
			NSDictionary* track = @{kADVENTURE_ID: adventureID,
													 kADVENTURE_NUMBER: adventureNumber,
													 kALREADY_PLAYED: alreadyPlayed,
													 kIS_PREP_ADVENTURE: isPrepAdventure};
			
			//store the track data
			[tempPlaybackInfo addObject:track];
		}
		
		playbackInfo = [tempPlaybackInfo copy];
	}
	
	//keep track of where we are because we need to overwrite all the track infor in placybackinfo. Darn immutable things
	NSMutableArray* tempPlaybackInfo = [[NSMutableArray alloc] init];
	
	for (NSDictionary* track in playbackInfo)
	{
    if ([(NSString*)track[kADVENTURE_ID] isEqualToString:self.adventure_ID] &&
				[track[kADVENTURE_NUMBER] intValue] == self.adventureNumber)
		{
			NSMutableDictionary* tempTrack = [track mutableCopy];
			tempTrack[kALREADY_PLAYED] = [NSNumber numberWithBool:YES];
			[tempPlaybackInfo addObject:[tempTrack copy]];
		}
		else [tempPlaybackInfo addObject:[track copy]];
	}
	
	playbackInfo = [tempPlaybackInfo copy];
	
	[defaults setObject:playbackInfo forKey:kPLAYBACK_USER_DEFAULTS];

	[defaults synchronize];
}

-(void)loadUserDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSArray* playbackInfo = [defaults arrayForKey:kPLAYBACK_USER_DEFAULTS];
	
	if (!playbackInfo)
	{//No tracks are stored (probably the first time opening the app)
		NSMutableArray * tempPlaybackInfo = [[NSMutableArray alloc] init];
		
		for (NSString* code in self.audioCodes)
		{
			//load the track data
			NSString * adventureID = [code substringWithRange:NSMakeRange(code.length - 3, 2)];
			NSNumber * adventureNumber = [NSNumber numberWithInt:[[code substringFromIndex:code.length - 1] intValue]];
			NSNumber * alreadyPlayed = [NSNumber numberWithBool:NO];
			NSNumber * isPrepAdventure = [NSNumber numberWithBool:[adventureID isEqualToString:@"PA"]];
			
			//check the track data
			NSLog(@"adventure ID: %@", adventureID);
			NSLog(@"adventure number: %@", adventureNumber);
			NSLog(@"already played: %@", alreadyPlayed);
			NSLog(@"is prep adventure: %@", isPrepAdventure);
			
			//assemble the track data
			NSDictionary* track = @{kADVENTURE_ID: adventureID,
													 kADVENTURE_NUMBER: adventureNumber,
													 kALREADY_PLAYED: alreadyPlayed,
													 kIS_PREP_ADVENTURE: isPrepAdventure};
			
			//store the track data
			[tempPlaybackInfo addObject:track];
		}
		
		playbackInfo = [tempPlaybackInfo copy];
	}
	[defaults setObject:playbackInfo forKey:kPLAYBACK_USER_DEFAULTS];
	
	[defaults synchronize];
}

-(void) showDefaultTrackInfo
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSArray* playbackInfo = [defaults arrayForKey:kPLAYBACK_USER_DEFAULTS];

	for (NSDictionary*track in playbackInfo)
	{
		//check the track data
		NSLog(@"adventure ID: %@", track[kADVENTURE_ID]);
		NSLog(@"adventure number: %@", track[kADVENTURE_NUMBER]);
		NSLog(@"already played: %@", track[kALREADY_PLAYED]);
		NSLog(@"is prep adventure: %@", track[kIS_PREP_ADVENTURE]);

	}
}

-(void)applyElapsedTime
{
	//NSTimeInterval timeLeft = self.player.duration - self.player.currentTime;
	
	if (self.player.isPlaying) self.playButtonImageView.image = [UIImage imageNamed:@"play-pause-on.png"];

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
//	self.scanButtonImageView.image = [UIImage imageNamed:@"scan-button-off.png"];
//	[self.player pause];
}

- (void)playButtonTouchDown
{
	self.playButtonImageView.image = [UIImage imageNamed:@"play-pause-on.png"];
}

- (void)playButtonTouchUpOutside
{
	if(!self.player.isPlaying) self.playButtonImageView.image = [UIImage imageNamed:@"play-pause-off.png"];
}

- (void)playButtonTouchUpInside
{
	[self applyElapsedTime];
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
