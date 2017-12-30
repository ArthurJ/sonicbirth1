/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBMeterCell.h"

@implementation SBMeterCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mValue = 0;
	
		mWidth = 10;
		mHeight = 100;
		mType = 0;
		mInversed = NO;
		mMin = 0;
		mMax = 1;
	}
	return self;
}

- (void) setValue:(double)value
{
	mValue = value;
}

- (void) setWidth:(int)w
{
	if (w < 3) w = 3;
	mWidth = w;
}

- (void) setHeight:(int)h
{
	if (h < 3) h = 3;
	mHeight = h;
}

- (void) setMin:(double)m
{
	mMin = m;
}

- (void) setMax:(double)m
{
	mMax = m;
}

- (void) setType:(int)t
{
	if (t < 0) t = 0; else if (t > 1) t= 1;
	mType = t;
}

- (void) setInversed:(BOOL)i
{
	mInversed = i;
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
	
	double val = mValue;
	if (isinf(val)) val = mMin;
	else if (isnan(val)) val = mMin;
	
	double pos = (val - mMin)/(mMax - mMin);
	if (pos < 0) pos = 0; else if (pos > 1) pos = 1;
	
	back.origin.x += 1;
	back.origin.y += 1;
	back.size.width -= 2;
	back.size.height -= 2;
	
	if (!mType) // vertical
	{
		pos *= back.size.height;
		if (!mInversed)
			ogFillRectangle(back.origin.x, back.origin.y + back.size.height - pos, back.size.width, pos);
		else
			ogFillRectangle(back.origin.x, back.origin.y, back.size.width, pos);
	}
	else
	{
		pos *= back.size.width;
		if (mInversed)
			ogFillRectangle(back.origin.x + back.size.width - pos, back.origin.y, pos, back.size.height);
		else
			ogFillRectangle(back.origin.x, back.origin.y, pos, back.size.height);
	}
}


- (NSSize) contentSize
{
	NSSize s = { mWidth, mHeight }; 
	return s;
}

@end
