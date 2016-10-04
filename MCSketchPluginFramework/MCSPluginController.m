//
//  MCSPluginController.m
//  MCSketchPluginFramework
//
//  Created by Matt Curtis on 10/11/15.
//  Copyright © 2015 Matt. All rights reserved.
//

#import "MCSPluginController.h"

#import "RSSwizzle.h"

#import "Utilities.h"


//	Notification

NSString *const MCSPluginSelectionDidChangeNotification = @"MCSPluginSelectionDidChangeNotification";

NSString *const MCSPluginCurrentArtboardDidChangeNotification = @"MCSPluginCurrentArtboardDidChangeNotification";

NSString *const MCSPluginCurrentDocumentDidChangeNotification = @"MCSPluginCurrentDocumentDidChangeNotification";

NSString *const MCSPluginAllDocumentsClosedNotification = @"MCSPluginAllDocumentsClosedNotification";

//	Notification Keys

NSString *const MCSPluginNotificationDocumentKey = @"MCSPluginNotificationDocumentKey";

NSString *const MCSPluginNotificationDocumentWindowKey = @"MCSPluginNotificationDocumentWindowKey";


@implementation MCSPluginController {
	
	BOOL _showedUpdatePromptOnce;
	
	}

	#pragma mark -
	#pragma mark Instantation

	- (instancetype) init {
		self = [super init];
		if(!self) return self;
		
		//	Swizzling
		
		[self swizzleForEvents];
		
		//	Notifications
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		
		[notificationCenter
			addObserver:self
			selector:@selector(windowBecameKeyOrMain:)
			name:NSWindowDidBecomeKeyNotification
			object:nil];
		
		[notificationCenter
			addObserver:self
			selector:@selector(windowBecameKeyOrMain:)
			name:NSWindowDidBecomeMainNotification
			object:nil];
		
		[notificationCenter
			addObserver:self
			selector:@selector(windowWillClose:)
			name:NSWindowWillCloseNotification
			object:nil];
		
		[notificationCenter
			addObserver:self
			selector:@selector(applicationDidBecomeActive)
			name:NSApplicationDidBecomeActiveNotification
			object:nil];
		
		//	User Defaults
		
		_userDefaults = [MCSPluginUserDefaults new];
		
		//	Updater
		
		_updater = [MCSPluginUpdater new];
		
		return self;
	}

	- (void) dealloc {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}


	#pragma mark -
	#pragma mark Singleton

	+ (instancetype) pluginController {
		//	Create table map
		
		static NSMutableDictionary *instanceDict;
		
		if(!instanceDict) instanceDict = [NSMutableDictionary new];
		
		//	Instance of class already exists
		
		id<NSCopying> key = (id<NSCopying>)[self class];
		
		id instance = [instanceDict objectForKey:key];
		
		if(instance) return instance;
		
		//	Instance doesn't exist, create it
		
		instance = [self new];
		
		[instanceDict setObject:instance forKey:key];
		
		return instance;
	}

	+ (instancetype) pluginController:(MSPluginBundle*)plugin pluginCommand:(MSPluginCommand*)pluginCommand {
		MCSPluginController *controller = [self pluginController];
		
		controller.plugin = plugin;
		controller.pluginCommand = pluginCommand;
		
		return controller;
	}


	#pragma mark -
	#pragma mark Utilities

	+ (NSAlert*) alertWithTitle:(NSString*)title information:(NSString*)information run:(BOOL)run {
		NSAlert *alert = [NSAlert new];
		
		alert.messageText = title;
		alert.informativeText = information;
		
		if(run) [alert runModal];
		
		return alert;
	}

	+ (NSAlert*) alertWithTitle:(NSString*)title information:(NSString*)information {
		return [self alertWithTitle:title information:information run:true];
	}


	#pragma mark -
	#pragma mark Application Notifications

	- (void) applicationDidBecomeActive {
		/*
		if(_showedUpdatePromptOnce) return;
		
		BOOL newerPluginBundleAvailable = [_updater isNewerPluginBundleAvailableLocally:_loadedVersion];
		
		if(!newerPluginBundleAvailable) return;
		
		_showedUpdatePromptOnce = true;
		
		[_updater showUpdateRestartPrompt];
		*/
	}


	#pragma mark -
	#pragma mark Plugin Setter

	- (void) setPlugin:(MSPluginBundle*)plugin {
		_plugin = plugin;
		
		NSString *identifier = plugin.identifier;
		
		if(!_loadedVersion){
			_loadedVersion = plugin.version;
		}
		
		_updater.pluginName = plugin.name;
		_updater.pluginIdentifier = identifier;
		
		_userDefaults.pluginIdentifier = identifier;
	}


	#pragma mark -
	#pragma mark Event Subclass Points

	- (void) allDocumentsDidClose {
		//	Empty
	}

	- (void) currentDocumentDidChange:(NSNotification*)notification {
		//	Empty
	}

	- (void) currentSelectionDidChange:(NSNotification*)notification {
		//	Empty
	}

	- (void) currentArtboardDidChange:(NSNotification*)notification {
		//	Empty
	}


	#pragma mark -
	#pragma mark Events

	- (void) windowWillClose:(NSNotification*)notification {
		NSWindow *window = notification.object;
		
		if(![window isKindOfClass:[MSDocumentWindow_Class class]]) return;
		
		BOOL allDocumentsClosed = true;
		
		NSMutableArray *windows = [NSMutableArray arrayWithArray:[NSApp windows]];
		
		[windows removeObject:window];
		
		for(NSWindow *window in windows){
			if(window.class == MSDocumentWindow_Class && window.isVisible){
				allDocumentsClosed = false; break;
			}
		}
		
		if(!allDocumentsClosed) return;
		
		[self allDocumentsDidClose];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:MCSPluginAllDocumentsClosedNotification object:self];
	}

	- (void) windowBecameKeyOrMain:(NSNotification*)notification {
		if(![notification.object isKindOfClass:[MSDocumentWindow_Class class]]) return;
		
		MSDocumentWindow *window = (MSDocumentWindow*)notification.object;
		MSDocument *document = window.windowController.document;
		
		NSDictionary *userInfo = @{
			MCSPluginNotificationDocumentKey: document,
			MCSPluginNotificationDocumentWindowKey: window
		};
		
		NSNotification *dispatchNotification =
			[NSNotification notificationWithName:MCSPluginCurrentDocumentDidChangeNotification object:self userInfo:userInfo];
	
		[self currentDocumentDidChange:dispatchNotification];
	
		[[NSNotificationCenter defaultCenter] postNotification:dispatchNotification];
	}

	- (void) swizzleForEvents {
		static const void *key = &key;
		
		__weak typeof(self) trueSelf = self;
		
		//	Selected Layers Did Change
		
		RSSwizzleInstanceMethod(MSDocument_Class,
			@selector(layerSelectionDidChange),
			RSSWReturnType(void),
			RSSWArguments(),
			RSSWReplacement({
				RSSWCallOriginal();
			
				MSDocument *document = (MSDocument*)self;
				NSDictionary *userInfo = @{
					MCSPluginNotificationDocumentKey: document,
					MCSPluginNotificationDocumentWindowKey: document.window
				};
			
				NSNotification *notification =
					[NSNotification notificationWithName:MCSPluginSelectionDidChangeNotification object:trueSelf userInfo:userInfo];
			
				[trueSelf currentSelectionDidChange:notification];
			
				[[NSNotificationCenter defaultCenter] postNotification:notification];
			}),
			RSSwizzleModeOncePerClassAndSuperclasses,
			key);
		
		//	Current Artboard Did Change
		
		RSSwizzleInstanceMethod(MSDocument_Class,
			@selector(currentArtboardDidChange),
			RSSWReturnType(void),
			RSSWArguments(),
			RSSWReplacement({
				RSSWCallOriginal();
			
				MSDocument *document = (MSDocument*)self;
				NSDictionary *userInfo = @{
					MCSPluginNotificationDocumentKey: document,
					MCSPluginNotificationDocumentWindowKey: document.window
				};
			
				NSNotification *notification =
					[NSNotification notificationWithName:MCSPluginCurrentArtboardDidChangeNotification object:trueSelf userInfo:userInfo];
			
				[[NSNotificationCenter defaultCenter] postNotification:notification];
			}),
			RSSwizzleModeOncePerClassAndSuperclasses,
			key);
	}

@end
