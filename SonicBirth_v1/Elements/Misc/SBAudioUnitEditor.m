/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
// ============================================================================================
// from http://www.cocoadev.com/index.pl?AudioUnitEditorWindow (Jeremy Jurksztowicz)

#import "SBAudioUnitEditor.h"
#import <AudioUnit/AUCocoaUIView.h>

#import <AudioUnit/AudioUnitCarbonView.h>

// ============================================================================================
// Carbon implementation from code at http://www.mat.ucsb.edu:8000/CoreAudio by Chris Reed.

// ============================================================================================
@interface SBAudioUnitEditor(SBAudioUnitEditorPrivate)
- (void) _error:(NSString*)errString status:(OSStatus)err;
- (void) windowWillClose:(NSNotification *)aNotification;
@end

static OSStatus WindowClosedHandler (EventHandlerCallRef myHandler, EventRef theEvent, void* userData)
{
        SBAudioUnitEditor* me = (SBAudioUnitEditor*)userData;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
        [me windowWillClose:nil];
        
		if (pool) [pool release];
		return noErr;
}

// ============================================================================================
@implementation SBAudioUnitEditor
// --------------------------------------------------------------------------------------------
- (void) _error:(NSString*)errString status:(OSStatus)err
{
	NSString * errorString = [NSString stringWithFormat:@"%@ failed; %i / %.4s", errString, err, (char*)&err];
	// We just send error to console, do what you will with it.
	NSLog(errorString);
}

// --------------------------------------------------------------------------------------------
- (ComponentDescription) initializeEditViewComponentDescription:(BOOL)forceGeneric;
{
	OSStatus err;

	ComponentDescription editUnitCD;

	// set up to use generic UI component
	editUnitCD.componentType = kAudioUnitCarbonViewComponentType;
	editUnitCD.componentSubType = 'gnrc';
	editUnitCD.componentManufacturer = 'appl';
	editUnitCD.componentFlags = 0;
	editUnitCD.componentFlagsMask = 0;

	if (forceGeneric) return editUnitCD;

	UInt32 propertySize;
	err = AudioUnitGetPropertyInfo(
			mEditUnit, kAudioUnitProperty_GetUIComponentList, 
			kAudioUnitScope_Global, 0, &propertySize, NULL);

	// An error occured so we will just have to use the generic control.
	if(err != noErr)
	{
//		NSLog(@"Error setting up carbon interface, falling back to generic interface.");
		return editUnitCD;
	}

	ComponentDescription *editors = (ComponentDescription*) malloc(propertySize);
	err = AudioUnitGetProperty(
			mEditUnit, kAudioUnitProperty_GetUIComponentList, kAudioUnitScope_Global,
			0, editors, &propertySize);

	if(err == noErr)
			editUnitCD = editors[0]; // We just pick the first one. Select whatever you like.

	free(editors);
	
	return editUnitCD;
}
// --------------------------------------------------------------------------------------------
+ (BOOL) pluginClassIsValid:(Class)pluginClass 
{
	if([pluginClass conformsToProtocol: @protocol(AUCocoaUIBase)])
	{
		if(	[pluginClass instancesRespondToSelector: @selector(interfaceVersion)] &&
			[pluginClass instancesRespondToSelector: @selector(uiViewForAudioUnit:withSize:)])
			return YES;
	}
    return NO;
}

- (NSView *) createCocoaView
{
	NSView *theView = nil;
	UInt32 dataSize = 0;
	Boolean isWritable = 0;
	OSStatus err = AudioUnitGetPropertyInfo(mEditUnit,
			kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global, 
			0, &dataSize, &isWritable);

	if(err != noErr)
			return nil;

	// If we have the property, then allocate storage for it.
	AudioUnitCocoaViewInfo * cvi = (AudioUnitCocoaViewInfo*)malloc(dataSize);
	err = AudioUnitGetProperty(mEditUnit, 
			kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global, 0, cvi, &dataSize);

	// Extract useful data.
	unsigned numberOfClasses = (dataSize - sizeof(CFURLRef)) / sizeof(CFStringRef);
	NSString * viewClassName = (NSString*)(cvi->mCocoaAUViewClass[0]);
	NSString * path = (NSString*)(CFURLCopyPath(cvi->mCocoaAUViewBundleLocation));
	NSBundle * viewBundle = [NSBundle bundleWithPath:[path autorelease]];
	Class viewClass = [viewBundle classNamed:viewClassName];

	if([SBAudioUnitEditor pluginClassIsValid:viewClass])
	{
		id factory = [[[viewClass alloc] init] autorelease];
		theView = [factory uiViewForAudioUnit:mEditUnit withSize:NSMakeSize(400, 300)];
	}

	// Delete the cocoa view info stuff.
	if(cvi)
	{
        int i;
        for(i = 0; i < numberOfClasses; i++)
            CFRelease(cvi->mCocoaAUViewClass[i]);

        CFRelease(cvi->mCocoaAUViewBundleLocation);
        free(cvi);
    }

	return theView;
}

