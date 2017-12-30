/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBRuntimeView.h"
#import "SBRootCircuit.h"

@implementation SBRuntimeView

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame pixelFormat:[NSOpenGLView defaultPixelFormat]]))
	{
		mCircuit = nil;
		mLastX = mLastY = 0;
		mW = nil;
		mTimers = 0;
	}
	return self;
}

- (void)prepareOpenGL
{
	if (!mW) mW = ogInit();
}

- (void) reshape
{
	NSRect r = [self bounds];
	ogSetShape(0, 0, r.size.width, r.size.height);
}


- (BOOL) isFlipped
{
	return YES;
}

- (BOOL) isOpaque
{
	return YES;
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void) dealloc
{	
	ogRelease(mW);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) setCircuit:(SBRootCircuit*)circuit
{
//	NSLog(@"setCircuit %p", circuit);
	mCircuit = circuit;
	assert(mCircuit);
	
	[[NSNotificationCenter defaultCenter]	addObserver:self
											selector:@selector(circuitDidChangeView:)
											name:kSBElementDidChangeViewNotification
											object:mCircuit];
											
	[[NSNotificationCenter defaultCenter]	addObserver:self
											selector:@selector(circuitDidChangeGlobalView:)
											name:kSBElementDidChangeGlobalViewNotification
											object:mCircuit];
	
	[mCircuit setGuiMode:kRuntime];
	[mCircuit setActsAsCircuit:YES];
	
	NSRect frame = [self frame];
	frame.size = [mCircuit circuitMinSize];
	
	[mCircuit setCircuitSize:frame.size];
	[self setFrame:frame];
}

- (void) drawRect:(NSRect)rect
{
	[self reshape];
	BOOL constantRefresh = NO;
	
	
	ogBeginDrawing(mW);
	ogClearBuffer();
	if (mCircuit)
	{
		[mCircuit drawRect:rect];
		constantRefresh = [mCircuit constantRefresh];
	}
	ogEndDrawing(1);
	
	if (constantRefresh)
		[self delayedRefresh];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (![self mouse:ml inRect:[self bounds]]) { [super mouseDown:theEvent]; return; }

	int clicks = [theEvent clickCount];
	
	BOOL isOK = [mCircuit mouseDownX:ml.x Y:ml.y clickCount:clicks];
	if (isOK) [self setNeedsDisplay:YES];

	mLastX = ml.x;
	mLastY = ml.y;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	// if (![self mouse:ml inRect:[self bounds]]) { [super mouseDragged:theEvent]; return; }

	BOOL isOK = [mCircuit mouseDraggedX:ml.x Y:ml.y lastX:mLastX lastY:mLastY];
	if (isOK) [self setNeedsDisplay:YES];

	mLastX = ml.x;
	mLastY = ml.y;
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	// if (![self mouse:ml inRect:[self bounds]]) { [super mouseUp:theEvent]; return; }

	BOOL isOK = [mCircuit mouseUpX:ml.x Y:ml.y];
	if (isOK) [self setNeedsDisplay:YES];
	
	mLastX = ml.x;
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSString *utf16 = [theEvent characters];
	unichar  ukey = [utf16 characterAtIndex:0];
	
	if (ukey == ' ')
	{
		// [gSoundServer pushedPlayButton:nil];
		return [super keyDown:theEvent];
	}
	
	BOOL isOK = [mCircuit keyDown:ukey];
	if (isOK) [self setNeedsDisplay:YES];
}

- (void) circuitDidChangeView:(NSNotification *)notification
{
	SBElement *e = [notification object];
	NSDictionary *d = [notification userInfo];
	if (d)
	{
		SBElement *e2 = [d objectForKey:@"object"];
		if (e2) e = e2;
	}
	if (e == mCircuit)
		[self setNeedsDisplay:YES];
	else
		[self setNeedsDisplayInRect:[e frame]];
	[self setNeedsDisplayInRect:[e frame]];
}

- (void) circuitDidChangeGlobalView:(NSNotification *)notification
{
	[self setNeedsDisplay:YES];
}

- (void) refresh
{
	if (mTimers > 0) mTimers--;
	[self setNeedsDisplay:YES];
}

- (void) delayedRefresh
{
//	NSLog(@"delayedRefresh timers %i window %p control %p", mTimers, mWindow, mControl);
	if (!mTimers)
	{
		mTimers++;
		[self performSelector:@selector(refresh) withObject:nil afterDelay:(1. / 20.)];
	}	
}

@end
