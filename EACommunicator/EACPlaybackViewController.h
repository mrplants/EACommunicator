//
//  EACPlaybackViewController.h
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EACPlaybackViewController : UIViewController

//the name of the audio file that will be played
@property (nonatomic, strong) NSString* audioFileName;

//loads the audio file called "self.audiofileName
-(void)loadAudioFile;

@end
