/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBIndexedCell.h"
#import "SBArgument.h"

#import <Carbon/Carbon.h>

@implementation SBIndexedCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mStringAttributes = [[NSMutableDictionary alloc] init];
		if (!mStringAttributes)
		{
			[self release];
			return nil;
		}
	
		// set font
		NSFont *ft = [NSFont fontWithName:@"Courier" size:9.0f];
		[mStringAttributes setObject:ft forKey:NSFontAttributeName];
		
		// check max chars
		NSSize size = [@"a" sizeWithAttributes:mStringAttributes];
		mMaxChars = kTextWidth / size.width;
	}
	return self;
}

- (void) dealloc
{
	if (mStringAttributes) [mStringAttributes release];
	if (mMenu) [mMenu release];
	[super dealloc];
}

- (void) setArgument:(SBArgument*)argument parameter:(int)idx
{
	mArgument = argument;
	mParameter = idx;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	int idx = [mArgument currentValueForParameter:mParameter];
	NSString *st = [[mArgument indexedNamesForParameter:mParameter] objectAtIndex:idx];
	
	if ([st length] > mMaxChars)
	{
		st = [st substringToIndex:(mMaxChars - 3)];
		st = [NSString stringWithFormat:@"%@...", st];
	}
	
	// calculate back
	NSRect back;
	back.origin = origin;
	back.size.width = kButtonWidth;
	back.size.height = kButtonHeight;
	
	//NSBezierPath *bpb = [NSBezierPath bezierPath];
	//[bpb setLineJoinStyle:NSRoundLineJoinStyle];
	
	// top left
	//NSPoint pt = origin; pt.y += kTextHeightOffset;
	//NSPoint start = pt;
	//[bpb moveToPoint:pt];
	
	//pt = origin; pt.x += kTextWidthOffset;
	//[bpb curveToPoint:pt controlPoint1:origin controlPoint2:origin];

	// top right
	//NSPoint pt2 = origin; pt2.x += kButtonWidth;
	//pt.x = pt2.x - kTextWidthOffset;
	//[bpb lineToPoint:pt];
	//pt.x += kTextWidthOffset;
	//pt.y += kTextHeightOffset;
	//[bpb curveToPoint:pt controlPoint1:pt2 controlPoint2:pt2];

	// bottom right
	//pt2.y += kButtonHeight;
	//pt.y = pt2.y - kTextHeightOffset;
	//[bpb lineToPoint:pt];
	
	//pt.x -= kTextWidthOffset;
	//pt.y += kTextHeightOffset;
	//[bpb curveToPoint:pt controlPoint1:pt2 controlPoint2:pt2];
	
	// bottom left
	//pt2.x -= kButtonWidth;
	//pt.x = pt2.x + kTextWidthOffset;
	//[bpb lineToPoint:pt];
	
	//pt.x -= kTextWidthOffset;
	//pt.y -= kTextHeightOffset;
	//[bpb curveToPoint:pt controlPoint1:pt2 controlPoint2:pt2];
	
	//[bpb lineToPoint:start];

	// draw back
	ogSetColor(mColorBack);
	ogFillRoundedRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height, 3);
	
	// draw contour
	ogSetColor(mColorContour);
	ogStrokeRoundedRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height, 3);
	
	// draw triangle
	ogSetColor(mColorFront);
	
#define kPOffset (0.30)
#define kPSize (1 - (2*kPOffset))
#define kPHalfSize ((1 - (2*kPOffset))/2)
	
	NSPoint pt = origin;
	pt.x += kButtonWidth - kTriangleBoxSize;
	pt.x += kTriangleBoxSize * kPOffset;
	pt.y += kTriangleBoxSize * kPOffset;

	//NSBezierPath *bp = [NSBezierPath bezierPath];
	//[bp moveToPoint:pt];
	
	NSPoint pt2 = pt;
	pt2.x += kTriangleBoxSize * kPSize;
	
	//[bp moveToPoint:pt2];
	
	NSPoint pt3 = pt2;
	pt3.x = pt.x + kTriangleBoxSize * kPHalfSize;
	pt3.y += kTriangleBoxSize * kPSize;

	//[bp lineToPoint:pt2];
	//[bp lineToPoint:pt];
	//[bp setLineJoinStyle:NSRoundLineJoinStyle];
	//[bp fill];
	ogFillTriangle(pt.x, pt.y, pt2.x, pt2.y, pt3.x, pt3.y);
	
	// draw text
	NSRect text;
	text.origin.x = origin.x + kTextWidthOffset;
	text.origin.y = origin.y + kTextHeightOffset;
	text.size.width = kTextWidth;
	text.size.height = kTextHeight;
	
	//[st drawInRect:text withAttributes:mStringAttributes];
	ogDrawStringInRect([st UTF8String], text.origin.x, text.origin.y, text.size.width, text.size.height);
}

