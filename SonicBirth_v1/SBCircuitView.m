/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#include <sys/time.h>
#import <OpenGL/gl.h>
#import <OpenGL/CGLRenderers.h>

#import "SBCircuitView.h"
#import "SBElementServer.h"
//#import "SBSoundServer.h"

#import "SBSlider.h"
#import "SBBoolean.h"
#import "SBIndexed.h"

#import "SBCircuitDocument.h"
#import "SBPreferenceServer.h"

@implementation SBCircuitView

- (id) initWithFrame:(NSRect)frame
{
	/*
	NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFARendererID, kCGLRendererGenericID,
		NSOpenGLPFADepthSize, 32,
		nil
	};

    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

	if (pf) printf("using soft. renderer\n");

	if ((self = [super initWithFrame:frame pixelFormat: ((pf) ? pf : [NSOpenGLView defaultPixelFormat]) ]))
	*/

	if ((self = [super initWithFrame:frame pixelFormat:[NSOpenGLView defaultPixelFormat]]))
	{
		mLevels = [[NSMutableArray alloc] init];
		if (!mLevels)
		{
			[self release];
			return nil;
		}

		mReleaseArray = [[NSMutableArray alloc] init];
		if (!mReleaseArray)
		{
			[self release];
			return nil;
		}

		mW = nil;
		mTimers = 0;

		mMenu = nil;

		[self registerForDraggedTypes:[NSArray arrayWithObjects:@"SBElementName", NSFilenamesPboardType, nil]];
    }

	// if (pf) [pf release];
    return self;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
// Before files were applicable:
// return NSDragOperationGeneric;
	NSPasteboard * pasteboard = [sender draggingPasteboard];
	if (pasteboard == nil)
		{ return NSDragOperationNone; }
	
	NSArray * types = [pasteboard types];
	if (types == nil)
		{ return NSDragOperationNone; }	
	if ([types count] < 1)
		{ return NSDragOperationNone; }	

	if ([types containsObject:@"SBElementName"])
		{ return NSDragOperationCopy; }
	else if ([types containsObject:NSFilenamesPboardType])
		{ return NSDragOperationCopy; }
	return NSDragOperationNone;
}

#warning Antoine, do you see any danger in this approach? (The archiving system may not have been designed for this)

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard * pasteboard = [sender draggingPasteboard];
	if (pasteboard == nil)
		{ return NO; }

	NSArray * types = [pasteboard types];
	if (types == nil)
		{ return NO; }
	
	NSPoint pt = [self convertPoint:[sender draggingLocation] fromView:nil];
	
	if ([types containsObject:@"SBElementName"])
		{ return [self insertElementWithName:[pasteboard stringForType:@"SBElementName"] atPosition:pt positionElement:YES]; }
	else if ([types containsObject:NSFilenamesPboardType])
	{
		NSArray * files = [pasteboard propertyListForType:NSFilenamesPboardType];

		int idx;
		for (idx = 0; idx < [files count]; idx++)
		{
			if ([self importCircuitAtPath:[files objectAtIndex:idx] atPosition:pt positionElement:YES])
				{ pt.x += 13.f; pt.y += 13.f; }
		}
		return YES;
	}
	return YES;
}

- (void)prepareOpenGL
{
	if (!mW) mW = ogInit();
}

- (void) reshape
{
	NSClipView *clipView = (NSClipView *)[self superview];
	NSScrollView *scrollView = (NSScrollView *)[clipView superview];

	NSRect f = [scrollView documentVisibleRect];
	NSSize s = [self bounds].size;

	if (f.size.height > s.height) f.size.height = s.height;

	//NSLog(@"Reshape called with x:%f y:%f w:%f h:%f ow: %f oh: %f",
	//	f.origin.x, f.origin.y, f.size.width, f.size.height, s.width, s.height);

	ogSetShape(-f.origin.x, f.origin.y - (s.height - f.size.height), s.width, s.height);
}

- (void) dealloc
{
	ogRelease(mW);

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (mMenu) [mMenu release];

	if (mInfoServer)  { [mInfoServer setString:@""]; [mInfoServer release]; }
	if (mSettingsServer)  { [mSettingsServer setSettingsView:nil]; [mSettingsServer release]; }

	if (mLevels) [mLevels release];
	if (mReleaseArray) [mReleaseArray release];
	[super dealloc];
}

