//
//  IDPLocationManager.h
//  Location
//
//  Created by Oleksa Korin on 10/19/13.
//  Copyright (c) 2013 Oleksa Korin. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "IDPObservableObject.h"

@class IDPLocationManager;

@protocol IDPLocationManagerObserver <NSObject>

- (void)locationManagerDidBecomeAvailable:(IDPLocationManager *)manager;
- (void)locationManagerDidBecomeUnavailable:(IDPLocationManager *)manager;

- (void)locationManagerDidChangeLocation:(IDPLocationManager *)manager;

@end

typedef enum  {
	kIDPLocationUnavailable = 0,
	kIDPLocationAvailable
} IDPLocationStatus;

// Location manager is a wrapper for CLLocation manager.
// You should call |schedule| to start receiving the location updates.
// You should only read |location|, when |locationStatus| is kIDPLocationAvailable.
// When you are not interested in location updates any more, you should call both unschedule
// and stop observing the manager.
//
@interface IDPLocationManager : IDPObservableObject
@property (nonatomic, readonly)	CLLocationCoordinate2D	location;
@property (nonatomic, readonly)	IDPLocationStatus		status;

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
