//
//  EACPlaybackViewController.m
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#define kPLAYBACK_USER_DEFAULTS (@"playback_info") //Array of Dictionaries of playback information
#define kURL_TO_AUDIO_FILE_MAP_USER_DEFAULTS (@"url to audio filename map") //A dictionary mapping the scanned URL to an audio filename.

//keys for user defaults information
#define kIS_PREP_ADVENTURE (@"is_prep_adventure") //BOOL. YES if adventure is a prep adventure.
#define kADVENTURE_NUMBER (@"adventure_number") //int. The adventure number for that adenture unit.
#define kALREADY_PLAYED (@"already_played") //BOOL. YES if the adventure has been played before.
#define kADVENTURE_ID (@"adventure identifier") //NSString *. Two letter identifier for the type of adventure unit
#define kPREP_ADVENTURE_ID (@"prep adventure identifier") //NSString *. identifier to tell which adventure a prep is from
#define kIS_SUB_ADVENTURE (@"is a sub adventure") //BOOL. YES if the adventure ID has an "a" like "BB1a" or "RR6a"
#define kCODE (@"code from the csv file.") //NSString *. code fromt the csv file
#define kURL (@"the url for the track") //NSString *. the url stored in the QR code for the track

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
@property (nonatomic, strong) NSArray * preScannedAudioMappings;
@property (nonatomic, strong) NSDictionary * audioMap;
@property (nonatomic, strong) NSArray * playbackInfo;

//current playback information for the track most recently scanned
@property (nonatomic, strong) NSString* adventure_ID;
@property (nonatomic, strong) NSString* prepAdventureID;
@property BOOL isPrepAdventure;
@property int adventureNumber;
@property BOOL isSubAdventure;
@property (nonatomic, strong) NSArray * CurrentUnitTracks;

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
@property (nonatomic, strong) NSArray * dotArray;
@property (nonatomic, strong) NSArray * numberForDotArray;

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
	
	[self loadUserDefaults];
	
	if(![defaults boolForKey:@"hasBeenLaunchedBefore"])
	{
		[self performSegueWithIdentifier:@"Instructions Segue"
															sender:self];
		
		[defaults setBool:YES forKey:@"hasBeenLaunchedBefore"];
		[defaults synchronize];
	}
	
	self.scanButtonImageView.image = [UIImage imageNamed:@"scan-button-off.png"];
	
	if(self.player && ![self.player isPlaying])
	{
		[self playButtonTouchDown];
		[self playButtonTouchUpInside];
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
	self.preScannedAudioMappings = [contentT componentsSeparatedByString:@"\r"];
	
	NSMutableDictionary * tempAudioMap = [[NSMutableDictionary alloc] init];
	for (NSString* audioMap in self.preScannedAudioMappings)
	{
    NSString* filename = [audioMap substringToIndex:[audioMap rangeOfString:@","].location];
		//		NSLog(@"file name: %@", filename);
		
		NSString* url = [audioMap substringFromIndex:[audioMap rangeOfString:@","].location+1];
		//		NSLog(@"url: %@", url);
		
		[tempAudioMap setObject:filename forKey:url];
	}
	
	self.audioMap = [tempAudioMap copy];
}

-(NSArray *)browserElements
{
	if (!_browserElements) _browserElements = [[NSArray alloc] init];
	return _browserElements;
}