- (void) awakeFromNib
{
	//[super awakeFromNib];

	if (mWindow) [mWindow setDelegate:self];

	[[NSNotificationCenter defaultCenter] addObserver:self
				selector:@selector(elementPopUpWillShow:)
				name:NSPopUpButtonWillPopUpNotification
				object:mElementsPopUp];

	if (!mInfoServer) mInfoServer = [SBInfoServer lastServer];
	if (!mSettingsServer) mSettingsServer = [SBSettingsServer lastServer];

	if (mInfoServer) [mInfoServer retain];
	if (mSettingsServer) [mSettingsServer retain];
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

- (void) drawRect:(NSRect)rect
{
	//struct timeval t1, t2;
	//gettimeofday(&t1, nil);

	// - - - - - - - - -
	[self reshape];

	ogBeginDrawing(mW);
	ogSetClearColor(gBackgroundColor[0], gBackgroundColor[1], gBackgroundColor[2], 1);
	ogClearBuffer();

	if (mCurCircuit) [mCurCircuit drawRect:rect];

	if (mLasso)
	{
		float x = (mLassoStart.x < mLassoEnd.x) ? mLassoStart.x : mLassoEnd.x;
		float y = (mLassoStart.y < mLassoEnd.y) ? mLassoStart.y : mLassoEnd.y;
		float w = (mLassoStart.x > mLassoEnd.x) ? mLassoStart.x - mLassoEnd.x : mLassoEnd.x - mLassoStart.x;
		float h = (mLassoStart.y > mLassoEnd.y) ? mLassoStart.y - mLassoEnd.y : mLassoEnd.y - mLassoStart.y;

		ogSetColorIndex(ogBlack);
		ogStrokeRectangle(x, y, w, h);
	}

	ogEndDrawing(1);

	//ogEndDrawing(0);
	//[[self openGLContext] flushBuffer];
	// - - - - - - - - -

	//gettimeofday(&t2, nil);
	//double ms = (t2.tv_sec - t1.tv_sec) * 1000. + (t2.tv_usec - t1.tv_usec) / 1000.;
	//NSLog(@"draw time: %.2f milliseconds", ms);

	if (!mTimers && mCurCircuit && [mCurCircuit constantRefresh])
	{
		mTimers++;
		[self performSelector:@selector(refresh) withObject:nil afterDelay:(1. / 20.)];
	}
}

- (void) refresh
{
	if (mTimers > 0) mTimers--;
	[self setNeedsDisplay:YES];
}

- (void) setRootCircuit:(SBRootCircuit*)c
{
	mRootCircuit = c;
	mCurCircuit = c;
	[mLevels removeAllObjects];
	[mCurrentLevel setIntValue:0];
	[mPrevLevel setEnabled:NO];
	[mNextLevel setEnabled:NO];
	mGuiMode = [mRootCircuit guiMode] != kCircuitDesign;
	[mMini setEnabled:!mGuiMode];
	[mMini setState:([mRootCircuit miniMode] ? NSOnState : NSOffState)];
	[self updateCurCircuit];
	[self circuitDidChangeView:nil];
}

- (IBAction) insertElement:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]])
	{
		NSMenuItem *item = sender;
		// NSLog(@"item: %@", item);

		NSMenu *menu = [item menu], *smenu = [menu supermenu];
		// NSLog(@"menu: %@", menu);

		while(smenu) { menu = smenu; smenu = [menu supermenu]; }

		NSString *name = [item title];
		// NSLog(@"insertElement: %@", name);

		SBElement *e = [gElementServer createElement:name];
		if (e)
		{
			if (menu == mMenu) [e setOriginX:mLastX Y:mLastY];
			else [e setOriginX:100 Y:100];

			if (mParent) [mParent undoMark];

			[mCurCircuit addElement:e];

			[self updateForSelectedElement:[mCurCircuit selectedElement]];
			[self setNeedsDisplay:YES];
		}
	}
}

