//
//  EACInstructionViewController.m
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#import "EACInstructionViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface EACInstructionViewController ()<UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *instructionImageView;

@property (weak, nonatomic) IBOutlet UIPageControl *instructionPageControl;

@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (nonatomic, strong) NSArray * instructionImageArray;

@end

@implementation EACInstructionViewController


-(void)viewDidLoad
{
	self.playButton.hidden = YES;
	[self.instructionImageView setHidden:YES];
	[super viewDidLoad];
	self.instructionImageArray = @[[UIImage imageNamed:@"instructional cards 1.png"],
																[UIImage imageNamed:@"instructional cards 2.png"],
																[UIImage imageNamed:@"instructional cards 3.png"]];
	self.instructionPageControl.numberOfPages = [self.instructionImageArray count];
	self.instructionPageControl.currentPage = 0;
	self.playButton.layer.cornerRadius = 10; // this value vary as per your desire
	self.playButton.clipsToBounds = YES;

}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	CGRect mainFrame = self.scrollView.frame;
	[self.scrollView setFrame:CGRectMake(self.scrollView.frame.size.width,
																			0,
																			mainFrame.size.width,
																			mainFrame.size.height)];
	[self setupScrollView];
	[UIView animateWithDuration:0.1 animations:^() {
		self.scrollView.frame = mainFrame;
	}];
}

-(void)setupScrollView
{
	self.scrollView.pagingEnabled = YES;
	self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame) * [self.instructionImageArray count],
																					 CGRectGetHeight(self.scrollView.frame));
	int imageCounter = 0;
	
	[self.instructionImageView removeFromSuperview];
	for (UIImage* instructionImage in self.instructionImageArray)
	{
		//create the new imageView
		UIImageView* instructionImageView = [[UIImageView alloc] initWithImage:instructionImage];
		
		//create the correct frame for the imageview.
		[instructionImageView setFrame:CGRectMake(self.instructionImageView.frame.origin.x + self.scrollView.frame.size.width * imageCounter,
																							self.instructionImageView.frame.origin.y,
																							self.instructionImageView.frame.size.width,
																							self.instructionImageView.frame.size.height)];
		
		//make it look nice with rounded corners
		instructionImageView.layer.cornerRadius = 20.0;
		instructionImageView.layer.masksToBounds = YES;
				
		//add it as a subview
		[self.scrollView addSubview:instructionImageView];
    imageCounter++;
	}
	
	[self.playButton removeFromSuperview];
	
	UIButton*button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.frame = self.playButton.frame;
	[button setBackgroundImage:[UIImage imageNamed:@"normalPlayPause.png"]
										forState:UIControlStateNormal];
	[button addTarget:self
						 action:@selector(dismissVC)
	 forControlEvents:UIControlEventTouchUpInside];

	button.frame = CGRectMake(button.frame.origin.x + self.scrollView.frame.size.width * --imageCounter,
														button.frame.origin.y,
														button.frame.size.width,
														button.frame.size.height);
	
	[self.scrollView addSubview:button];

	[self.scrollView addSubview:button];
	self.scrollView.scrollsToTop = NO;
	self.scrollView.delegate = self;
}

-(void) dismissVC
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

// at the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	// switch the indicator when more than 50% of the previous/next page is visible
	CGFloat pageWidth = CGRectGetWidth(self.scrollView.frame);
	NSUInteger page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	self.instructionPageControl.currentPage = page;
}

- (void)gotoPage:(BOOL)animated
{
	NSInteger page = self.instructionPageControl.currentPage;
		
	// update the scroll view to the appropriate page
	CGRect bounds = self.scrollView.bounds;
	bounds.origin.x = CGRectGetWidth(bounds) * page;
	bounds.origin.y = 0;
	[self.scrollView scrollRectToVisible:bounds animated:animated];
}

- (IBAction)changePage:(id)sender
{
	[self gotoPage:YES];    // YES = animate
}



@end
