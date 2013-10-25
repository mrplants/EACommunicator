//
//  EACScannerViewController.h
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EAScannerDelegate <NSObject>

-(void)didScanCode:(NSString*) code;

@end

@interface EACScannerViewController : UIViewController

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSDictionary * audioMap;

@end