- (void) elementPopUpWillShow:(NSNotification *)notification
{
	[gElementServer fillMenu:[mElementsPopUp menu] target:self action:@selector(insertElement:)];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	if (mGuiMode) return;

	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (![self mouse:ml inRect:[self bounds]]) { [super mouseDown:theEvent]; return; }

	mLastX = ml.x;
	mLastY = ml.y;

	if (mMenu) [mMenu release];
	mMenu = [[NSMenu alloc] init];
	if (!mMenu) return;

	[gElementServer fillMenu:mMenu target:self action:@selector(insertElement:)];

	[NSMenu popUpContextMenu:mMenu
			withEvent:theEvent
			forView:self
			withFont:[NSFont fontWithName:@"Lucida Grande" size:10]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	mLasso = NO;

	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (![self mouse:ml inRect:[self bounds]]) { [super mouseDown:theEvent]; return; }

	if (mParent) [mParent snapShot];

	int clicks = [theEvent clickCount];
	unsigned int flags = [theEvent modifierFlags];
	BOOL isOK = [mCurCircuit mouseDownX:ml.x Y:ml.y clickCount:clicks flags:flags];
	if (isOK) [self setNeedsDisplay:YES];
	else if (clicks == 2)
	{
		int idx;

		idx = [mCurCircuit inputNameForX:ml.x Y:ml.y];
		if (idx >= 0)
		{
			NSString *newName = [self newStringForDescription:@"New input name:"
													oldString:[mCurCircuit nameOfInputAtIndex:idx]];
			[mCurCircuit changeInputName:idx newName:newName];
			[self setNeedsDisplay:YES];
			if (mParent) [mParent undoMark];
		}

		idx = [mCurCircuit outputNameForX:ml.x Y:ml.y];
		if (idx >= 0)
		{
			NSString *newName = [self newStringForDescription:@"New output name:"
													oldString:[mCurCircuit nameOfOutputAtIndex:idx]];
			[mCurCircuit changeOutputName:idx newName:newName];
			[self setNeedsDisplay:YES];
			if (mParent) [mParent undoMark];
		}
	}


	if (clicks == 1 && ![mCurCircuit selectedElement] && ![mCurCircuit creatingWire] && ![mCurCircuit selectedWire])
	{
		if (!mGuiMode && !(flags & NSAlternateKeyMask))
		{
			mLasso = YES;
			mLassoStart = mLassoEnd = ml;
		}
	}

	mLastX = ml.x;
	mLastY = ml.y;

	[self updateForSelectedElement:[mCurCircuit selectedElement]];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	// if (![self mouse:ml inRect:[self bounds]]) { [super mouseDragged:theEvent]; return; }

	if (mLasso)
	{
		mLassoEnd = ml;
		[self setNeedsDisplay:YES];
		return;
	}

	BOOL isOK = [mCurCircuit mouseDraggedX:ml.x Y:ml.y lastX:mLastX lastY:mLastY];
	if (isOK) [self setNeedsDisplay:YES];
	else
	{
		NSPoint pt = [self visibleRect].origin;

		pt.y += mLastY - ml.y;
		pt.x += mLastX - ml.x;

		[self scrollPoint:pt];
		ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	}

	mLastX = ml.x;
	mLastY = ml.y;
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	// if (![self mouse:ml inRect:[self bounds]]) { [super mouseUp:theEvent]; return; }

	if (mLasso)
	{
		mLasso = NO;

		NSRect rect = { {
		(mLassoStart.x < mLassoEnd.x) ? mLassoStart.x : mLassoEnd.x,
		(mLassoStart.y < mLassoEnd.y) ? mLassoStart.y : mLassoEnd.y } , {
		(mLassoStart.x > mLassoEnd.x) ? mLassoStart.x - mLassoEnd.x : mLassoEnd.x - mLassoStart.x,
		(mLassoStart.y > mLassoEnd.y) ? mLassoStart.y - mLassoEnd.y : mLassoEnd.y - mLassoStart.y } };

		[mCurCircuit selectRect:rect];

		[self setNeedsDisplay:YES];
		return;
	}

	if (mParent && [mCurCircuit creatingWire]) [mParent snapShotMark];

	BOOL isOK = [mCurCircuit mouseUpX:ml.x Y:ml.y];
	if (isOK) [self setNeedsDisplay:YES];

	mLastX = ml.x;
	mLastY = ml.y;
}
/*
- (void)scrollWheel:(NSEvent *)theEvent
{
	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSLog(@"ml.x: %f ml.y: %f deltaX: %f deltaY: %f deltaZ: %f",
				ml.x, ml.y,
				[theEvent deltaX],
				[theEvent deltaY],
				[theEvent deltaZ]);
}
*/
- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSString *utf16 = [theEvent characters];
	unichar  ukey = [utf16 characterAtIndex:0];

	if (ukey == ' ')
	{
		//[gSoundServer pushedPlayButton:nil];
		[super keyDown:theEvent];
		return;
	}

	if ([mCurCircuit selectedElement] && (ukey == NSDeleteFunctionKey || ukey == 0x7F) && !mGuiMode && mParent)
		[mParent undoMark];

	BOOL isOK = [mCurCircuit keyDown:ukey];
	if (isOK) [self setNeedsDisplay:YES];

	[self updateForSelectedElement:[mCurCircuit selectedElement]];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[self updateForSelectedElement:[mCurCircuit selectedElement]];
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	[self updateForSelectedElement:[mCurCircuit selectedElement]];
}


