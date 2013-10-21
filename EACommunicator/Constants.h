//
//  Constants.h
//  EACommunicator
//
//  Created by Sean Fitzgerald on 5/22/13.
//  Copyright (c) 2013 Museum of Science Boston. All rights reserved.
//

#ifndef EACommunicator_Constants_h
#define EACommunicator_Constants_h

#define TESTING_MODE (YES)

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

#define TRANSITION_TIME (.5)

#define PLAYPAUSE_X (82)
#define PLAYPAUSE_RADIUS (43)
#define PLAYPAUSE_Y (327)

#define QR_X (109)
#define QR_RADIUS (31)
#define QR_Y (409)

#define SUBADVENTURE (@"Subadventure")
#define UNIT (@"Unit")
#define ADVENTURE_NUMBER (@"Adventure Number")
#define URL (@"URL")
#define AUDIO_FILE_NAME (@"Audio File Name")

#endif
