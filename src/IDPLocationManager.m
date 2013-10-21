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
@property (nonatomic, assign, readwrite)	IDPLocationStatus		status;

// you can use the property for a more fine grained control of CLLocationManager
@property (nonatomic, retain, readwrite)	CLLocationManager		*locationManager;

// the amount of times the manager was scheduled
@property (nonatomic, assign, readwrite)	NSUInteger				scheduleCount;

@property (nonatomic, readwrite, getter = isScheduled)	BOOL		scheduled;

- (void)notifyObserversOfBecomingAvailable;
- (void)notifyObserversOfBecomingUnavailable;

- (void)notifyObserversOfLocationChanges;

- (void)notifyObserversOfStatus:(IDPLocationStatus)status;

@end

@implementation IDPLocationManager

@synthesize status	= _status;

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
	
	CLLocationManager *manager = [CLLocationManager object];
    manager.delegate = self;
    manager.distanceFilter = kCLDistanceFilterNone;
    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
	if ([manager respondsToSelector:@selector(setActivityType:)]) {
		manager.activityType = CLActivityTypeFitness;
	}
	
	self.locationManager = manager;
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
	BOOL shouldNotify = location.latitude != _location.latitude
						|| location.longitude != _location.longitude;
	
	IDPNonatomicAssignPropertySynthesize(_location, location);
	
	if (shouldNotify) {
		[self notifyObserversOfLocationChanges];
	}
}

- (void)setStatus:(IDPLocationStatus)status {
	BOOL shouldNotify = status != _status;
	
	IDPNonatomicAssignPropertySynthesize(_status, status);
	
	if (shouldNotify) {
		[self notifyObserversOfStatus:status];
	}
}

- (IDPLocationStatus)status {
	if (![CLLocationManager locationServicesEnabled]) {
		return kIDPLocationUnavailable;
	}

	return _status;
}

- (CLAuthorizationStatus)authorizationStatus {
	return [CLLocationManager authorizationStatus];
}

#pragma mark -
#pragma mark Public

- (void)schedule {
	if (![CLLocationManager locationServicesEnabled]) {
		return;
	}
	
	if (0 == self.scheduleCount) {
		[self.locationManager startUpdatingLocation];
	} else {
		[self notifyObserversOfStatus:self.status];
	}
	
	self.scheduleCount += 1;
}

- (void)unschedule {
	if (0 == self.scheduleCount) {
		return;
	}
	
	self.scheduleCount -=1;
	if (0 == self.scheduleCount) {
		[self.locationManager stopUpdatingLocation];
	}
}

#pragma mark -
#pragma mark Private

- (void)notifyObserversOfStatus:(IDPLocationStatus)status {
	if (kIDPLocationAvailable == status) {
		[self notifyObserversOfBecomingAvailable];
	} else {
		[self notifyObserversOfBecomingUnavailable];
	}
}

- (void)notifyObserversOfBecomingAvailable {
	[self notifyObserversWithSelector:@selector(locationManagerDidBecomeAvailable:)];
}

- (void)notifyObserversOfBecomingUnavailable {
	[self notifyObserversWithSelector:@selector(locationManagerDidBecomeUnavailable:)];
}

- (void)notifyObserversOfLocationChanges {
	[self notifyObserversWithSelector:@selector(locationManagerDidChangeLocation:)];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)		 locationManager:(CLLocationManager *)manager
	didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	if (kCLAuthorizationStatusNotDetermined == status) {
		self.status = kIDPLocationUnavailable;		
		[self.locationManager startUpdatingLocation];
	} else if (kCLAuthorizationStatusAuthorized == status) {
//		self.status = kIDPLocationAvailable;
//		self.location = manager.location.coordinate;
	} else {
		[self.locationManager stopUpdatingLocation];
		self.status = kIDPLocationUnavailable;
	}
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
	self.status = kIDPLocationUnavailable;
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
	self.status = kIDPLocationAvailable;
}

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations
{
	self.status = kIDPLocationAvailable;
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
	self.status = kIDPLocationUnavailable;
}

@end
