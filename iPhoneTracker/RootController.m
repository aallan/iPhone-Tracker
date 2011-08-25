//
//  iPhoneTrackerViewController.m
//  iPhoneTracker
//
//  Created by Alasdair Allan on 24/08/2011.
//  Copyright 2011 University of Exeter. All rights reserved.
//

#import "AppDelegate.h"
#import "RootController.h"

@implementation RootController

@synthesize map;

- (void)dealloc {
    [map release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
        
}

-(void)viewDidAppear:(BOOL) animated {
    [super viewDidAppear:animated];
    [self refreshData:self];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CLLocation *location = delegate.locationManager.location;
    MKCoordinateSpan span; 
    span.latitudeDelta = 0.2; 
    span.longitudeDelta = 0.2;
    MKCoordinateRegion region; 
    region.span = span; 
    region.center = location.coordinate;
    [self.map setRegion:region animated:YES]; 
    self.map.showsUserLocation = YES;
}

- (void)viewDidUnload {
    [self setMap:nil];
    [super viewDidUnload];
  
}

#pragma mark - Callback Methods


- (IBAction)exportData:(id)sender {
    UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Export via Email", nil] autorelease];
    [actionSheet showInView:self.view];
    
}

- (IBAction)refreshData:(id)sender {
    
    [self.map removeOverlays:self.map.overlays];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSLog(@"Database has %d location points", [delegate getSizeOfDatabase]);
    for ( int i = 1; i <= [delegate getSizeOfDatabase]; i++ ) {
        CLLocation *newLocation = [delegate readLocationFromDatabaseWithIndex:i];
        
       // NSLog(@"retrieved = %@", newLocation);
        
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:newLocation.coordinate radius:newLocation.horizontalAccuracy];
        [circle setTitle:@"location"];
        
        [self.map addOverlay:circle];
    }
}

#pragma mark - MKMapKit Delegate Methods

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    
    MKCircle *circle = overlay;
    MKCircleView *circleView = [[[MKCircleView alloc] initWithCircle:overlay] autorelease];
    
    if ([circle.title isEqualToString:@"location"]) {
        circleView.fillColor = [UIColor redColor];
        circleView.alpha = 0.25;
    }
    return circleView;
}

#pragma mark - UIActionSheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (buttonIndex == actionSheet.firstOtherButtonIndex + 0) {
        NSData *data = [delegate exportDatabase];
        if (data != nil) {
            MFMailComposeViewController *picker = [[[MFMailComposeViewController alloc] init] autorelease];
            [picker setSubject:@"My Location Data"];
            [picker addAttachmentData:data mimeType:@"application/iphonetracker" fileName:@"location.db"];
            [picker setToRecipients:[NSArray array]];
            [picker setMessageBody:@"An SQLite database containing your location data." isHTML:NO];
            [picker setMailComposeDelegate:self];
            [self presentModalViewController:picker animated:YES];                    
        }
        
    }
}

#pragma mark - MFMailComposeViewController Delegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
}

@end