- (void) updateForSelectedElement:(SBElement*)e
{
	if (e)
	{

		//NSString *infos = [NSString stringWithFormat:@"%@: %@", [[e class] name], [e informations]];

		NSMutableString *infos = [NSMutableString stringWithCapacity:200];
		[infos appendString:[NSString stringWithFormat:@"%@: %@", [[e class] name], [e informations]]];

		int inputs = [e numberOfInputs];
		int outputs = [e numberOfOutputs];
		int i;

		if (inputs)
		{
			[infos appendString:@"\n\nInputs : "];
			[infos appendString:[e nameOfInputAtIndex:0]];
			for (i = 1; i < inputs; i++)
			{
				[infos appendString:@", "];
				[infos appendString:[e nameOfInputAtIndex:i]];
			}
			[infos appendString:@"."];
		}

		if (outputs)
		{
			[infos appendString:@"\n\nOutputs : "];
			[infos appendString:[e nameOfOutputAtIndex:0]];
			for (i = 1; i < outputs; i++)
			{
				[infos appendString:@", "];
				[infos appendString:[e nameOfOutputAtIndex:i]];
			}
			[infos appendString:@"."];
		}

		[mInfoServer setString:infos];

		[mSettingsServer setSettingsView:[e settingsView]];
		SBCircuit *c = [e subCircuit];
		if (c && c != mCurCircuit && !mGuiMode)
			[mNextLevel setEnabled:YES];
		else
			[mNextLevel setEnabled:NO];
	}
	else
	{
		[mNextLevel setEnabled:NO];
		[mInfoServer setString:@""];
		[mSettingsServer setSettingsView:[mCurCircuit settingsView]];
	}
}

- (void) reselect
{
	if (mCurCircuit) [self updateForSelectedElement:[mCurCircuit selectedElement]];
}

- (void) updateCurCircuit
{
	[mCurCircuit setActsAsCircuit:YES];
	[mCurCircuit setMiniMode:[mMini state] == NSOnState];

	[self setFrame:[self frame]];

	[self updateForSelectedElement:[mCurCircuit selectedElement]];

	// change view
	// remove
	[[NSNotificationCenter defaultCenter] removeObserver:self
					name:kSBElementDidChangeViewNotification
					object:nil];

	[[NSNotificationCenter defaultCenter] removeObserver:self
					name:kSBElementDidChangeGlobalViewNotification
					object:nil];

	// add
	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(circuitDidChangeView:)
					name:kSBElementDidChangeViewNotification
					object:mCurCircuit];

	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(circuitDidChangeGlobalView:)
					name:kSBElementDidChangeGlobalViewNotification
					object:mCurCircuit];

	// change size
	[[NSNotificationCenter defaultCenter] removeObserver:self
					name:kSBCircuitDidChangeMinSizeNotification
					object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(circuitDidChangeMinSize:)
					name:kSBCircuitDidChangeMinSizeNotification
					object:mCurCircuit];

	[self setNeedsDisplay:YES];
}