-(void)loadTrackData:(NSString*) scannedCode
{
	NSString * audioFilename = self.audioMap[scannedCode];
	
	NSString * code = [audioFilename substringFromIndex:8];
	
	int indexOfAdventure_ID = [code rangeOfString:@"_"].location + 1;
	
	if ([code rangeOfString:@"a"].location != NSNotFound)
	{
		self.isSubAdventure = YES;
	} else
	{
		self.isSubAdventure = NO;
	}
	
	self.adventure_ID = [code substringWithRange:NSMakeRange(indexOfAdventure_ID, 2)];
	//	NSLog(@"%@", self.adventure_ID);
	
	self.isPrepAdventure = [self.adventure_ID isEqualToString:@"PA"];
	//	NSLog(@"%d", self.isPrepAdventure);
	if (self.isPrepAdventure)
	{
		for (NSDictionary* trackInfo in self.playbackInfo)
		{
			NSString * prepAdventureID = [scannedCode substringWithRange:NSMakeRange([scannedCode rangeOfString:self.adventure_ID].location - 3, 2)];
			//			NSLog(@"loading track, prep adventure ID: %@", prepAdventureID);
			self.prepAdventureID = prepAdventureID;
		}
	} else {
		self.prepAdventureID = nil;
	}
	
	self.adventureNumber = [[code substringFromIndex:indexOfAdventure_ID + 2] intValue];
	//	NSLog(@"%d", self.adventureNumber);
}

-(void)loadAudioFile
{
	[self stopPlaybackAnimations];
	[self.player stop];
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
		if (!self.isPrepAdventure)
		{
			for (NSDictionary* track in playbackInfo)
			{
				if([(NSString*)track[kADVENTURE_ID] isEqualToString:self.adventure_ID] ||
					 [(NSString*)track[kPREP_ADVENTURE_ID] isEqualToString:self.adventure_ID])
				{
					[tracksHaveBeenPlayedInfo addObject:track];
				}
			}
			[self applyPreviouslyPlayedTracks:tracksHaveBeenPlayedInfo];
		}
		else
		{
			for (NSDictionary* track in playbackInfo)
			{				
				if([(NSString*)track[kADVENTURE_ID] isEqualToString:self.prepAdventureID] ||
					 [(NSString*)track[kPREP_ADVENTURE_ID] isEqualToString:self.prepAdventureID])
				{
					[tracksHaveBeenPlayedInfo addObject:track];
				}
			}
			[self applyPreviouslyPlayedTracks:tracksHaveBeenPlayedInfo];
		}
		
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
	else if (self.isSubAdventure) adventureNumberImageName = [NSString stringWithFormat:@"track%dA.png", self.adventureNumber];
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
	if (self.isSubAdventure)
	{
		UIImageView * smallerAdventureImageViewA = [[UIImageView alloc] initWithFrame:smallerAdventureNumberImageView.frame];
		smallerAdventureImageViewA.image = [UIImage imageNamed:@"bigA.png"];
		smallerAdventureImageViewA.frame = CGRectMake(smallerAdventureImageViewA.frame.origin.x,
																									smallerAdventureImageViewA.frame.origin.y,
																									smallerAdventureImageViewA.image.size.width / 3,
																									smallerAdventureImageViewA.frame.size.height);
		
		smallerAdventureImageViewA.contentMode = UIViewContentModeScaleAspectFit;
		smallerAdventureImageViewA.clipsToBounds = YES;
		[self.browserWindowImageView addSubview:smallerAdventureImageViewA];
		smallerAdventureImageViewA.center = CGPointMake(smallerAdventureImageViewA.center.x + smallerAdventureNumberImageView.frame.size.width, smallerAdventureImageViewA.center.y - 2);
		smallerAdventureNumberImageView.center = CGPointMake(smallerAdventureNumberImageView.center.x, smallerAdventureNumberImageView.center.y);
		
//	adventureNumberImageView.image = [NSString stringWithFormat:@"track%dA.png", self.adventureNumber];
	}
	
	//put the imageView in the correct position
	adventureNumberImageView.center = adventureNumberImageViewCenter;
	
	//set the correct content mode for the imageView
	adventureNumberImageView.contentMode = UIViewContentModeScaleAspectFit;
	adventureNumberImageView.clipsToBounds = YES;
	smallerAdventureNumberImageView.contentMode = UIViewContentModeScaleAspectFit;
	smallerAdventureNumberImageView.clipsToBounds = YES;
	
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
	nowPlayingImageView.clipsToBounds = YES;
	
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
	adventureImageView.clipsToBounds = YES;
	
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
	prepAdventureImageView.clipsToBounds = YES;
	
	//add the imageView to the browser imageView
	[self.browserWindowImageView addSubview:prepAdventureImageView];
}

