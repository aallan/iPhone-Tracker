//
//  iPhoneTrackerAppDelegate.m
//  iPhoneTracker
//
//  Created by Alasdair Allan on 24/08/2011.
//  Copyright 2011 University of Exeter. All rights reserved.
//

#import "AppDelegate.h"
#import "RootController.h"

#include <sqlite3.h>

@implementation AppDelegate

@synthesize window=_window;
@synthesize viewController=_viewController;

@synthesize locationManager;
@synthesize importBuffer;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
     
    // If the UIApplicationLaunchOptionsLocationKey is present we have been launched in the background
    if ( [launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey] != nil ) {
        
    }

    // If the UIApplicationLaunchOptionsURLKey is present we have been launched with a URL
    if ( [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey] != nil ) {
        NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
        if([[[UIDevice currentDevice] systemVersion] hasPrefix:@"3.2"]) {
            [self application:application handleOpenURL:url];
        }
    } 
    
    // Copy the starter location database to the Documents directory if needed
    [self copyDatabaseFromBundle];
    
    // Create a location manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    [locationManager startMonitoringSignificantLocationChanges];
    
    // Check if location services are enabled
    if ( ![CLLocationManager locationServicesEnabled] ) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"Location services have been disabled for this device."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        
    }
    
    // Check the device is capable of monitoring significant location changes
    if ( ![CLLocationManager significantLocationChangeMonitoringAvailable] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Significant Location Change" message:@"This device is not able to report updates based on significant location changes only. This primarily involves detecting changes in the cell tower currently associated with the device."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];            
    }

    // Check to see if background operations are supported
    UIDevice* device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
        backgroundSupported = device.multitaskingSupported;
    }
    
    if( !backgroundSupported ) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Multitasking Not Supported" message:@"The ability to execute code in the background is not supported on all devices. Multitasking and background location monitoring is not available on this device."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        
    }
    
    // Initialise the root view controller
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc {
    [_window release];
    [_viewController release];
    [locationManager release];
    [importBuffer release];
    [super dealloc];
}

#pragma mark - SQLite Methods

- (void)copyDatabaseFromBundle {
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    NSString *filePath = [self databaseLocation];
    
    // We don't have a database, maybe this is the first time we've been run?
    if ( ![fileManager fileExistsAtPath:filePath] ) { 
        NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"location.db"]; 
        [fileManager copyItemAtPath:bundlePath toPath:filePath error:nil];
    } 
    
}

- (void)copyDatabaseToDocumentsDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    NSString *filePath = [self databaseLocation];
    
    // We have a new imported database
    if ( self.importBuffer != nil ) {
        NSError *error;
        
        NSLog(@"Writing copy of DB to file %@", filePath);
        [fileManager removeItemAtPath:filePath error:&error];
        BOOL status = [self.importBuffer writeToFile:filePath atomically:YES];
        if ( status ) {
            // if we succeeded zero the input buffer.
            self.importBuffer = nil;
        } else {
            NSString *errorTitle = [NSString stringWithFormat:@"Error (%@)", error.code];
            NSString *errorMessage = error.localizedDescription;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];   
            
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Empty Database" message:@"The imported database is empty. Discarding and keeping existing database." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];   

    }
}

- (NSString *)databaseLocation {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"location.db"];
    return filePath;
}

