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
@property (nonatomic, strong) NSDictionary* audioFileDictionary;

//loads the audio file from self.audioFileDictionary
-(void)loadAudioFile;

//loads the metadata for the scanned code that corresponds to the played audio file
-(void)loadTrackData:(NSString*) scannedCode;

@end