- (IBAction) prevLevel:(id)sender
{
	int level = [mLevels count] - 1;
	[mLevels removeObjectAtIndex:level];
	[mCurrentLevel setIntValue:level];

	[mCurCircuit setActsAsCircuit:NO];
	[mNextLevel setEnabled:NO];
	if (level > 0)
	{
		[mPrevLevel setEnabled:YES];
		mCurCircuit = [mLevels objectAtIndex:level - 1];
	}
	else
	{
		[mPrevLevel setEnabled:NO];
		mCurCircuit = mRootCircuit;
	}

	[self updateCurCircuit];
}

- (IBAction) nextLevel:(id)sender
{
	SBElement *e = [mCurCircuit selectedElement];
	SBCircuit *c = [e subCircuit];
	if (c && c != mCurCircuit)
	{
		[mLevels addObject:c];
		[mCurrentLevel setIntValue:[mLevels count]];

		[mPrevLevel setEnabled:YES];
		[mNextLevel setEnabled:NO];

		mCurCircuit = c;
		[self updateCurCircuit];
	}
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
	if (e == mCurCircuit)
		[self setNeedsDisplay:YES];
	else
		[self setNeedsDisplayInRect:[e frame]];
}

- (void) circuitDidChangeGlobalView:(NSNotification *)notification
{
	[self setNeedsDisplay:YES];
	[self updateForSelectedElement:[mCurCircuit selectedElement]];
	if (mCurCircuit == mRootCircuit)
	{
		mGuiMode = [mRootCircuit guiMode] != kCircuitDesign;
		if (mGuiMode)
		{
			[mNextLevel setEnabled:NO];

			[mMini setEnabled:NO];
			[mElementsPopUp setEnabled:NO];
		}
		else
		{
			[mMini setEnabled:YES];
			[mElementsPopUp setEnabled:YES];
		}
	}
}

- (void) circuitDidChangeMinSize:(NSNotification *)notification
{
	[self setFrame:[self frame]];
	[self setNeedsDisplay:YES];
}

- (void)setFrame:(NSRect)frameRect
{
//	NSLog(@"setFrame w: %i h: %i", (int)frameRect.size.width, (int)frameRect.size.height);

	BOOL minIsMax = (mCurCircuit == mRootCircuit) ? [mRootCircuit minSizeIsMaxSize] : NO;
	NSSize size = [mCurCircuit circuitMinSize];
	NSView *superView = [self superview];
	NSRect f = [superView frame];

	if (minIsMax)
	{
		f.size.width = size.width;
		f.size.height = size.height;
	}
	else
	{
		if (f.size.width < size.width) f.size.width = size.width;
		if (f.size.height < size.height) f.size.height = size.height;
	}

	[mCurCircuit setCircuitSize:f.size];

	[super setFrame:f];
}

- (IBAction) setMinSizeToCurrentSize:(id)sender
{
	if (mParent) [mParent undoMark];

	[mCurCircuit setCircuitMinSize:[[self superview] frame].size];
}

- (void) selectAll:(id)sender
{
	if (mCurCircuit)
	{
		[mCurCircuit selectAll];
		[self updateForSelectedElement:[mCurCircuit selectedElement]];
		[self setNeedsDisplay:YES];
	}
}

- (void) delete:(id)sender
{
	unichar ukey = NSDeleteFunctionKey;

	if ([mCurCircuit selectedElement] && (ukey == NSDeleteFunctionKey || ukey == 0x7F) && !mGuiMode && mParent)
		[mParent undoMark];

	BOOL isOK = [mCurCircuit keyDown:ukey];
	if (isOK) [self setNeedsDisplay:YES];

	[self updateForSelectedElement:[mCurCircuit selectedElement]];
}

- (void) cut:(id)sender
{
	NSArray *a = [mCurCircuit selectedElements];

	[self copy:sender];

	if (!a) return; // can't cut circuit

	while(a)
	{
		[mCurCircuit removeElement:[a objectAtIndex:0]];
		a = [mCurCircuit selectedElements];
	}

	[self setNeedsDisplay:YES];
}

- (void) duplicate:(id)sender
{
	[self copy:sender];
	[self paste:sender];
}