NSInteger sortTracks(id track1, id track2, void *context)
{
	int v1 = [((NSDictionary*)track1)[kADVENTURE_NUMBER] intValue];
	int v2 = [((NSDictionary*)track2)[kADVENTURE_NUMBER] intValue];
	if ([((NSDictionary*)track1)[kIS_PREP_ADVENTURE] boolValue] ||
			[((NSDictionary*)track2)[kIS_PREP_ADVENTURE] boolValue])
	{
		if([((NSDictionary*)track1)[kIS_PREP_ADVENTURE] boolValue] &&
			 [((NSDictionary*)track2)[kIS_PREP_ADVENTURE] boolValue])
		{
			if (v1 < v2)
				return NSOrderedAscending;
			else if (v1 > v2)
				return NSOrderedDescending;
			else
				return NSOrderedSame;
		}
		else
			if ([((NSDictionary*)track1)[kIS_PREP_ADVENTURE] boolValue])
			{
				return NSOrderedAscending;
			}
			else
				if ([((NSDictionary*)track2)[kIS_PREP_ADVENTURE] boolValue])
				{
					return NSOrderedDescending;
				}
	}
	else
		if (v1 < v2)
			return NSOrderedAscending;
		else if (v1 > v2)
			return NSOrderedDescending;
		else if (v1 == v2)
		{
			if ([((NSDictionary*)track1)[kIS_SUB_ADVENTURE] boolValue])
				return NSOrderedDescending;
			else if ([((NSDictionary*)track1)[kIS_SUB_ADVENTURE] boolValue])
				return NSOrderedAscending;
		}
	return NSOrderedSame;
}

-(void) applyPreviouslyPlayedTracks:(NSArray*)tracksHaveBeenPlayedInfo
{
		
	NSArray *sortedArray;
	sortedArray = [tracksHaveBeenPlayedInfo sortedArrayUsingFunction:sortTracks context:NULL];

	tracksHaveBeenPlayedInfo = sortedArray;
	
	self.CurrentUnitTracks = sortedArray;
	
	NSMutableArray * trackPlayedValues = [[NSMutableArray alloc] init];
	
	for (NSDictionary* track in tracksHaveBeenPlayedInfo)
	{
    [trackPlayedValues addObject: track[kALREADY_PLAYED]];
	}
	
	NSMutableArray * dotArray = [[NSMutableArray alloc] init];
	NSMutableArray * numberForDotArray = [[NSMutableArray alloc] init];
	int numberOfSubTracks = 0;
	int trackIndex = 0;
	for (NSNumber * wasPlayed in trackPlayedValues)
	{
		//allocate and initialize the two imageViews
		UIImageView* dot = [[UIImageView alloc] init];
		UIImageView* trackNumber = [[UIImageView alloc] init];
		if (trackIndex >1)
		{
			trackNumber = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"small%d.png", trackIndex+1 - 2 - numberOfSubTracks]]];
		}
		else
		{
			trackNumber = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"smallP%d.png", trackIndex+1]]];
		}
		
		//give the correct image to the dot imageView
    if ([wasPlayed boolValue]) dot.image = [UIImage imageNamed:@"dotfull.png"];
		else dot.image = [UIImage imageNamed:@"dotempty.png"];
		
		//move them and scale them to the correct values;
		dot.frame = CGRectMake(72 + 173.0 * trackIndex / [tracksHaveBeenPlayedInfo count],
													 223,
													 dot.image.size.width / 2,
													 dot.image.size.height / 2);
		trackNumber.frame = CGRectMake(0,
																	 0,
																	 trackNumber.image.size.width / 2,
																	 trackNumber.image.size.height / 2);
		trackNumber.center = CGPointMake(dot.frame.origin.x + 5, dot.frame.origin.y + 17);
		
		if ([tracksHaveBeenPlayedInfo[trackIndex][kIS_SUB_ADVENTURE] boolValue])
		{
			trackNumber.center = CGPointMake(trackNumber.center.x - 5, trackNumber.center.y);
			
			trackNumber.image = [UIImage imageNamed:[NSString stringWithFormat:@"small%d.png", trackIndex+1 - 3 - numberOfSubTracks]];
			numberOfSubTracks++;

			UIImageView * smallerSubAdventureImageViewA = [[UIImageView alloc] initWithFrame:trackNumber.frame];
			smallerSubAdventureImageViewA.image = [UIImage imageNamed:@"bigA.png"];
			smallerSubAdventureImageViewA.contentMode = UIViewContentModeScaleAspectFit;
			smallerSubAdventureImageViewA.clipsToBounds = YES;
			smallerSubAdventureImageViewA.center = CGPointMake(smallerSubAdventureImageViewA.center.x + 10, smallerSubAdventureImageViewA.center.y + 2);
			[self.browserWindowImageView addSubview:smallerSubAdventureImageViewA];
		}
		
		//set the content mode and other necessary properties
		dot.contentMode = UIViewContentModeScaleAspectFit;
		dot.clipsToBounds = YES;
		trackNumber.contentMode = UIViewContentModeScaleAspectFit;
		trackNumber.clipsToBounds = YES;
		
		//add them to the respective subview
		[self.browserWindowImageView addSubview:dot];
		[dotArray addObject:dot];
		[self.browserWindowImageView addSubview:trackNumber];
		[numberForDotArray addObject:trackNumber];
		
		//increment the trackIndex
		trackIndex++;
	}
	self.dotArray = [dotArray copy];
	self.numberForDotArray = [numberForDotArray copy];
}

