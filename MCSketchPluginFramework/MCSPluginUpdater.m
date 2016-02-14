//
//  MCSPluginUpdater.m
//  MCSketchPluginFramework
//
//  Created by Matt Curtis on 11/23/15.
//  Copyright © 2015 Matt. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "MCSPluginUpdater.h"

#import "SketchRuntime.h"


@implementation MCSPluginUpdater

	#pragma mark -
	#pragma mark Update Check

	- (BOOL) isNewerPluginBundleAvailableLocally:(NSString*)loadedVersion {
		AppController *appController = NSApp.delegate;
		MSPluginManager *pluginManager = appController.pluginManager;
		
		NSDictionary *currentPlugins =
			[pluginManager pluginsFromFolderAtURL:pluginManager.pluginsFolderURL visitedURLs:nil relativeFolderPath:nil];
		
		MSPluginBundle *currentPlugin = [currentPlugins objectForKey:_pluginIdentifier];
		
		if(!currentPlugin) return false;
		
		NSComparisonResult comparisonResult = [loadedVersion compare:currentPlugin.version options:NSNumericSearch];
		
		return (comparisonResult == NSOrderedAscending);
	}


	#pragma mark -
	#pragma mark Restart Prompt

	- (IBAction) restartButtonPressed:(id)sender {
		[self relaunchSketch];
	}

	- (void) showUpdateRestartPrompt {
		NSAlert *alert = [NSAlert new];
		
		alert.messageText = [NSString stringWithFormat:@"%@ update complete!", _pluginName];
		alert.informativeText = [NSString stringWithFormat:@"Restart Sketch to use the latest and greatest version of %@.", _pluginName];
		
		[alert runModal];
	}


	#pragma mark -
	#pragma mark Relaunch

	- (void) relaunchSketch {
		//	:(
	}

@end