- (NSSize) contentSize
{
	NSSize s = { kButtonWidth, kButtonHeight }; 
	return s;
}
/*
- (void) setColorsBack:(NSColor*)back contour:(NSColor*)contour front:(NSColor*)front
{
	[super setColorsBack:back contour:contour front:front];
	if (mColorFront) [mStringAttributes setObject:mColorFront forKey:NSForegroundColorAttributeName];
}
*/
- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	if (x < 0 || x >= kButtonWidth || y < 0 || y >= kButtonHeight)	return NO;

	NSEvent *event = (NSApp) ? [NSApp currentEvent] : nil;
	NSWindow *window = (event) ? [event window] : nil;
	NSView *view = (window) ? [window contentView] : nil;
	
	if (!view)
	{
		// try carbon
#if 0
		// first convert to global x & y
		/*
		NSPoint pt = [mArgument contentOrigin];
		x += pt.x;
		y += pt.y;
	
		WindowRef window = FrontWindow();
		
		Rect windowBounds;
		GetWindowBounds(window, kWindowGlobalPortRgn, &windowBounds);
		
		x += windowBounds.left;
		y += windowBounds.top;
		*/
		
		/*
		NSPoint pt = [NSEvent mouseLocation];
		x = pt.x;
		y = pt.y;
		*/
		
		Point pt;
		GetMouse(&pt);
		LocalToGlobal(&pt);
		x = pt.h;
		y = pt.v;
		
	//	printf("GetMouse x:%i, y:%i (cv: x:%i y:%i)\n", pt.h, pt.v, x, y);
		
		
		// then create menu
		MenuRef menu;
		CreateNewMenu(0, 0, &menu);
		if (!menu)
		{
			NSLog(@"cant create carbon menu\n");
			return NO;
		}
		
		// then add items to menu
		NSArray *a = [mArgument indexedNamesForParameter:mParameter];
		int c = [a count], i;
	
		for (i = 0; i < c; i++)
		{
			Str255 st;
			CopyCStringToPascal([[a objectAtIndex:i] UTF8String], st);
			AppendMenuItemText(menu, st);
		}
		
		// and finally draw it
		long result = PopUpMenuSelect(menu, y, x, 0);
		DisposeMenu(menu);
		
		if (result)
		{
			int idx = (result & 0xFFFF) - 1;
		
			[mArgument takeValue:idx
				offsetToChange:0
				forParameter:mParameter];
				
			[mArgument beginGestureForParameterAtIndex:mParameter];
			[mArgument didChangeParameterValueAtIndex:mParameter];
			[mArgument endGestureForParameterAtIndex:mParameter];
			
			return YES;
		}
#endif
		return NO;
	}

	
	if (mMenu) [mMenu release];
	mMenu = [[NSMenu alloc] init];
	if (!mMenu) return NO;
	
	NSArray *a = [mArgument indexedNamesForParameter:mParameter];
	int c = [a count], i;
	
	for (i = 0; i < c; i++)
		[[mMenu addItemWithTitle:[a objectAtIndex:i] action:@selector(changedIndex:) keyEquivalent:@""] setTarget:self];
		
	[NSMenu popUpContextMenu:mMenu
			withEvent:event
			forView:view
			withFont:[mStringAttributes objectForKey:NSFontAttributeName]];
	
	return YES;
}

- (void) changedIndex:(id)sender
{
	if (!sender) return;
	
	int idx = [mMenu indexOfItem:sender];
	if (idx < 0) return;

	[mArgument takeValue:idx
				offsetToChange:0
				forParameter:mParameter];
				
	[mArgument beginGestureForParameterAtIndex:mParameter];
	[mArgument didChangeParameterValueAtIndex:mParameter];
	[mArgument endGestureForParameterAtIndex:mParameter];
}

@end
