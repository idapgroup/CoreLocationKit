//
//  IDPLocationManager.m
//  Location
//
//  Created by Oleksa Korin on 10/19/13.
//  Copyright (c) 2013 Oleksa Korin. All rights reserved.
//

#import "IDPLocationManager.h"

#import "NSObject+IDPExtensions.h"

#import "IDPPropertyMacros.h"

@interface IDPLocationManager () <CLLocationManagerDelegate>
@property (nonatomic, assign, readwrite)	CLLocationCoordinate2D	location;
@property (nonatomic, assign, readwrite)	IDPLocationStatus		locationStatus;
@property (nonatomic, assign, readwrite)    IDPModelState   state;

// you can use the property for a more fine grained control of CLLocationManager
@property (nonatomic, retain, readwrite)	CLLocationManager		*locationManager;

// the amount of times the manager was scheduled
@property (nonatomic, assign, readwrite)	NSUInteger				scheduleCount;

@property (nonatomic, readwrite, getter = isScheduled)	BOOL		scheduled;

- (void)updateStatus;

// this method should be called, when the locationStatus changed
- (void)processStatusChange;

@end

@implementation IDPLocationManager

@dynamic authorizationStatus;

#pragma mark -
#pragma mark Class Methods

+ (id)sharedManager {
	static dispatch_once_t pred;
	static id <NSObject> __sharedManager = nil;
	
	dispatch_once(&pred, ^{
		__sharedManager = [[self alloc] init];
	});

	return __sharedManager;
}

#pragma mark -
#pragma mark Initializations and Deallocations

- (void)dealloc {
    self.locationManager = nil;
	
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        [self baseInit];
    }
	
    return self;
}

- (void)baseInit {
	[super baseInit];
	
	self.locationManager = [CLLocationManager object];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
}

#pragma mark -
#pragma mark Accessors

- (void)setLocationManager:(CLLocationManager *)locationManager {
	if (locationManager != _locationManager) {
		[_locationManager stopUpdatingLocation];
	}
	
	IDPNonatomicRetainPropertySynthesize(_locationManager, locationManager);
}

- (void)setLocation:(CLLocationCoordinate2D)location {
	IDPNonatomicAssignPropertySynthesize(_location, location);
	
	[self notifyObserversOfChanges];
}

- (CLAuthorizationStatus)authorizationStatus {
	return [CLLocationManager authorizationStatus];
}

#pragma mark -
#pragma mark Public

// shortcut for load
- (void)schedule {
	[self load];
}

// shortcut for cancel
- (void)unschedule {
	[self cancel];
}

- (BOOL)load {
	if (![super load]) {
		return NO;
	}
	
	[self updateStatus];
	
	if (kIDPLocationAvailable == self.locationStatus) {
		[self processStatusChange];
		[self.locationManager startUpdatingLocation];
		self.scheduleCount += 1;
	}
	
	return kIDPLocationAvailable == self.locationStatus;
}

- (void)cancel {
    [self dump];
}

- (void)dump {
	if (0 == self.scheduleCount) {
		return;
	}
	
	self.scheduleCount -=1;
	if (0 == self.scheduleCount) {
		[self.locationManager stopUpdatingLocation];
		[super dump];
	}
}

#pragma mark -
#pragma mark Private

- (void)updateStatus {
	BOOL isAuthorized = kCLAuthorizationStatusAuthorized == self.authorizationStatus;
	self.locationStatus = isAuthorized ? kIDPLocationAvailable : kIDPLocationUnavailable;
}

- (void)processStatusChange {
	if (IDPModelLoading == self.state) {
		if (kIDPLocationAvailable == self.locationStatus) {
			[self finishLoading];
		} else if (kCLAuthorizationStatusNotDetermined != self.authorizationStatus) {
			[self failLoading];
		}
	} else {
		[super cancel];
	}
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)		 locationManager:(CLLocationManager *)manager
	didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	[self updateStatus];
	[self processStatusChange];
}

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations
{
	self.location = manager.location.coordinate;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	self.location = manager.location.coordinate;
}
#pragma clang diagnostic pop

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	BOOL isUnavailable = (kCLErrorDenied == error.code
						  || kCLErrorNetwork == error.code
						  || kCLErrorLocationUnknown == error.code);
	[self updateStatus];
	[self processStatusChange];
}

@end
