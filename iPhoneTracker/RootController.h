//
//  iPhoneTrackerViewController.h
//  iPhoneTracker
//
//  Created by Alasdair Allan on 24/08/2011.
//  Copyright 2011 University of Exeter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>

@interface RootController : UIViewController <MKMapViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    
    MKMapView *map;
}

@property (nonatomic, retain) IBOutlet MKMapView *map;

- (IBAction)exportData:(id)sender;
- (IBAction)refreshData:(id)sender;
- (IBAction)about:(id)sender;

@end
