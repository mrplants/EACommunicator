//
//  EACScannerViewController.m
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#import "EACScannerViewController.h"

@interface EACScannerViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *crosshairsImageView;
@property (weak, nonatomic) IBOutlet UIImageView *scannerLightImageView;

@property (nonatomic) int crosshairImageIndex;
@property (strong, nonatomic) NSArray *crosshairImageArray;

@property (nonatomic) int scannerLightImageIndex;
@property (strong, nonatomic) NSArray *scannerLightImageArray;

@end

@implementation EACScannerViewController


-(void)viewDidLoad
{
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
	[super viewDidLoad];
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

@end
