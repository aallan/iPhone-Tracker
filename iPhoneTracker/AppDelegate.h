//
//  iPhoneTrackerAppDelegate.h
//  iPhoneTracker
//
//  Created by Alasdair Allan on 24/08/2011.
//  Copyright 2011 University of Exeter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class RootController;

@interface AppDelegate : NSObject <UIApplicationDelegate, CLLocationManagerDelegate, UIAlertViewDelegate> {

    CLLocationManager *locationManager;
    NSData *importBuffer;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RootController *viewController;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) NSData *importBuffer;

- (void)copyDatabaseFromBundle;
- (void)copyDatabaseToDocumentsDirectory;

- (NSString *)databaseLocation;
- (int)getSizeOfDatabase;
- (CLLocation *)readLocationFromDatabaseWithIndex:(int)index;
- (void)addLocationToDatabase:(CLLocation *)newLocation;
- (NSData *)exportDatabase;

#pragma mark - URI Handlers

- (void)importFromURL:(NSURL *)url;


@end
