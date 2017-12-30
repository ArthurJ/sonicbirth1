/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSliderCell.h"
#import "SBArgument.h"

#define kButtonRadius (mSliderWidth >> 1)
#define kButtonDiameter (mSliderWidth)
#define kButtonMinMaxCourse (173.f) // make it a prime number!

#define kMinAngleDegree 120 // 90+30 // y reversed...
#define kMaxAngleDegree 60 // 90-30

#define kMinAngle (4.188790205f) // 270 - 30 -> 240 -> 4.188790205 rad
#define kMaxAngle (-1.047197551f) // 270 + 30 -> 300 -> 5.235987756 rad, or -60 -> -1.047197551

#define kTextSpace (3)
#define kTextHeight (12)


static NSPoint calculatePoint(NSPoint center, float angle, float radius)
{
	NSPoint pt = center;
	pt.x += cosf(angle) * radius;
	pt.y -= sinf(angle) * radius;
	return pt;
}

@implementation SBSliderCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mBackImage = nil;
		mFrontImage = nil;
		
		mSliderHeight = mSliderWidth = 26;
		
		mValueCell = nil;
	}
	return self;
}

- (void) dealloc
{
	if (mBackImage) ogReleaseImage(mBackImage);
	if (mFrontImage) ogReleaseImage(mFrontImage);
	if (mValueCell) [mValueCell release];
	[super dealloc];
}

- (void) setArgument:(SBArgument*)argument parameter:(int)idx
{
	mArgument = argument;
	mParameter = idx;
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
	
	if (mShowValue)
	{
		[self drawValueContentPoint:origin value:ocur];
		if (mSliderWidth < kTextMinWidth)
			origin.x += (kTextMinWidth - mSliderWidth) / 2;
	}

	// calculate front
	NSPoint center = origin;
	center.x += mSliderWidth * 0.5f;
	center.y += mSliderHeight * 0.5f;
	
	// calculate back
	NSRect back;
	back.origin = origin;
	back.size.width = kButtonDiameter;
	back.size.height = kButtonDiameter;
	
	// draw back
	if (mBackImage)
		ogDrawImage(mBackImage, origin.x, origin.y);
	else
	{
		ogSetColor(mColorBack);
		ogFillCircle(back.origin.x + kButtonRadius, back.origin.y + kButtonRadius, kButtonRadius);
	
		// draw contour
		ogSetColor(mColorContour);
		
		NSPoint p1 = calculatePoint(center, kMinAngle, kButtonRadius - 2);
		NSPoint p2 = calculatePoint(center, kMinAngle, kButtonRadius);
		
		ogPushContext();
		ogSetLineWidth(1.5f);
		
			ogStrokeLine(p1.x, p1.y, p2.x, p2.y);
			
			p1 = calculatePoint(center, kMaxAngle, kButtonRadius - 2);
			p2 = calculatePoint(center, kMaxAngle, kButtonRadius);
			ogStrokeLine(p1.x, p1.y, p2.x, p2.y);
			
			ogStrokeArc(center.x, center.y, kButtonRadius, kMinAngleDegree, 360);
			ogStrokeArc(center.x, center.y, kButtonRadius, 0, kMaxAngleDegree);
			
		if (mFrontImage)
		ogPopContext();
	}
	
	
	if (mFrontImage)
	{
		float a = -150 + (cur - min)/(max - min)*(300);
		ogDrawRotatedImage(	mFrontImage,
							center.x - ogImageWidth(mFrontImage)/2,
							center.y - ogImageHeight(mFrontImage)/2,
							a);
	}
	else
	{
		if (mBackImage)
		{
		ogPushContext();
		ogSetLineWidth(1.5f);
		}
		
			// draw front
			ogSetColor(mColorFront);
			
			float angle = kMinAngle + (cur - min)/(max - min)*(kMaxAngle - kMinAngle);
			NSPoint dst = calculatePoint(center, angle, kButtonRadius - 1);
			
			ogStrokeLine(center.x, center.y, dst.x, dst.y);
		
		ogPopContext();
	}
}

- (NSSize) contentSize
{
	if (mShowValue)
	{
		NSSize s = {	(mSliderWidth < kTextMinWidth) ? kTextMinWidth : mSliderWidth,
						mSliderHeight + kTextHeight + kTextSpace }; 
		return s;
	}
	else
	{
		NSSize s = { mSliderWidth, mSliderHeight}; 
		return s;
	}
}


- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	mMouseLock = NO;
	int ox = x, oy = y;
	
	if (mShowValue && mSliderWidth < kTextMinWidth)
		x -= (kTextMinWidth - mSliderWidth) / 2;

	x -= kButtonRadius;
	y -= kButtonRadius;
	float dist = hypotf(x, y);
	
	if (dist >= kButtonRadius)
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

