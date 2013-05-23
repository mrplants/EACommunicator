//
//  EACScannerViewController.m
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#import "EACScannerViewController.h"
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
@property (nonatomic) int crosshairImageIndex;
@property (strong, nonatomic) NSArray *crosshairImageArray;

@property (nonatomic) int scannerLightImageIndex;
@property (strong, nonatomic) NSArray *scannerLightImageArray;

//camera equipment
@property (weak, nonatomic) IBOutlet ZBarReaderView *zBarReaderView;

@property BOOL isProcessingSampleFrame;

@end

@implementation EACScannerViewController


-(void)viewDidLoad
{
	[super viewDidLoad];

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
}

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	if (IS_IPHONE_5)
	{
		[self iPhone5Setup];
	}

#if !(TARGET_IPHONE_SIMULATOR)
	[ZBarReaderView class];
	[self setupZBar];
#endif

}

-(void) setupZBar
{
	// the delegate receives decode results
	self.zBarReaderView.readerDelegate = self;	
}

-(void)iPhone5Setup
{//The iphone 5 has a longer screen, which cannot be accounted for in the storyboard setup, so we need to give it a different image and lay out the sub-images differently
	self.backgroundImageView.image = [UIImage imageNamed:@"scanner screen-tall@2x.png"];
	//move the dynamic images down so they still line up with the slots in the background image
	self.crosshairsImageView.frame = self.scannerLightImageView.frame = CGRectMake(0, 44, self.crosshairsImageView.frame.size.width, self.crosshairsImageView.frame.size.height);
}

- (IBAction)backButtonTapped
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)nextScannerButton
{
	
	if (self.crosshairImageIndex < 2)
		self.crosshairImageIndex++;
	else self.crosshairImageIndex = 0;
	
	self.crosshairsImageView.image = (UIImage *)self.crosshairImageArray[self.crosshairImageIndex];
	
}
- (IBAction)nextLightButton
{
	if (self.scannerLightImageIndex < 2)
		self.scannerLightImageIndex++;
	else self.scannerLightImageIndex = 0;
	
	self.scannerLightImageView.image = (UIImage *)self.scannerLightImageArray[self.scannerLightImageIndex];
}

-(void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

- (void) viewDidAppear: (BOOL) animated
{
	// run the reader when the view is visible
	[self.zBarReaderView start];
}

- (void) viewWillDisappear: (BOOL) animated
{
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
}

- (void) readerView: (ZBarReaderView*) view
		 didReadSymbols: (ZBarSymbolSet*) syms
					fromImage: (UIImage*) img
{
	// do something useful with results
	for(ZBarSymbol *sym in syms) {
		NSLog(@"%@", sym.data);
		break;
	}
}

@end

 