- (void) copy:(id)sender
{
	NSArray *e = [mCurCircuit selectedElements];
	NSArray *w = [mCurCircuit selectedWires];

	if (!e) e = [NSArray arrayWithObject:mCurCircuit];

	NSArray *se = [SBCircuitView saveElements:e]; if (!se) return;
	NSArray *sw = (w) ? [SBCircuitView saveWires:w elements:e] : nil;
	NSArray *sa = [NSArray arrayWithObjects:se, sw, nil];

	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization
						dataFromPropertyList:sa
						format:NSPropertyListXMLFormat_v1_0
						errorDescription:&error];

	if (data && !error)
	{
		NSPasteboard* pboard = [NSPasteboard generalPasteboard];
		[pboard declareTypes:[NSArray arrayWithObject:@"SBElement"] owner:nil];
		[pboard setData:data forType:@"SBElement"];
	}
	else
	{
		NSLog(@"Error while serializing: %@", error);
		// [error release];
	}
}

- (void) paste:(id)sender
{
	NSPasteboard* pboard = [NSPasteboard generalPasteboard];
	NSData *data = [pboard dataForType:@"SBElement"];

	if (data)
	{
		NSString *error = nil;
		NSArray *a = [NSPropertyListSerialization
						propertyListFromData:data
						mutabilityOption:NSPropertyListImmutable
						format:nil
						errorDescription:&error];
		if (a && !error)
		{
			int c = [a count];
			NSArray *sa = (c > 0) ? [a objectAtIndex:0] : nil;
			NSArray *sw = (c > 1) ? [a objectAtIndex:1] : nil;
			NSArray *le = [SBCircuitView loadElements:sa];
			NSArray *lw = [SBCircuitView loadWires:sw elements:le];
			if (le)
			{
				int i, c = [le count];
				for (i = 0; i < c; i++)
					[mCurCircuit addElement:[le objectAtIndex:i]];

				if (lw)
				{
					c = [lw count];
					for (i = 0; i < c; i++)
						[mCurCircuit addWire:[lw objectAtIndex:i]];
				}
			}
			[self setNeedsDisplay:YES];
		}
		else
		{
			NSLog(@"Error while deserializing: %@", error);
			// [error release];
		}
	}
}

+ (NSDictionary*) saveElement:(SBElement*)e
{
	if (!e) return nil;
	if ([e category] == kInternal) return nil;

	NSMutableDictionary *mde = [[[NSMutableDictionary alloc] init] autorelease];
	if (!mde) return nil;

	NSString *name = [[e className] copy];
		[mde setObject:name forKey:@"class"];
	[name release];

	NSPoint dorigin = [e designOrigin];

	NSNumber *n = [NSNumber numberWithFloat:dorigin.x];
	[mde setObject:n forKey:@"originX"];

	n = [NSNumber numberWithFloat:dorigin.y];
	[mde setObject:n forKey:@"originY"];

	NSDictionary *d = [e saveData];
	if (d) [mde setObject:d forKey:@"settings"];

	return mde;
}

+ (SBElement*) loadElement:(NSDictionary*)d
{
	if (!d) return nil;

	NSString *s = [d objectForKey:@"class"];
	if (s)
	{
		SBElement *e = [gElementServer createElement:s];
		if (e)
		{
			float x = 100, y = 100;
			NSNumber *n = [d objectForKey:@"originX"];
			if (n)
				x = [n floatValue];

			n = [d objectForKey:@"originY"];
			if (n)
				y = [n floatValue];

			NSDictionary *ds = [d objectForKey:@"settings"];
			if (ds) [e loadData:ds];

			[e setOriginX:x Y:y];
			return e;
		}
	}

	return nil;
}

+ (NSArray*) saveElements:(NSArray*)a
{
	if (!a) return nil;

	int i, c = [a count];
	if (c <= 0) return nil;

	NSMutableArray *ma = [[[NSMutableArray alloc] init] autorelease];
	if (!ma) return nil;

	for (i = 0; i < c; i++)
	{
		NSObject *o = [SBCircuitView saveElement:[a objectAtIndex:i]];
		if (o) [ma addObject:o];
	}

	return ma;
}

+ (NSArray*) loadElements:(NSArray*)a
{
	if (!a) return nil;

	int i, c = [a count];
	if (c <= 0) return nil;

	NSMutableArray *ma = [[[NSMutableArray alloc] init] autorelease];
	if (!ma) return nil;

	for (i = 0; i < c; i++)
	{
		NSObject *o = [SBCircuitView loadElement:[a objectAtIndex:i]];
		if (o) [ma addObject:o];
	}

	return ma;
}

