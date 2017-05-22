//
//  Utilities.m
//  MCSketchPluginFramework
//
//  Created by Matt Curtis on 10/2/15.
//  Copyright © 2015 Matt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <JavaScriptCore/JavaScriptCore.h>

#import "Utilities.h"


#pragma mark -
#pragma mark General

Class GetClass(NSString *className){
	return NSClassFromString(className);
};


#pragma mark -
#pragma mark Mocha

JSContext *JSContextOfMochaObject(MOJavaScriptObject *mochaObject){
	JSContext *context = [JSContext contextWithJSGlobalContextRef:(JSGlobalContextRef)mochaObject.JSContext];
	
	return context;
};

JSValue *JSValueFromMochaObject(MOJavaScriptObject *mochaObject){
	JSValue *value = [JSValue valueWithJSValueRef:mochaObject.JSObject inContext:JSContextOfMochaObject(mochaObject)];
	
	return value;
};


#pragma mark -
#pragma mark Text

CGFloat Sketch_GetTextHeight(CGFloat desiredTextWidth, MSTextLayer *textLayer){
	CGFloat formerWidth = textLayer.frame.width;
	
	textLayer.frame.width = desiredTextWidth;
	
	CGFloat height = Sketch_GetTextSize(textLayer).height;
	
	textLayer.frame.width = formerWidth;
	
	return height;
};

CGSize Sketch_GetTextSize(MSTextLayer *textLayer){
	//	Create & size text container

	NSTextContainer *textContainer = [textLayer createTextContainer];

	textContainer.size = CGSizeMake(textLayer.frame.size.width, CGFLOAT_MAX);
	
	//	Create layout manager & text storage

	NSLayoutManager *layoutManager = [textLayer createLayoutManager];
	
	layoutManager.textStorage = [textLayer createTextStorage];
	
	[layoutManager addTextContainer:textContainer];
	
	//	Force update if needed...
	
    [layoutManager glyphRangeForTextContainer:textContainer];
	
    return [layoutManager usedRectForTextContainer:textContainer].size;
};

#pragma mark -
#pragma mark Layer Creation

MSShapeGroup *Sketch_CreateShapeLayer(){
	return (MSShapeGroup*)[[MSLayerGroup_Class new] addLayerOfType:@"rectangle"];
};

MSTextLayer *Sketch_CreateTextLayer(){
	return (MSTextLayer*)[[MSLayerGroup_Class new] addLayerOfType:@"text"];
};


#pragma mark -
#pragma mark Document

MSDocument *Sketch_GetCurrentDocument(){
	MSDocument *document = [MSDocument_Class currentDocument]; //?? //[NSDocumentController sharedDocumentController].currentDocument;
	
	if(!document){
		//	Fallback
		
		for(NSWindow *window in [NSApp windows]){
			if(window.class == MSDocumentWindow_Class && window.isMainWindow){
				document = window.windowController.document; break;
			}
		}
	}
	
	return document;
};


#pragma mark -
#pragma mark Page

MSPage *Sketch_GetCurrentPage(){
	return [Sketch_GetCurrentDocument() currentPage];
};


#pragma mark -
#pragma mark Undo Registration

void Sketch_DisableUndoRegistration(MSDocument *document){
	[(document ?: Sketch_GetCurrentDocument()).undoManager disableUndoRegistration];
};

void Sketch_EnableUndoRegistration(MSDocument *document){
	[(document ?: Sketch_GetCurrentDocument()).undoManager enableUndoRegistration];
};

void Sketch_DisableUndoRegistrationInBlock(MSDocument *document, void(^block)()){
	Sketch_DisableUndoRegistration(document);
	
	block();
	
	Sketch_EnableUndoRegistration(document);
};


#pragma mark -
#pragma mark Selection

NSArray *Sketch_GetSelectedLayers(MSDocument *document){
	return [(document ?: Sketch_GetCurrentDocument()) selectedLayers];
};