// --------------------------------------------------------------------------------------------
- (WindowRef) createCarbonWindow:(ComponentDescription) editUnitCD
{
#if 0
	Component editComponent = FindNextComponent(NULL, &editUnitCD);
	
	AudioUnitCarbonView editView;
	OpenAComponent(editComponent, &editView);
	if (!editView) return nil;
	
	WindowRef carbonWindow;

	Rect bounds = { 100, 100, 200, 200 }; // Generic resized later
	OSStatus res = CreateNewWindow(kFloatingWindowClass, 
			kWindowCloseBoxAttribute | kWindowCollapseBoxAttribute | kWindowStandardHandlerAttribute
			/* | kWindowCompositingAttribute */ | kWindowSideTitlebarAttribute, &bounds, &carbonWindow);

	if(res != noErr)
	{
		[self _error:@"Create new carbon window" status:res];
		return nil;
	}
	
	// create the edit view
	ControlRef rootControl;
	res = GetRootControl(carbonWindow, &rootControl);
	if (!rootControl)
		res = CreateRootControl(carbonWindow, &rootControl);
	
	if (!rootControl)
	{
		[self _error:@"Get root control of carbon window" status:res];
		// free window
		return nil;
	}
	
	GetControlBounds(rootControl, &bounds);
	
	Float32Point loc  = { 0.f, 0.f };
	Float32Point size = { bounds.right, bounds.bottom } ;
	
	ControlRef viewPane;
	res = AudioUnitCarbonViewCreate(editView, mEditUnit, carbonWindow, 
			rootControl, &loc, &size, &viewPane);
	if (res != noErr)
	{
		[self _error:@"AudioUnitCarbonViewCreate" status:res];
		// free window
		return nil;
	}

	// resize and move window
	GetControlBounds(viewPane, &bounds);
	size.x = bounds.right - bounds.left;
	size.y = bounds.bottom - bounds.top;
	
	if (size.x > 0 && size.y > 0)
	{
		SizeWindow(carbonWindow, (short) (size.x + 0.5), (short) (size.y + 0.5),  YES);
		RepositionWindow(carbonWindow, NULL, kWindowCenterOnMainScreen);
	}
	
	EventTypeSpec eventList[] = {{kEventClassWindow, kEventWindowClose}};   
	EventHandlerUPP handlerUPP = NewEventHandlerUPP(WindowClosedHandler);

	OSStatus err = InstallWindowEventHandler(
                carbonWindow, handlerUPP, GetEventTypeCount(eventList), eventList, self, NULL);
	if(err != noErr) 
	{
		[self _error: @"Install close window handler" status: err];
		return nil;
	}
	
	return carbonWindow;
#else
	return 0;
#endif
}

// --------------------------------------------------------------------------------------------
- (void) windowWillClose:(NSNotification *)aNotification
{
	if (mDelegate) [mDelegate performSelector:@selector(audioUnitEditorClosed:) withObject:self afterDelay:0];
}

- (void) show
{
	[mWindow makeKeyAndOrderFront:nil];
}

// --------------------------------------------------------------------------------------------
- (id) initWithAudioUnit: (AudioUnit) unit forceGeneric: (BOOL) forceGeneric delegate: (id) delegate
{
	self = [super init];
	if (!self) return nil;

	mEditUnit = unit;
	mDelegate = delegate;


	NSView *view = [self createCocoaView];
	if (view)
	{
		mWindow = [[NSWindow alloc]
					initWithContentRect: NSMakeRect(100, 400, [view frame].size.width, [view frame].size.height)
					styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
					backing: NSBackingStoreBuffered
					defer:NO];
		if (!mWindow)
		{
			[self release];
			return nil;
		}
		
		[mWindow setContentView:view];
		
		[mWindow setIsVisible:YES];
		[mWindow center];
		[mWindow setDelegate:self];
		[mWindow setReleasedWhenClosed:NO];
		
		return self;
	}


	WindowRef window = [self createCarbonWindow:[self initializeEditViewComponentDescription:forceGeneric]];
	if (window)
	{
		// create the cocoa window for the carbon one and make it visible.
		mWindow = [[NSWindow alloc] initWithWindowRef:window];
		if (!mWindow)
		{
			[self release];
			return nil;
		}
		
		[mWindow setIsVisible:YES];
		[mWindow center];
		[mWindow setDelegate:self];
		[mWindow setReleasedWhenClosed:NO];

		return self;
	}

	[self release];
	return nil;
}

- (void) dealloc
{
	if (mWindow) [mWindow release];
	[super dealloc];
}

@end