+ (NSDictionary*) saveWire:(SBWire*)w elements:(NSArray*)e
{
	if (!w || !e) return nil;

	NSMutableDictionary *mde = [[[NSMutableDictionary alloc] init] autorelease];
	if (!mde) return nil;

	NSNumber *n = [NSNumber numberWithInt:[w inputIndex]];
	[mde setObject:n forKey:@"inputIndex"];

	n = [NSNumber numberWithInt:[w outputIndex]];
	[mde setObject:n forKey:@"outputIndex"];

	NSUInteger idx;
	idx = [e indexOfObjectIdenticalTo:[w inputElement]];
	if (idx != NSNotFound)
	{
		n = [NSNumber numberWithInt:idx];
		[mde setObject:n forKey:@"inputElement"];
	}
	else return nil;

	idx = [e indexOfObjectIdenticalTo:[w outputElement]];
	if (idx != NSNotFound)
	{
		n = [NSNumber numberWithInt:idx];
		[mde setObject:n forKey:@"outputElement"];
	}
	else return nil;

	NSDictionary *d = [w saveData];
	if (d) [mde setObject:d forKey:@"settings"];

	return mde;
}

+ (SBWire*) loadWire:(NSDictionary*)d elements:(NSArray*)e
{
	if (!d || !e) return nil;

	NSNumber *n1, *n2, *n3, *n4;

	n1 = [d objectForKey:@"inputIndex"];
	n2 = [d objectForKey:@"outputIndex"];
	n3 = [d objectForKey:@"inputElement"];
	n4 = [d objectForKey:@"outputElement"];

	NSDictionary *ds = [d objectForKey:@"settings"];

	if (n1 && n2 && n3 && n4)
	{
		int ie = [n3 intValue];
		int oe = [n4 intValue];
		int c = [e count];

		if (ie < 0 || oe < 0 || ie >= c || oe >= c)
			return nil;

		SBWire *w = [[[SBWire alloc] init] autorelease];

		[w setInputIndex:[n1 intValue]];
		[w setOutputIndex:[n2 intValue]];
		[w setInputElement:[e objectAtIndex:[n3 intValue]]];
		[w setOutputElement:[e objectAtIndex:[n4 intValue]]];

		if (ds) [w loadData:ds];

		int inputs = [[w inputElement] numberOfInputs];
		int outputs = [[w outputElement] numberOfOutputs];
		int ip = [w inputIndex];
		int op = [w outputIndex];

		if (ip >= 0 && op >= 0 && ip < inputs && op < outputs)
			return w;
	}

	return nil;
}

+ (NSArray*) saveWires:(NSArray*)a elements:(NSArray*)e
{
	if (!a || !e) return nil;

	int i, c = [a count];
	if (c <= 0) return nil;

	NSMutableArray *ma = [[[NSMutableArray alloc] init] autorelease];
	if (!ma) return nil;

	for (i = 0; i < c; i++)
	{
		NSObject *o = [SBCircuitView saveWire:[a objectAtIndex:i] elements:e];
		if (o) [ma addObject:o];
	}

	return ma;
}

+ (NSArray*) loadWires:(NSArray*)a elements:(NSArray*)e
{
	if (!a || !e) return nil;

	int i, c = [a count];
	if (c <= 0) return nil;

	NSMutableArray *ma = [[[NSMutableArray alloc] init] autorelease];
	if (!ma) return nil;

	for (i = 0; i < c; i++)
	{
		NSObject *o = [SBCircuitView loadWire:[a objectAtIndex:i] elements:e];
		if (o) [ma addObject:o];
	}

	return ma;
}

- (NSString*) newStringForDescription:(NSString*)desc oldString:(NSString*)oldString
{
	[mGetStringDesc setStringValue:desc];
	[mGetStringTF setStringValue:oldString];
	int result = [NSApp runModalForWindow:mGetStringWindow];
	[mGetStringWindow orderOut:nil];

	if (result) return [mGetStringTF stringValue];
	else return oldString;
}

- (void) newStringCancel:(id)sender
{
	[NSApp stopModalWithCode:0];
}

