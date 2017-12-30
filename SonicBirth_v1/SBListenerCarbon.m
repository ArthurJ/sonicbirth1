/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBListenerCarbon.h"
#import "SBRootCircuit.h"


@implementation SBListenerCarbon

- (id) initWithCircuit:(SBRootCircuit*)c
{
	self = [super init];
	if (self != nil)
	{
		mWindow = nil;
		mControl = nil;
		mTimers = 0;
		if (c)
		{
			[[NSNotificationCenter defaultCenter]	addObserver:self
													selector:@selector(update:)
													name:kSBElementDidChangeViewNotification
													object:c];
												
			[[NSNotificationCenter defaultCenter]	addObserver:self
													selector:@selector(update:)
													name:kSBElementDidChangeGlobalViewNotification
													object:c];
		}
	}
	return self;
}

- (void) setWindow:(WindowRef)w
{
	mWindow = w;
}

- (void) setControl:(ControlRef)c
{
	mControl = c;
}

- (void) update:(NSNotification *)notification
{
	
#if 0
	if (mWindow)
	{
		Rect windowBounds;
		GetWindowPortBounds(mWindow, &windowBounds);
		InvalWindowRect(mWindow, &windowBounds);
		
//		printf("SBListenerCarbon update window\n");
	}
	
	if (mControl)
	{
		HIViewSetNeedsDisplay(mControl, YES);
	
//		printf("SBListenerCarbon update control\n");
	}
#endif

/*
	WindowRef window = mWindow;
	
	if (!window && mControl)
		window = GetControlOwner(mControl);

	if (window)
	{
		OSStatus err1 = 0, err2 = 0, err3 = 0;
		
		Rect windowBounds;
		GetWindowPortBounds(window, &windowBounds);
		err1 = InvalWindowRect(window, &windowBounds);
		
		HIViewRef view = HIViewGetRoot(window);
		if (view) err2 = HIViewSetNeedsDisplay(view, YES);
		
		if (mControl) err3 = HIViewSetNeedsDisplay(mControl, YES);
		printf("InvalWindowRect called, window: %p view: %p bd: %i %i %i %i err: %i err2: %i err3: %i\n",
				(void*)window,
				(void*)view,
				(int)windowBounds.top,
				(int)windowBounds.left,
				(int)(windowBounds.bottom - windowBounds.top),
				(int)(windowBounds.right - windowBounds.left),
				(int)err1,
				(int)err2,
				(int)err3);
		#warning "remove printf"
	}
*/
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) refresh
{
	if (mTimers > 0) mTimers--;
	[self update:nil];
}

- (void) delayedRefresh
{
//	NSLog(@"delayedRefresh timers %i window %p control %p", mTimers, mWindow, mControl);
	if (!mTimers && (mWindow || mControl))
	{
		mTimers++;
		[self performSelector:@selector(refresh) withObject:nil afterDelay:(1. / 20.)];
	}	
}

@end
