/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSliderVerCell.h"
#import "SBArgument.h"

#define kButtonWidth (mSliderWidth)
#define kButtonHeight (mSliderHeight)
#define kRadius (mSliderWidth / 2.f)

#define kButtonMinMaxCourse ((float)(kButtonHeight))

#define kTextSpace (3)
#define kTextHeight (12)
#define kTextWidth (32)


@implementation SBSliderVerCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mSliderWidth = 14;
		mSliderHeight = 100;
	}
	return self;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	BOOL logarithmic = [mArgument logarithmicForParameter:mParameter];

	float cur = [mArgument currentValueForParameter:mParameter], ocur = cur;
	float min = [mArgument minValueForParameter:mParameter];
	float max = [mArgument maxValueForParameter:mParameter];
	
	if (logarithmic)
	{
		cur = lin2log(cur, min, max);
		float nmin = lin2log(min, min, max);
		max = lin2log(max, min, max);
		min = nmin;
	}
	
	float pos = 1.f - (cur-min)/(max-min);
	
	if (mShowValue)
	{
		[self drawValueContentPoint:origin value:ocur];
		if (mSliderWidth < kTextMinWidth)
			origin.x += (kTextMinWidth - mSliderWidth) / 2;
	}

	NSRect back = { origin, { kButtonWidth, kButtonHeight }};
	
	// draw back
	if (mBackImage)
		ogDrawImage(mBackImage, origin.x, origin.y);
	else
	{
		ogSetColor(mColorBack);
		ogFillRoundedRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height, kRadius);

		// draw contour
		ogSetColor(mColorContour);
		ogStrokeRoundedRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height, kRadius);
	}

	// draw front
	NSPoint pt = origin;
	if (mFrontImage)
	{
		float range = kButtonHeight - ogImageHeight(mFrontImage);
		pt.y += pos * range;
		pt.x += (kButtonWidth - ogImageWidth(mFrontImage)) / 2;
		ogDrawImage(mFrontImage, pt.x, pt.y);
	}
	else
	{
		float range = kButtonHeight - kRadius - kRadius;
		pt.y += pos * range;
	
		ogSetColor(mColorFront);
		ogFillCircle(pt.x + kRadius, pt.y + kRadius, kRadius - 1);
	}
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	mMouseLock = NO;
	int ox = x, oy = y;
	
	if (mShowValue && mSliderWidth < kTextMinWidth)
		x -= (kTextMinWidth - mSliderWidth) / 2;

	if (x >= kButtonWidth || x < 0 || y < 0 || y >= kButtonHeight)
	{
		if (mShowValue && mValueCell)
		{
			int width =	  (mSliderWidth > kTextMaxWidth)
						? kTextMaxWidth
						: ((mSliderWidth < kTextMinWidth) ? kTextMinWidth : mSliderWidth);
			int dx = (mSliderWidth > width) ? ((width - mSliderWidth) / 2) : 0;
			int dy = -mSliderHeight - kTextSpace;
			return [mValueCell mouseDownX:ox + dx Y:oy + dy clickCount:(int)clickCount];
		}
		return NO;
	}
	
	if (mShowValue && mValueCell) [mValueCell setSelected:NO];
	
	[mArgument beginGestureForParameterAtIndex:mParameter];
	mMouseLock = YES;
	mStartPos = y;
	mStartVal = [mArgument currentValueForParameter:mParameter];
	
	return YES;
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	if (!mMouseLock)
	{
		if (mShowValue && mValueCell)
		{
			int width =	  (mSliderWidth > kTextMaxWidth)
						? kTextMaxWidth
						: ((mSliderWidth < kTextMinWidth) ? kTextMinWidth : mSliderWidth);
			int dx = (mSliderWidth > width) ? ((width - mSliderWidth) / 2) : 0;
			int dy = -mSliderHeight - kTextSpace;
			return [mValueCell mouseDraggedX:x + dx Y:y + dy
										lastX:lx + dx lastY:ly + dy];
		}
		return NO;
	}
	
	BOOL logarithmic = [mArgument logarithmicForParameter:mParameter];

	float cur = mStartVal;
	float min = [mArgument minValueForParameter:mParameter], omin = min;
	float max = [mArgument maxValueForParameter:mParameter], omax = max;
	
	if (logarithmic)
	{
		cur = lin2log(cur, min, max);
		float nmin = lin2log(min, min, max);
		max = lin2log(max, min, max);
		min = nmin;
	}
		
	cur = cur + (mStartPos - y)/kButtonMinMaxCourse * (max - min);
	if (cur < min) cur = min;
	else if (cur > max) cur = max;
	
	[mArgument takeValue:(logarithmic) ? log2lin(cur, omin, omax) : cur
				offsetToChange:0
				forParameter:mParameter];
				
	[mArgument didChangeParameterValueAtIndex:mParameter];
	
	return YES;
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	if (!mMouseLock)
	{
		if (mShowValue && mValueCell)
		{
			int width =	  (mSliderWidth > kTextMaxWidth)
						? kTextMaxWidth
						: ((mSliderWidth < kTextMinWidth) ? kTextMinWidth : mSliderWidth);
			int dx = (mSliderWidth > width) ? ((width - mSliderWidth) / 2) : 0;
			int dy = -mSliderHeight - kTextSpace;
			return [mValueCell mouseUpX:x + dx Y:y + dy];
		}
		return NO;
	}
	
	[mArgument endGestureForParameterAtIndex:mParameter];
	mMouseLock = NO;
	return YES;
}

@end
