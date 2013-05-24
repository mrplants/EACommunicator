//
//  EACScannerViewController.m
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#import "EACScannerViewController.h"
#import "EACPlaybackViewController.h"
#import "Constants.h"
#include "TargetConditionals.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import "ZBarSDK.h"

@interface EACScannerViewController () <ZBarReaderViewDelegate>

//image Views
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *crosshairsImageView;
@property (weak, nonatomic) IBOutlet UIImageView *scannerLightImageView;

//visual models
@property (strong, nonatomic) NSArray *crosshairImageArray;
@property (strong, nonatomic) NSArray *scannerLightImageArray;

//camera equipment
@property (weak, nonatomic) IBOutlet ZBarReaderView *zBarReaderView;

//codes that we are looking for
@property (nonatomic, strong) NSArray * codes;

@property BOOL isProcessingSampleFrame;

@end

@implementation EACScannerViewController


-(void)viewDidLoad
{
	[ZBarReaderView class];
	[super viewDidLoad];

#define BLANK 0
#define GREEN 1
#define RED 2
	
	self.crosshairImageArray =
	@[[UIImage imageNamed:@"scanner-crosshairs-blank.png"],
	 [UIImage imageNamed:@"scanner-crosshairs-green.png"],
	 [UIImage imageNamed:@"scanner-crosshairs-red.png"]
	 ];
	
	self.scannerLightImageArray =
	@[[UIImage imageNamed:@"scanner-light-off.png"],
	 [UIImage imageNamed:@"scanner-light-green.png"],
	 [UIImage imageNamed:@"scanner-light-red.png"]
	 ];
	
	[self loadAudioCSV];
}

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	if (IS_IPHONE_5)
	{
		[self iPhone5Setup];
	}

}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self setupZBar];

	if (IS_IPHONE_5)
	{
		//The iphone 5 has a longer screen, which cannot be accounted for in the storyboard setup, so we need to give it a different image and lay out the sub-images differently
		self.backgroundImageView.image = [UIImage imageNamed:@"scanner screen-tall@2x.png"];
	}
	
}

-(void) setupZBar
{
	//cropping sizes taken from the original scan image

	// the delegate receives decode results
	self.zBarReaderView.readerDelegate = self;
	self.zBarReaderView.tracksSymbols = NO;
	self.zBarReaderView.allowsPinchZoom = NO;
}

-(void)iPhone5Setup
{	
	//move the dynamic images down so they still line up with the slots in the background image
	self.crosshairsImageView.frame = self.scannerLightImageView.frame = CGRectMake(0, 44, self.scannerLightImageView.frame.size.width, self.scannerLightImageView.frame.size.height);
	self.zBarReaderView.frame = CGRectMake(self.zBarReaderView.frame.origin.x, self.zBarReaderView.frame.origin.y + 44, self.zBarReaderView.frame.size.width, self.zBarReaderView.frame.size.height);
}

-(void) loadAudioCSV
{
	NSString* pathT = [[NSBundle mainBundle] pathForResource:@"EACommunicatorAudioDataModel"
																										ofType:@"csv"];
	NSString* contentT = [NSString stringWithContentsOfFile:pathT
																								 encoding:NSUTF8StringEncoding
																										error:NULL];
	self.codes = [contentT componentsSeparatedByString:@"\r"];
	
}

- (IBAction)backButtonTapped
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) viewDidAppear: (BOOL) animated
{
	[super viewDidAppear:animated];
	// run the reader when the view is visible
	self.scannerLightImageView.image = self.scannerLightImageArray[BLANK];
	self.crosshairsImageView.image = self.crosshairImageArray[BLANK];
	[self.zBarReaderView start];
	self.scannerLightImageView.image = self.scannerLightImageArray[RED];
	self.crosshairsImageView.image = self.crosshairImageArray[RED];
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[self.zBarReaderView stop];
}

-(void)dealloc
{
	[self cleanup];
}

- (void) cleanup
{
	self.zBarReaderView.readerDelegate = nil;
	self.zBarReaderView = nil;
}

- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) orient
																 duration: (NSTimeInterval) duration
{
	// compensate for view rotation so camera preview is not rotated
	[self.zBarReaderView willRotateToInterfaceOrientation: orient
																			duration: duration];
	[super willRotateToInterfaceOrientation:orient duration:duration];
}

- (void) readerView: (ZBarReaderView*) view
		 didReadSymbols: (ZBarSymbolSet*) syms
					fromImage: (UIImage*) img
{
	// do something useful with results
	for(ZBarSymbol *sym in syms) {
		NSLog(@"%@", sym.data);
		if ([self isCorrectCode:sym.data])
		{
			self.scannerLightImageView.image = self.scannerLightImageArray[GREEN];
			self.crosshairsImageView.image = self.crosshairImageArray[GREEN];
			EACPlaybackViewController* playerViewController = self.delegate;
			playerViewController.audioFileName = [NSString stringWithFormat:@"ea_duotr%@",sym.data];
			[playerViewController loadAudioFile];
			[self dismissViewControllerAnimated:YES completion:NULL];
		}
		break;
	}
}

-(BOOL) isCorrectCode:(NSString*)data
{
	for (NSString* code in self.codes)
	{
    if ([data isEqualToString:code])
			return YES;
	}
	return NO;
}

@end

 
