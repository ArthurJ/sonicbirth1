/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBValueCell.h"
#import "SBElement.h" // for gTextAttributes

#define kMinWidth 20
#define kMinHeight 12

#define kMaxWidth 100
#define kMaxHeight 24

#define kDefaultWidth 60
#define kDefaultHeight 16


@implementation SBValueCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mWidth = kDefaultWidth;
		mHeight = kDefaultHeight;
	}
	return self;
}

- (void) setValue:(double)value
{
	mValue = value;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	NSRect back = { origin, { mWidth, mHeight }};

	// draw back	
	ogSetColor(mColorBack);
	ogFillRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height);

	// draw contour
	ogSetColor(mColorContour);
	ogStrokeRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height);
	
	// draw text
	ogSetColor(mColorFront);
	ogDrawValueInRect(mValue, back.origin.x + 1, back.origin.y + 1, back.size.width - 2, back.size.height - 2);
}


- (NSSize) contentSize
{
	NSSize s = { mWidth, mHeight }; 
	return s;
}

- (void) setWidth:(float)width height:(float)height
{
	if (width < kMinWidth) width = kMinWidth;
	else if (width > kMaxWidth) width = kMaxWidth;
	
	if (height < kMinHeight) height = kMinHeight;
	else if (height > kMaxHeight) height = kMaxHeight;
	
	mWidth = width;
	mHeight = height;
}

@end
