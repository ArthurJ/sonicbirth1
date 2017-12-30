/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBEditFloatCell.h"
#import "equation.h"
#import <math.h>

@implementation SBEditFloatCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mValue = 0;
		[self setString:[[NSNumber numberWithDouble:mValue] stringValue]];
	}
	return self;
}

- (void) setValue:(double)value
{
	if (value != mValue)
	{
		mValue = value;
		[self setString:[[NSNumber numberWithDouble:mValue] stringValue]];
	}
}

- (double) value
{
	return mValue;
}

- (void) endEditing
{
	[mString appendString:@";"];
	
	mValue = parseSimpleEquation([mString UTF8String]);
	[self setString:[[NSNumber numberWithDouble:mValue] stringValue]];

	[super endEditing];
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	if (mFocused)
	{
		[super drawContentAtPoint:origin];
		return;
	}

	NSRect back = { origin, { mWidth, mHeight }};

	// draw back	
	ogSetColor(mColorBack);
	ogFillRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height);
	
	// draw contour
	ogSetColor(mColorContour);
	ogStrokeRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height);
	
	// draw text
	ogSetColor(mColorFront);
	ogDrawValueInRect(mValue,
						back.origin.x + 2, back.origin.y + 1,
						back.size.width - 4, back.size.height - 2);
	
}


@end