- (IBAction)screenTapped:(UITapGestureRecognizer *)sender
{
	if ([self pointIsInsidePlayPauseButton:[sender locationInView:self.resizeView]]) [self playButtonTouchUpInside];
	if ([self pointIsInsideQRScannerButton:[sender locationInView:self.resizeView]]) [self QRButtonTouchUpInside];

	if (sender.numberOfTouches > 1) return;
	
	int dotNumber = 0;
	BOOL touchInsideDot = NO;
	for (UIImageView* dot in self.dotArray)
	{
    if (CGRectContainsPoint(dot.frame, [sender locationInView:self.view]))
		{
			touchInsideDot = YES;
			NSDictionary * track = self.CurrentUnitTracks[dotNumber];
			if ([track[kALREADY_PLAYED] boolValue])
			{
				NSString * trackCode = track[kCODE];
				self.audioFileName = trackCode;
				NSString* url = track[kURL];
				
				//load the audio file
				[self loadAudioFile];
				
				//load the track metadata
				[self loadTrackData:url];
				
				//update the browser screen
				[self updateBrowser];

			}
			
		}
		dotNumber++;
	}
	int numberForDotNumber = 0;
	for (UIImageView* trackNumberForDot in self.numberForDotArray)
	{
    if (CGRectContainsPoint(trackNumberForDot.frame, [sender locationInView:self.view]))
		{
			touchInsideDot = YES;
			NSDictionary * track = self.CurrentUnitTracks[numberForDotNumber];
			if ([track[kALREADY_PLAYED] boolValue])
			{
				NSString * trackCode = track[kCODE];
				self.audioFileName = trackCode;
				NSString* url = track[kURL];
				
				//load the audio file
				[self loadAudioFile];
				
				//load the track metadata
				[self loadTrackData:url];
				
				//update the browser screen
				[self updateBrowser];
				
			}			
		}
		numberForDotNumber++;
	}
}

