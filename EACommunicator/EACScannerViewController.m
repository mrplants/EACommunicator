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

@interface EACScannerViewController () <AVCaptureMetadataOutputObjectsDelegate, ZBarCaptureDelegate>

//image Views
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *crosshairsImageView;
@property (weak, nonatomic) IBOutlet UIImageView *scannerLightImageView;
@property (weak, nonatomic) IBOutlet UIView *resizingImageView;

//visual models
@property (strong, nonatomic) NSArray *crosshairImageArray;
@property (strong, nonatomic) NSArray *scannerLightImageArray;

//camera equipment
@property (nonatomic ,strong) AVCaptureSession * videoSession;
@property (weak, nonatomic) IBOutlet UIView * cameraView;
@property (weak, nonatomic) IBOutlet UIView *cameraShutterView;
@property BOOL foundCode;

@property (atomic, strong) ZBarCaptureReader * zBarReader;

//codes that we are looking for
@property (nonatomic, strong) NSArray * codes;

@property BOOL isProcessingSampleFrame;

@end

@implementation EACScannerViewController

-(BOOL)prefersStatusBarHidden
{
	return YES;
}

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
}

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	if (IS_IPHONE_5)
	{
		[self iPhone5Setup];
	}

}

-(void)setupCamera
{
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError *error = nil;
	
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
																																			error:&error];
	if (input) {
    [session addInput:input];
	} else {
    NSLog(@"Error: %@", error);
	}
	
//	AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
	self.zBarReader = [[ZBarCaptureReader alloc] init];
	self.zBarReader.captureDelegate = self;
	[session addOutput:self.zBarReader.captureOutput];
	[self.zBarReader willStartRunning];
	
//	[output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
//	[session addOutput:output];

//	NSLog(@"%@", [output availableMetadataObjectTypes]);
	
//	[output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
	
	AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	
	[captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	[captureVideoPreviewLayer setFrame:self.cameraView.bounds];
	
	CALayer *rootLayer = [self.cameraView layer];
	[rootLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[rootLayer addSublayer:captureVideoPreviewLayer];
	
	[session startRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
	NSString *QRCode = nil;
	for (AVMetadataObject *metadata in metadataObjects) {
		if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
			QRCode = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
			break;
		}
	}
	[self scannedCode:QRCode];
}

-(void)scannedCode:(NSString *) QRCode
{
	if ([self isCorrectCode:QRCode] && !self.foundCode)
	{
		self.foundCode = YES;
		
		EACPlaybackViewController* playerViewController = self.delegate;
		playerViewController.audioFileDictionary = self.audioMap[QRCode];
		
		//load the audio file
		[playerViewController loadAudioFile];
		
		//load the track metadata
		[playerViewController loadTrackData:QRCode];
		
		//animate the pretransition view changes (light change and pause), then force transition back to the main screen
		[UIView animateWithDuration:.05
													delay:0
												options:UIViewAnimationOptionCurveEaseIn
										 animations:^(void) {
											 self.scannerLightImageView.alpha = 0;
											 self.crosshairsImageView.alpha = 0;
										 }
										 completion:^(BOOL finished){
											 self.scannerLightImageView.image = self.scannerLightImageArray[GREEN];
											 self.crosshairsImageView.image = self.crosshairImageArray[GREEN];
											 [UIView animateWithDuration:.05
																						 delay:0
																					 options:UIViewAnimationOptionCurveEaseOut
																				animations:^(){
																					self.scannerLightImageView.alpha = 1;
																					self.crosshairsImageView.alpha = 1;
																				} completion:^(BOOL finished){
																					[NSThread sleepForTimeInterval:0.45f];
																					[self backButtonTapped];
																				}];
										 }];
		NSLog(@"QR Code that is being used: %@", QRCode);
	}
	
	NSLog(@"QR Code: %@", QRCode);
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self setupCamera];

	if (IS_IPHONE_5)
	{
		//The iphone 5 has a longer screen, which cannot be accounted for in the storyboard setup, so we need to give it a different image and lay out the sub-images differently
		self.backgroundImageView.image = [UIImage imageNamed:@"scanner screen-tall@2x.png"];
	}
	
}

