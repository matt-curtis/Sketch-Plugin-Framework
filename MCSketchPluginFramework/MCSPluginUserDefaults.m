
//
//  MCSPluginUserDefaults.m
//  MCSketchPluginFramework
//
//  Created by Matt Curtis on 11/23/15.
//  Copyright © 2015 Matt. All rights reserved.
//

#import "MCSPluginUserDefaults.h"

@implementation MCSPluginUserDefaults

	- (BOOL) synchronize {
		return [[NSUserDefaults standardUserDefaults] synchronize];
	}

	- (NSString*) getNamespacedKeyName:(NSString*)keyName {
		return [_pluginIdentifier stringByAppendingFormat:@".%@", keyName];
	}

	- (id) objectForKey:(NSString*)defaultName {
		defaultName = [self getNamespacedKeyName:defaultName];
		
		return [[NSUserDefaults standardUserDefaults] objectForKey:defaultName];
	}

	- (void) setObject:(id)value forKey:(NSString*)defaultName {
		defaultName = [self getNamespacedKeyName:defaultName];
		
		[[NSUserDefaults standardUserDefaults] setObject:value forKey:defaultName];
	}

	- (void) removeObjectForKey:(NSString*)defaultName {
		defaultName = [self getNamespacedKeyName:defaultName];
		
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultName];
	}

@end