-(void) updateBrowserTime
{
	// This would be less jittery if the number images were set by their centers instead of their origins.
	// Consider it. There is significant improvement to be made
	
	//	NSLog(@"%f / %f", self.player.currentTime, self.player.duration);
	
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
	
	//	NSLog(@"%d%d:%d%d of %d%d:%d%d",
	//				firstNumber,
	//				secondNumber,
	//				thirdNumber,
	//				fourthNumber,
	//				fifthNumber,
	//				sixthNumber,
	//				seventhNumber,
	//				eighthNumber);
	
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
				origin = CGPointMake(76 + imageIndex / 6 * 86, 205);
				break;
			case 1:
			case 7:
				origin = CGPointMake(92 + imageIndex / 6 * 86, 205);
				break;
			case 2:
			case 8:
				origin = CGPointMake(108 + imageIndex / 6 * 86, 207);
				break;
			case 3:
			case 9:
				origin = CGPointMake(116 + imageIndex / 6 * 86, 205);
				break;
			case 4:
			case 10:
				origin = CGPointMake(132 + imageIndex / 6 * 86, 205);
				break;
			case 5:
				origin = CGPointMake(147, 206);
				break;
				
			default:
				break;
		}
		
    imageView.frame = CGRectMake(origin.x,
																 origin.y,
																 imageView.image.size.width / 2,
																 imageView.image.size.height / 2);
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.clipsToBounds = YES;
		[self.browserWindowImageView addSubview:imageView];
		imageIndex++;
	}
}