- (void) newStringOk:(id)sender
{
	[NSApp stopModalWithCode:1];
}

- (void) mini:(id)sender
{
	if (mParent) [mParent undoMark];

	[mRootCircuit setMiniMode:[mMini state] == NSOnState];
	[self setNeedsDisplay:YES];
}

- (void) setParent:(SBCircuitDocument*)parent
{
	mParent = parent;
}

// au design stuff
- (void) saveCircuit:(id)sender
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:@"sbc"];

	int result = [panel runModal];
	if (result != NSOKButton) return;

	NSString *fileName = [panel filename];

	NSDictionary *d = [mRootCircuit saveData];
	if (!d) return;

	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization
						dataFromPropertyList:d
						format:NSPropertyListXMLFormat_v1_0
						errorDescription:&error];

	if (data && !error)
	{
		[data writeToFile:fileName atomically:YES];
	}
	else
	{
		NSLog(@"Error while serializing: %@", error);
		// [error release];
	}

	return;
}


- (void) importCircuit:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:YES];
	int result = [panel runModalForTypes:[NSArray arrayWithObject:@"sbc"]];
	if (result != NSOKButton) return;

	NSString *path = [panel filename];

	[self importCircuitAtPath:path atPosition:NSZeroPoint positionElement:NO];
}

- (BOOL) importCircuitAtPath:(NSString *)inPath atPosition:(NSPoint)inPosition positionElement:(BOOL)positionElement
{
	if (inPath == nil)
		{ return NO; }

	NSString * path = [NSString stringWithString:inPath];
	path = [path stringByStandardizingPath];

	if (path == nil)
		{ return NO; }

	if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO)
		{ return NO; }

	if ([[path pathExtension] isEqualToString:@"sbc"] == NO)
		{ return NO; }

	NSData *data = [NSData dataWithContentsOfFile:path];
	if (data)
	{
		NSString *error = nil;
		NSDictionary *d = [NSPropertyListSerialization
			propertyListFromData:data
			mutabilityOption:NSPropertyListImmutable
			format:nil
			errorDescription:&error];
		if (d && !error)
		{
			SBCircuit *c = [[SBCircuit alloc] init];
			if (!c)
				{ return NO; }

			if (![c loadData:d])
			{
				[c release];
				{ return NO; }
			}

			if (mCurCircuit)
			{
				if (positionElement)
					{ [c setOriginX:inPosition.x Y:inPosition.y]; }
				else
					{ [c setOriginX:100 Y:100]; }

				if (mParent) [mParent undoMark];

				[mCurCircuit addElement:c];

				[self updateForSelectedElement:[mCurCircuit selectedElement]];
				[self setNeedsDisplay:YES];
				return YES;
			}

			[c release];
		}
		else
		{
			NSLog(@"Error while deserializing: %@", error);
// [error release];
		}
	}
	return NO;
}


- (BOOL)insertElementWithName:(NSString *)inName atPosition:(NSPoint)inPosition positionElement:(BOOL)positionElement
{
	if (inName == nil)
		{ return NO; }
	
	NSString * elementName = [NSString stringWithString:inName];

	if (elementName == nil)
		{ return NO; }
	
	SBElement * element = [gElementServer createElement:elementName];
	if (element == nil)
		{ return NO; }
	
	if (positionElement)
		{ [element setOriginX:inPosition.x Y:inPosition.y]; }
	else 
		{ [element setOriginX:100 Y:100]; }
	
	if (mParent)
		{ [mParent undoMark]; }
	
	[mCurCircuit addElement:element];
	
	[self updateForSelectedElement:[mCurCircuit selectedElement]];
	[self setNeedsDisplay:YES];
	return YES;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	float min = [sender isVertical] ? 505.f : 250.f;
	return (proposedMin > min) ? proposedMin : min;
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	float max = [sender isVertical] ? [sender frame].size.width : 500.f;
	return (proposedMax < max) ? proposedMax : max;
}

- (void) addObjectToArray:(id)object
{
	[mReleaseArray addObject:object];
}

- (NSButton *)mPrevLevel
{
	return mPrevLevel;
}

- (NSButton *)mNextLevel
{
	return mNextLevel;
}

- (SBCircuit *)mCurCircuit
{
	return mCurCircuit;	
}

@end