NSArray *Sketch_GetSelectedArtboards(MSDocument *document, BOOL linear, BOOL includeCurrentOrOnly){
	NSMutableSet *artboards = [NSMutableSet set];
	NSArray *selection = Sketch_GetSelectedLayers(document);
	
	if(includeCurrentOrOnly){
		MSArtboardGroup *currentArtboard = Sketch_GetCurrentOrOnlyArtboard(document);
		
		if(currentArtboard) [artboards addObject:currentArtboard];
	}
	
	for(MSLayer *layer in selection){
		if(layer.class == MSArtboardGroup_Class){
			[artboards addObject:layer];
		} else if(!linear){
			MSArtboardGroup *parentArtboard = layer.parentArtboard;
			
			if(parentArtboard) [artboards addObject:parentArtboard];
		}
	}
	
	return artboards.allObjects;
};


#pragma mark -
#pragma mark Artboards

MSArtboardGroup *Sketch_GetCurrentArtboard(MSDocument *document){
	return [[(document ?: Sketch_GetCurrentDocument()) currentPage] currentArtboard];
};

MSArtboardGroup *Sketch_GetCurrentOrOnlyArtboard(MSDocument *document){
	document = (document ?: Sketch_GetCurrentDocument());
	
	MSPage *page = document.currentPage;
	MSArtboardGroup *artboard = page.currentArtboard;
	
	if(!artboard && page.artboards.count == 1){
		artboard = page.artboards.firstObject;
	}
	
	return artboard;
};


#pragma mark -
#pragma mark Geometry

CGRect Sketch_MSRectToCGRect(MSRect *rect){
	return rect.rect;
};

NSRect Sketch_MSRectToNSRect(MSRect *rect){
	return NSRectFromCGRect(rect.rect);
};

void Sketch_SetMSRectWithCGRect(MSRect *msrect, CGRect cgrect){
	BOOL constrainProportions = msrect.constrainProportions;
	
	msrect.constrainProportions = false;
	
	msrect.rect = cgrect;
	
	msrect.constrainProportions = constrainProportions;
};

void Sketch_SetMSRectWithNSRect(MSRect *msrect, NSRect nsrect){
	Sketch_SetMSRectWithCGRect(msrect, NSRectToCGRect(nsrect));
};


CGRect Sketch_GetAbsoluteLayerFrame(MSLayer *layer){
	CGRect rect = Sketch_MSRectToCGRect(layer.frame);
	double zoom = layer.parentPage.zoomValue;
	
	rect.size.width = rect.size.width * zoom;
	rect.size.height = rect.size.height * zoom;
	
	return rect;
};

CGRect Sketch_GetLayerFrameInContentDrawView(MSLayer *layer){
	CGRect rect = Sketch_GetAbsoluteLayerFrame(layer);
	
	MSPage *page = layer.parentPage;
	
	double zoom = page.zoomValue;
	CGPoint scrollOrigin = page.scrollOrigin;
	
	rect.origin.x = (rect.origin.x + (scrollOrigin.x / zoom)) * zoom;
	rect.origin.y = (rect.origin.y + (scrollOrigin.y / zoom)) * zoom;
	
	return rect;
};

CGRect Sketch_GetLayerFrameInWindow(MSLayer *layer, MSDocument *document){
	CGRect rect = Sketch_GetLayerFrameInContentDrawView(layer);
	MSContentDrawView *contentDrawView = document.currentView;
	
	rect = [contentDrawView convertRect:rect toView:document.window.contentView];
	
	return rect;
};

CGRect Sketch_GetLayerFrameInScreen(MSLayer *layer, MSDocument *document){
	CGRect rect = Sketch_GetLayerFrameInWindow(layer, document);
	
	rect = [document.window convertRectToScreen:rect];
	
	return rect;
};


#pragma mark -
#pragma mark Layer to Images

NSData *Sketch_GetImageDataFromLayer(MSLayer *layer, double scale){
	MSExportFormat *format = [MSExportFormat_Class formatWithScale:scale name:@"no" fileFormat:@"png"];
	MSExportRequest *request =
		[MSExportRequest_Class exportRequestsFromExportableLayer:layer exportFormats:@[ format ] useIDForName:false].firstObject;
	
	NSColorSpace *colorSpace = [NSColorSpace sRGBColorSpace];
	NSData *imageData = [[MSExporter_Class exporterForRequest:request colorSpace:colorSpace] data];
	
	return imageData;
};

NSImage *Sketch_GetImageFromLayer(MSLayer *layer, double scale){
	NSData *imageData = Sketch_GetImageDataFromLayer(layer, scale);
	NSImage *image = [[NSImage alloc] initWithData:imageData];
	
	return image;
};