-(void)iPhone5Setup
{	
	//move the dynamic images down so they still line up with the slots in the background image
	self.resizingImageView.frame = CGRectMake(0, 44, self.resizingImageView.frame.size.width, self.resizingImageView.frame.size.height);
	self.cameraView.frame = CGRectMake(self.cameraView.frame.origin.x,
																		 self.cameraView.frame.origin.y + 44,
																		 self.cameraView.frame.size.width,
																		 self.cameraView.frame.size.height);
}

-(void) revealCamera
{
	[UIView animateWithDuration:.3
												delay:.2
											options:UIViewAnimationOptionTransitionCrossDissolve + UIViewAnimationOptionCurveEaseInOut
									 animations:^(){
										 self.cameraShutterView.alpha = 0;
										 self.scannerLightImageView.alpha = 1;
										 self.crosshairsImageView.alpha = 1;
									 }
									 completion:NULL];
}

- (IBAction)backButtonTapped
{
	UIViewController* destinationViewController = self.presentingViewController;
	
	CGRect mainFrame = self.view.frame;
	
	destinationViewController.view.frame = CGRectMake(0,
																										-destinationViewController.view.frame.size.height,
																										destinationViewController.view.frame.size.width,
																										destinationViewController.view.frame.size.height);
	
	[self.view.superview addSubview:destinationViewController.view];
	
	[UIView animateWithDuration:TRANSITION_TIME
												delay:0
											options:UIViewAnimationOptionCurveEaseOut
									 animations:^() {
										 self.view.frame = CGRectMake(0,
																																	self.view.frame.size.height,
																																	self.view.frame.size.width,
																																	self.view.frame.size.height);
										 destinationViewController.view.frame = mainFrame;
									 } completion:^(BOOL finished) {
										 [self dismissViewControllerAnimated:NO completion:nil];
									 }];

	
}

- (void) viewDidAppear: (BOOL) animated
{
	[super viewDidAppear:animated];
	// run the reader when the view is visible
//	self.scannerLightImageView.image = self.scannerLightImageArray[BLANK];
//	self.crosshairsImageView.image = self.crosshairImageArray[BLANK];
	[self.videoSession startRunning];
	[self revealCamera];
	self.scannerLightImageView.image = self.scannerLightImageArray[RED];
	self.crosshairsImageView.image = self.crosshairImageArray[RED];
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[self.zBarReader willStopRunning];
	[self.videoSession stopRunning];
	self.zBarReader = nil;
	self.videoSession = nil;
}

- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) orient
																 duration: (NSTimeInterval) duration
{
	// compensate for view rotation so camera preview is not rotated
//	[self.zBarReaderView willRotateToInterfaceOrientation: orient
//																							 duration: duration];
	[super willRotateToInterfaceOrientation:orient duration:duration];
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

-(void)setAudioMap:(NSDictionary *)audioMap
{
	_audioMap = audioMap;
	
	NSMutableArray * tempCodes = [[NSMutableArray alloc] init];
	for (NSDictionary * fileDictionary in [_audioMap allValues])
	{
		NSLog(@"class of fileDictionary: %@",[fileDictionary class]);
		NSLog(@"fileDictionary: %@", fileDictionary);
    [tempCodes addObject:fileDictionary[EA_URL]];
	}
	self.codes = [tempCodes copy];
}

-(void)captureReader:(ZBarCaptureReader *)captureReader didReadNewSymbolsFromImage:(ZBarImage *)image
{
	for(ZBarSymbol *sym in image.symbols)
	{
		[self scannedCode:sym.data];
		if (self.foundCode) {
			[self.zBarReader willStopRunning];
		}
	}
}

@end

 