- (void) setShowValue:(BOOL)showValue
{
	mShowValue = showValue;
	if (showValue && !mValueCell)
	{
		mValueCell = [[SBEditFloatCell alloc] init];
		if (!mValueCell) mShowValue = NO;
		else
		{
			[mValueCell setTarget:self];
			[mValueCell setColorsBack:mColorBack contour:mColorContour front:mColorFront];
		}
	}
}

- (void) editCellUpdated:(SBEditFloatCell*)cell
{
	double value = [cell value];
	
	[mArgument beginGestureForParameterAtIndex:mParameter];
	
	[mArgument takeValue:value
				offsetToChange:0
				forParameter:mParameter];
				
	[mArgument didChangeParameterValueAtIndex:mParameter];
	[mArgument endGestureForParameterAtIndex:mParameter];
}

- (void) setSelected:(BOOL)selected
{
//	mSelected = selected;
	if (mValueCell) [mValueCell setSelected:selected];
}

- (BOOL) keyDown:(unichar)ukey
{
	if (mValueCell) return [mValueCell keyDown:ukey];
	return NO;
}

- (BOOL) showsValue
{
	return mShowValue;
}

- (void) setSliderWidth:(float)width
{
	BOOL circular = [self isMemberOfClass:[SBSliderCell class]];

	if (circular) width *= 2; // width is radius

	if (mBackImage && width < ogImageWidth(mBackImage)) width = ogImageWidth(mBackImage);
	if (mFrontImage && width < ogImageWidth(mFrontImage)) width = ogImageWidth(mFrontImage);

	if (width < 5) width = 5;
	else if (width > 500) width = 500;
	
	if (circular)
		mSliderHeight = mSliderWidth = width;
	else
		mSliderWidth = width;
}

- (void) setSliderHeight:(float)height
{
	if (mBackImage && height < ogImageHeight(mBackImage)) height = ogImageHeight(mBackImage);
	if (mFrontImage && height < ogImageHeight(mFrontImage)) height = ogImageHeight(mFrontImage);

	if ([self isMemberOfClass:[SBSliderCell class]])
	{
		mSliderHeight = mSliderWidth;
		return;
	}
	
	mSliderHeight = height;
	if (mSliderHeight < 5) mSliderHeight = 5;
	else if (mSliderHeight > 500) mSliderHeight = 500;
}

- (int) sliderWidth
{
	return mSliderWidth;
}

- (int) sliderHeight
{
	return mSliderHeight;
}

- (void) setBackImage:(NSImage*)back frontImage:(NSImage*)front
{
	if (mBackImage) ogReleaseImage(mBackImage);
	if (mFrontImage) ogReleaseImage(mFrontImage);
	
	mBackImage = nil;
	mFrontImage = nil;

	if (back) mBackImage = [back toOgImage];
	if (front) mFrontImage = [front toOgImage];
	
	if (mBackImage || mFrontImage)
	{
		mSliderWidth = 0;
		mSliderHeight = 0;
	}
	
	if (mBackImage)
	{
		if (ogImageWidth(mBackImage) > mSliderWidth) mSliderWidth = ogImageWidth(mBackImage);
		if (ogImageHeight(mBackImage) > mSliderHeight) mSliderHeight = ogImageHeight(mBackImage);
	}
	
	if (mFrontImage)
	{
		if (ogImageWidth(mFrontImage) > mSliderWidth) mSliderWidth = ogImageWidth(mFrontImage);
		if (ogImageHeight(mFrontImage) > mSliderHeight) mSliderHeight = ogImageHeight(mFrontImage);
	}
}

- (void) setColorsBack:(ogColor)back contour:(ogColor)contour front:(ogColor)front
{
	[super setColorsBack:back contour:contour front:front];
	if (mValueCell) [mValueCell setColorsBack:back contour:contour front:front];
}

- (void) drawValueContentPoint:(NSPoint)origin value:(double)value
{
	NSRect rect;
	
	rect.size.height = kTextHeight;
	rect.origin.y = origin.y + mSliderHeight + kTextSpace;
	
	rect.size.width =	  (mSliderWidth > kTextMaxWidth)
						? kTextMaxWidth
						: ((mSliderWidth < kTextMinWidth) ? kTextMinWidth : mSliderWidth);

	
	rect.origin.x = origin.x;
	if (mSliderWidth > rect.size.width) rect.origin.x += (mSliderWidth - rect.size.width) / 2;
	
	[mValueCell setWidth:rect.size.width height:rect.size.height];
	[mValueCell setValue:value];
	[mValueCell drawContentAtPoint:rect.origin];
}

@end
