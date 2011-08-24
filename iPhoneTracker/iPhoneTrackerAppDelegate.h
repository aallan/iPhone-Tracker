//
//  iPhoneTrackerAppDelegate.h
//  iPhoneTracker
//
//  Created by Alasdair Allan on 24/08/2011.
//  Copyright 2011 University of Exeter. All rights reserved.
//

#import <UIKit/UIKit.h>

@class iPhoneTrackerViewController;

@interface iPhoneTrackerAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet iPhoneTrackerViewController *viewController;

@end
