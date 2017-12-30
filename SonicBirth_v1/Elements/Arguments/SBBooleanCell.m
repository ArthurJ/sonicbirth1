/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBBooleanCell.h"
#import "SBArgument.h"

#define kButtonSpace (1)

#define kButtonRadius (4)
#define kButtonHighLowOffset (6)

#define kButtonSpacedRadius (kButtonRadius + kButtonSpace)
#define kButtonDiameter (kButtonRadius*2)

#define kButtonWidth (kButtonDiameter + (kButtonSpace*2))
#define kButtonHeight (kButtonDiameter + kButtonHighLowOffset + (kButtonSpace*2))

@implementation SBBooleanCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mWidth = kButtonWidth;
		mHeight = kButtonHeight;
		
		mOffImage = nil;
		mMidImage = nil;
		mOnImage = nil;
	}
	return self;
}

- (void) dealloc
{
	if (mOffImage) ogReleaseImage(mOffImage);
	if (mMidImage) ogReleaseImage(mMidImage);
	if (mOnImage) ogReleaseImage(mOnImage);
	[super dealloc];
}

- (void) setArgument:(SBArgument*)argument parameter:(int)idx
{
	mArgument = argument;
	mParameter = idx;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	BOOL enabled = ([mArgument currentValueForParameter:mParameter] > 0.5); // 0 is off, 1 is on
	
	if (mMidImage && mMouseLock)
	{
		ogDrawImage(mMidImage, origin.x, origin.y);
		return;
	}
	else if (mOnImage && enabled && !mMouseLock)
	{
		ogDrawImage(mOnImage, origin.x, origin.y);
		return;
	}
	else if (mOffImage && !enabled && !mMouseLock)
	{
		ogDrawImage(mOffImage, origin.x, origin.y);
		return;
	}
	
	//NSBezierPath *bp;
	NSPoint cur;
	if (mMouseLock)
	{
		// calculate mid circle
		cur.x = origin.x + kButtonSpace;
		cur.y = origin.y + kButtonSpace + (kButtonHighLowOffset/2);
	}
	else if (enabled)
	{
		// calculate high circle
		cur.x = origin.x + kButtonSpace;
		cur.y = origin.y + kButtonSpace;
	}
	else
	{
		// calculate low circle
		cur.x = origin.x + kButtonSpace;
		cur.y = origin.y + kButtonSpace + kButtonHighLowOffset;
	}
	
	// calculate middle
	NSPoint pt = origin;
	pt.y += kButtonSpacedRadius;

	NSPoint center = origin;
	center.x += kButtonSpacedRadius;
	center.y += kButtonSpacedRadius;
	
	NSPoint center2 = center;
	center2.y += kButtonHighLowOffset;

	NSPoint pt2 = pt;
	pt2.x += kButtonWidth;
	pt2.y += kButtonHighLowOffset;

	// draw back
	ogSetColor(mColorBack);
	
	ogFillArc(center.x, center.y, kButtonSpacedRadius, 180, 360);
	ogFillRectangle(pt.x, pt.y, kButtonWidth, kButtonHighLowOffset);
	ogFillArc(center2.x, center2.y, kButtonSpacedRadius, 0, 180);
	
	// draw contour
	ogSetColor(mColorContour);

	ogStrokeArc(center.x, center.y, kButtonSpacedRadius, 180, 360);
	ogStrokeLine(pt.x, pt.y, pt.x, pt2.y);
	ogStrokeLine(pt2.x, pt.y, pt2.x, pt2.y);
	ogStrokeArc(center2.x, center2.y, kButtonSpacedRadius, 0, 180);
	
	// draw front
	ogSetColor(mColorFront);
	ogFillCircle(cur.x + kButtonRadius, cur.y + kButtonRadius, kButtonRadius);
}

- (NSSize) contentSize
{
	NSSize s = { mWidth, mHeight }; 
	return s;
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	if (!mMouseLock) return NO; mMouseLock = NO;
	if (x < 0 || x >= mWidth || y < 0 || y > mHeight) return YES;
	BOOL enabled = ([mArgument currentValueForParameter:mParameter] > 0.5);
	[mArgument takeValue:(enabled) ? 0. : 1.
				offsetToChange:0
				forParameter:mParameter];
				
	[mArgument beginGestureForParameterAtIndex:mParameter];
	[mArgument didChangeParameterValueAtIndex:mParameter];
	[mArgument endGestureForParameterAtIndex:mParameter];
	return YES;
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	if (x < 0 || x >= mWidth || y < 0 || y > mHeight) return NO;
	mMouseLock = YES;
	return YES;
}

- (void) setOffImage:(NSImage*)off midImage:(NSImage*)mid onImage:(NSImage*)on
{
	if (mOffImage) ogReleaseImage(mOffImage);
	if (mMidImage) ogReleaseImage(mMidImage);
	if (mOnImage) ogReleaseImage(mOnImage);
	
	mOffImage = nil;
	mMidImage = nil;
	mOnImage = nil;

	if (off) mOffImage = [off toOgImage];
	if (mid) mMidImage = [mid toOgImage];
	if (on)  mOnImage  = [on  toOgImage];
	
	mWidth = kButtonWidth;
	mHeight = kButtonHeight;
	
	if (mOffImage)
	{
		if (ogImageWidth(mOffImage) > mWidth) mWidth = ogImageWidth(mOffImage);
		if (ogImageHeight(mOffImage) > mHeight) mHeight = ogImageHeight(mOffImage);
	}
	
	if (mMidImage)
	{
		if (ogImageWidth(mMidImage) > mWidth) mWidth = ogImageWidth(mMidImage);
		if (ogImageHeight(mMidImage) > mHeight) mHeight = ogImageHeight(mMidImage);
	}
	
	if (mOnImage)
	{
		if (ogImageWidth(mOnImage) > mWidth) mWidth = ogImageWidth(mOnImage);
		if (ogImageHeight(mOnImage) > mHeight) mHeight = ogImageHeight(mOnImage);
	}
}

@end
