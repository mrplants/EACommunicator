//
//  EAC_ZBarCaptureReader.h
//  EACommunicator
//
//  Created by Sean Fitzgerald on 11/10/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#import "ZBarCaptureReader.h"

@interface EAC_ZBarCaptureReader : ZBarCaptureReader

-(dispatch_queue_t) getRunningQueue;

@end