- (int)getSizeOfDatabase {
    
    int count = 0;
    sqlite3 *database;
    
    if (sqlite3_open([[self databaseLocation] UTF8String], &database) == SQLITE_OK) 
    {
        const char* sqlStatement = "SELECT COUNT(*) FROM location";
        sqlite3_stmt* statement;
        
        if( sqlite3_prepare_v2(database, sqlStatement, -1, &statement, NULL) == SQLITE_OK ) 
        {
            if( sqlite3_step(statement) == SQLITE_ROW )
                count  = sqlite3_column_int(statement, 0); 
        }
        else
        {
            NSLog( @"Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(database) );
        }
        
        // Finalize and close database.
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    
    return count;
}

- (CLLocation *)readLocationFromDatabaseWithIndex:(int)index {
    
    CLLocation *location = nil;
    sqlite3 *database;
    
    if(sqlite3_open([[self databaseLocation] UTF8String], &database) == SQLITE_OK) {
        const char *sqlStatement = [[NSString stringWithFormat:@"SELECT * FROM location WHERE id = '%d'", index] cStringUsingEncoding:NSASCIIStringEncoding];
        sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(database, sqlStatement, 
                              -1, &compiledStatement, NULL) == SQLITE_OK) {
            if(sqlite3_step(compiledStatement) == SQLITE_ROW) {
                
                NSString *timestamp = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
                
                // Convert string to date object
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"%Y-%m-%d %H:%M:%S %z"];
                NSDate *date = [dateFormat dateFromString:timestamp];  
                            
                float latitude = sqlite3_column_double(compiledStatement, 2);
                float longitude = sqlite3_column_double(compiledStatement, 3);
                float altitude = sqlite3_column_double(compiledStatement, 4);
                float horizontalAccuracy = sqlite3_column_double(compiledStatement, 5);
                float verticalAccuracy = sqlite3_column_double(compiledStatement, 6);
                float speed = sqlite3_column_double(compiledStatement, 7);
                float course = sqlite3_column_double(compiledStatement, 8);
                
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
                location = [[CLLocation alloc] initWithCoordinate:coordinate altitude:(CLLocationDistance)altitude horizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy verticalAccuracy:(CLLocationAccuracy)verticalAccuracy course:(CLLocationDirection)course speed:(CLLocationSpeed)speed timestamp:date];
            }
        }
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
    return location;
}

-(void) addLocationToDatabase:(CLLocation *)newLocation {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"location.db"];
    
    sqlite3 *database;
    
    if(sqlite3_open([filePath UTF8String], &database) == SQLITE_OK) {
        const char *sqlStatement = "INSERT INTO location (timestamp, latitude, longitude, altitude, horizontalAccuracy, verticalAccuracy, speed, course) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK)    {
            
            sqlite3_bind_text(compiledStatement, 1, [[newLocation.timestamp description] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(compiledStatement, 2, newLocation.coordinate.latitude);
            sqlite3_bind_double(compiledStatement, 3, newLocation.coordinate.longitude);
            sqlite3_bind_double(compiledStatement, 4, newLocation.altitude);
            sqlite3_bind_double(compiledStatement, 5, newLocation.horizontalAccuracy);
            sqlite3_bind_double(compiledStatement, 6, newLocation.verticalAccuracy);
            sqlite3_bind_double(compiledStatement, 7, newLocation.speed);
            sqlite3_bind_double(compiledStatement, 8, newLocation.course);
            
        }
        if(sqlite3_step(compiledStatement) != SQLITE_DONE ) {
            NSLog( @"Error: %s", sqlite3_errmsg(database) );
        } else {
            NSLog( @"Insert into row id = %d", (int)sqlite3_last_insert_rowid(database));
        }
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
    
    
} 

- (NSData *)exportDatabase {
    return [NSData dataWithContentsOfFile:[self databaseLocation]];

}

#pragma mark - URI Import Methods

- (void)importFromURL:(NSURL *)url {
    NSLog(@"Importing from url = %@", url);
    self.importBuffer = [NSData dataWithContentsOfURL:url];
    
    // We have a new database ask the user whether we should use it?
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Importing Database" message:@"Do you wish to import a new database? The existing data will be overwritten."  delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Proceed", nil];
    [alert show];
    [alert release];

    
}

-(BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    BOOL status = NO;
    if (url != nil && [url isFileURL]) {
        [self importFromURL:url];
        status = YES;
    } 
    return status;
}


#pragma mark - UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
   
    if ( buttonIndex == 0 ) {
        NSLog(@"Copy cancelled");
    } else if ( buttonIndex == 1 ) {
        NSLog(@"Proceed with copy");
        [self copyDatabaseToDocumentsDirectory];
        [self.viewController refreshData:self];
    }
    
}

#pragma mark - CLLocationManager Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    NSLog(@"%@", newLocation);
    [self addLocationToDatabase:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    NSString *errorTitle = [NSString stringWithFormat:@"Error (%@)", error.code];
    NSString *errorMessage = error.localizedDescription;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];   
}

@end
