//
//  MCSPluginUserDefaultsController.m
//  MCSketchPluginFramework
//
//  Created by Matt Curtis on 11/23/15.
//  Copyright © 2015 Matt. All rights reserved.
//

#import "MCSPluginUserDefaultsController.h"

@implementation MCSPluginUserDefaultsController

	- (instancetype) initWithCoder:(NSCoder*)coder {
		return [super initWithDefaults:[self userDefaultsProxy] initialValues:nil];
	}

	- (instancetype) initWithDefaults:(NSUserDefaults*)defaults initialValues:(NSDictionary*)initialValues {
		return [super initWithDefaults:defaults ?: [self userDefaultsProxy] initialValues:initialValues];
	}

	- (NSUserDefaults*) userDefaultsProxy {
		return nil; // subclass point
	}

@end