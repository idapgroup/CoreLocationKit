//
//  IDPLocationManager.h
//  Location
//
//  Created by Oleksa Korin on 10/19/13.
//  Copyright (c) 2013 Oleksa Korin. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "IDPModel.h"
#import "IDPModelProtocol.h"

typedef enum  {
	kIDPLocationUnavailable = 0,
	kIDPLocationAvailable
} IDPLocationStatus;

// Location manager is a wrapper for CLLocation manager.
// As soon, as you create the thing, it requests for permissions.
// If the permissions are granted, you should call |schedule|
// to start receiving the location updates.
// You should only read |location|, when |locationStatus| is kIDPLocationAvailable.
// Manager calls -modelDidLoad:, when |locationStatus| changed to kIDPLocationAvailable.
// Manager calls -modelDidFailToLoad:, when |authorizationStatus| is either
// kCLAuthorizationStatusRestricted or kCLAuthorizationStatusDenied.
// Manager calls -modelDidCancel:, when when |locationStatus|
// changed to kIDPLocationUnavailable.
// Manager calls  -modelDidUnload:, when the manager unsheduled.
// Generates -modelDidChange:, when the location changed.
// Both cancel and dump perform one unschedule.
// When you are not interested in location updates any more, you should call both unschedule
// and stop observing the manager.
//
@interface IDPLocationManager : IDPModel
@property (nonatomic, readonly)	CLLocationCoordinate2D	location;
@property (nonatomic, readonly)	IDPLocationStatus		locationStatus;

// a binding to CLLocationManager class method |authorizationStatus|
@property (nonatomic, readonly)	CLAuthorizationStatus	authorizationStatus;

// you can use the property for a more fine grained control of CLLocationManager
@property (nonatomic, readonly)	CLLocationManager		*locationManager;

// the amount of times the manager was scheduled
@property (nonatomic, readonly)	NSUInteger				scheduleCount;

@property (nonatomic, readonly, getter = isScheduled)	BOOL	scheduled;

+ (id)sharedManager;

// shortcut for load
- (void)schedule;
// shortcut for cancel
- (void)unschedule;

@end
