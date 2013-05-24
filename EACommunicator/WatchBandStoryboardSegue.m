//
//  WatchBandStoryboardSegue.m
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/23/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#import "WatchBandStoryboardSegue.h"
#import "Constants.h"

@implementation WatchBandStoryboardSegue

- (void)perform
{
	// Add your own animation code here.
	
	UIViewController* sourceViewController = self.sourceViewController;
	UIViewController* destinationViewController = self.destinationViewController;
	
	CGRect mainFrame = sourceViewController.view.frame;
	
	destinationViewController.view.frame = CGRectMake(0,
																							 destinationViewController.view.frame.size.height,
																							 destinationViewController.view.frame.size.width,
																							 destinationViewController.view.frame.size.height);
	
	[sourceViewController.view.superview addSubview:destinationViewController.view];
	
	[UIView animateWithDuration:TRANSITION_TIME
												delay:0
											options:UIViewAnimationOptionCurveEaseOut
									 animations:^() {
										 sourceViewController.view.frame = CGRectMake(0,
																																	-sourceViewController.view.frame.size.height,
																																	sourceViewController.view.frame.size.width,
																																	sourceViewController.view.frame.size.height);
										 destinationViewController.view.frame = mainFrame;
									 } completion:^(BOOL finished) {
										 [[self sourceViewController] presentViewController:destinationViewController animated:NO completion:NULL];
									 }];
}

@end