-(void) setCurrentTrackPlayed
{
	[self applyElapsedTime];
	//apply the NSUserDefaults that will set this track to "isPlayed = YES"
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSArray* playbackInfo = [defaults arrayForKey:kPLAYBACK_USER_DEFAULTS];
	
	if (!playbackInfo)
	{//No tracks are stored (probably the first time opening the app)
		NSMutableArray * tempPlaybackInfo = [[NSMutableArray alloc] init];
		
		//get all the audio file names
		for (NSString* url in [self.audioMap allKeys])
		{
			NSString * fileName = self.audioMap[url];
			
			NSString* code = [fileName substringFromIndex:8];
			
			//load the track data
			NSString * adventureID = [code substringWithRange:NSMakeRange(code.length - 3, 2)];
			NSNumber * adventureNumber = [NSNumber numberWithInt:[[code substringFromIndex:code.length - 1] intValue]];
			NSNumber * alreadyPlayed = [NSNumber numberWithBool:NO];
			NSNumber * isPrepAdventure = [NSNumber numberWithBool:[adventureID isEqualToString:@"PA"]];
			
			//check the track data
			//NSLog(@"adventure ID: %@", adventureID);
			//NSLog(@"adventure number: %@", adventureNumber);
			//NSLog(@"already played: %@", alreadyPlayed);
			NSLog(@"is prep adventure: %@", isPrepAdventure);
			
			if ([isPrepAdventure boolValue])
			{
				NSString * prepAdventureID = [url substringWithRange:NSMakeRange([url rangeOfString:adventureID].location - 3, 2)];
				NSLog(@"prep adventure ID: %@", prepAdventureID);
				
				//assemble the track data
				NSDictionary* track = @{kADVENTURE_ID: adventureID,
														kADVENTURE_NUMBER: adventureNumber,
														kALREADY_PLAYED: alreadyPlayed,
														kIS_PREP_ADVENTURE: isPrepAdventure,
														kPREP_ADVENTURE_ID: prepAdventureID,
														kIS_SUB_ADVENTURE: [NSNumber numberWithBool:NO],
														kCODE: fileName,
														kURL: url};
				
				//store the track data
				[tempPlaybackInfo addObject:track];
				
			} else
				if ([code rangeOfString:@"a"].location == NSNotFound)
				{
					//assemble the track data
					NSDictionary* track = @{kADVENTURE_ID: adventureID,
														 kADVENTURE_NUMBER: adventureNumber,
														 kALREADY_PLAYED: alreadyPlayed,
														 kIS_PREP_ADVENTURE: isPrepAdventure,
														 kIS_SUB_ADVENTURE: [NSNumber numberWithBool:NO],
														 kCODE: fileName,
														 kURL: url};
					
					//store the track data
					[tempPlaybackInfo addObject:track];
				} else
				{
					//assemble the track data
					NSDictionary* track = @{kADVENTURE_ID: [code substringWithRange:NSMakeRange(code.length - 4, 2)],
														 kADVENTURE_NUMBER: [NSNumber numberWithInt:[[code substringWithRange:NSMakeRange(code.length - 2, 1)] intValue]],
														 kALREADY_PLAYED: alreadyPlayed,
														 kIS_PREP_ADVENTURE: isPrepAdventure,
														 kIS_SUB_ADVENTURE: [NSNumber numberWithBool:YES],
														 kCODE: fileName,
														 kURL: url};
					
					//store the track data
					[tempPlaybackInfo addObject:track];
				}
			
		}
		
		playbackInfo = [tempPlaybackInfo copy];
	}
	
	//keep track of where we are because we need to overwrite all the track info in playbackinfo.
	NSMutableArray* tempPlaybackInfo = [[NSMutableArray alloc] init];
	
	for (NSDictionary* track in playbackInfo)
	{
    if (!self.isPrepAdventure &&
				[(NSString*)track[kADVENTURE_ID] isEqualToString:self.adventure_ID] &&
				[track[kADVENTURE_NUMBER] intValue] == self.adventureNumber &&
				[track[kIS_SUB_ADVENTURE] boolValue] == self.isSubAdventure)
		{
			NSMutableDictionary* tempTrack = [track mutableCopy];
			tempTrack[kALREADY_PLAYED] = [NSNumber numberWithBool:YES];
			[tempPlaybackInfo addObject:[tempTrack copy]];
		}
		else if (self.isPrepAdventure &&
						 [(NSString*)track[kPREP_ADVENTURE_ID] isEqualToString:self.prepAdventureID] &&
						 [track[kADVENTURE_NUMBER] intValue] == self.adventureNumber)
		{
			NSMutableDictionary* tempTrack = [track mutableCopy];
			tempTrack[kALREADY_PLAYED] = [NSNumber numberWithBool:YES];
			[tempPlaybackInfo addObject:[tempTrack copy]];
		}
		else [tempPlaybackInfo addObject:[track copy]];
	}
	
	playbackInfo = [tempPlaybackInfo copy];
	
	self.playbackInfo = playbackInfo;
	
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
		
		//get all the audio file names
		for (NSString* url in [self.audioMap allKeys])
		{
			NSString * fileName = self.audioMap[url];
			
			NSString* code = [fileName substringFromIndex:8];
			
			//load the track data
			NSString * adventureID = [code substringWithRange:NSMakeRange(code.length - 3, 2)];
			NSNumber * adventureNumber = [NSNumber numberWithInt:[[code substringFromIndex:code.length - 1] intValue]];
			NSNumber * alreadyPlayed = [NSNumber numberWithBool:NO];
			NSNumber * isPrepAdventure = [NSNumber numberWithBool:[adventureID isEqualToString:@"PA"]];
			
			//check the track data
			//NSLog(@"adventure ID: %@", adventureID);
			//NSLog(@"adventure number: %@", adventureNumber);
			//NSLog(@"already played: %@", alreadyPlayed);
			NSLog(@"is prep adventure: %@", isPrepAdventure);
			
			if ([isPrepAdventure boolValue])
			{
				NSString * prepAdventureID = [url substringWithRange:NSMakeRange([url rangeOfString:adventureID].location - 3, 2)];
				NSLog(@"prep adventure ID: %@", prepAdventureID);
				
				//assemble the track data
				NSDictionary* track = @{kADVENTURE_ID: adventureID,
														kADVENTURE_NUMBER: adventureNumber,
														kALREADY_PLAYED: alreadyPlayed,
														kIS_PREP_ADVENTURE: isPrepAdventure,
														kPREP_ADVENTURE_ID: prepAdventureID,
														kIS_SUB_ADVENTURE: [NSNumber numberWithBool:NO],
														kCODE: fileName,
														kURL: url};
				
				//store the track data
				[tempPlaybackInfo addObject:track];
				
			} else
				if ([code rangeOfString:@"a"].location == NSNotFound)
				{
					//assemble the track data
					NSDictionary* track = @{kADVENTURE_ID: adventureID,
														 kADVENTURE_NUMBER: adventureNumber,
														 kALREADY_PLAYED: alreadyPlayed,
														 kIS_PREP_ADVENTURE: isPrepAdventure,
														 kIS_SUB_ADVENTURE: [NSNumber numberWithBool:NO],
														 kCODE: fileName,
														 kURL: url};
					
					//store the track data
					[tempPlaybackInfo addObject:track];
				} else
				{
					//assemble the track data
					NSDictionary* track = @{kADVENTURE_ID: [code substringWithRange:NSMakeRange(code.length - 4, 2)],
														 kADVENTURE_NUMBER: [NSNumber numberWithInt:[[code substringWithRange:NSMakeRange(code.length - 2, 1)] intValue]],
														 kALREADY_PLAYED: alreadyPlayed,
														 kIS_PREP_ADVENTURE: isPrepAdventure,
														 kIS_SUB_ADVENTURE: [NSNumber numberWithBool:YES],
														 kCODE: fileName,
														 kURL: url};
					
					//store the track data
					[tempPlaybackInfo addObject:track];
				}
			
		}
		
		playbackInfo = [tempPlaybackInfo copy];
	}
	
	//	for (NSDictionary * track in playbackInfo)
	//	{
	//		NSLog(@"adventure ID: %@", track[kADVENTURE_ID]);
	//		NSLog(@"adventure number: %@", track[kADVENTURE_NUMBER]);
	//		NSLog(@"already played: %@", track[kALREADY_PLAYED]);
	//		NSLog(@"is prep adventure: %@", track[kIS_PREP_ADVENTURE]);
	//	}
	
	self.playbackInfo = playbackInfo;
	
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
		//		NSLog(@"adventure ID: %@", track[kADVENTURE_ID]);
		//		NSLog(@"adventure number: %@", track[kADVENTURE_NUMBER]);
		//		NSLog(@"already played: %@", track[kALREADY_PLAYED]);
		//		NSLog(@"is prep adventure: %@", track[kIS_PREP_ADVENTURE]);
		
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
	
	if (concentricCircleLevel > 12)
	{
		concentricCircleLevel = 12;
	}
	if (concentricCircleLevel < 0)
	{
		concentricCircleLevel = 0;
	}
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
		[self setCurrentTrackPlayed];
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
	//[self setCurrentTrackPlayed];
	[self.player setCurrentTime:0];
	[self applyElapsedTime];
	self.animatedConcentricImageView.image = self.animatedConcentricImageArray[0];
	self.elapsedImageView.image = self.elapsedVisualImageArray[[self.elapsedVisualImageArray count]-1];
	[self updateBrowser];
}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
	[self stopPlaybackAnimations];
}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags
{
	[self startPlaybackAnimations];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
	NSLog(@"audio error: %@", error);
	[player stop];
}

#ifdef TESTING_MODE

- (IBAction)testingLongPress:(UILongPressGestureRecognizer *)sender
{
	if([sender numberOfTouches] == 3)
	{
		[self reset];
	}
}

-(void) reset
{
	if (self.player.isPlaying)
	{
		[self playButtonTouchDown];
		[self playButtonTouchUpInside];
	}
	self.player = nil;
	[self updateBrowser];
	
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults removeObjectForKey:kPLAYBACK_USER_DEFAULTS];
	[defaults removeObjectForKey:@"hasBeenLaunchedBefore"];
	[defaults removeObjectForKey:kURL_TO_AUDIO_FILE_MAP_USER_DEFAULTS];
	
	if(![defaults boolForKey:@"hasBeenLaunchedBefore"])
	{
		[self performSegueWithIdentifier:@"Instructions Segue"
															sender:self];
		
		[defaults setBool:YES forKey:@"hasBeenLaunchedBefore"];
		[defaults synchronize];
	}
	[self loadUserDefaults];
}

#endif

@end
