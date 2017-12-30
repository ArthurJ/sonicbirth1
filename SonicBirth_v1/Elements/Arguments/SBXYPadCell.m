/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBXYPadCell.h"
#import "SBArgument.h"

@implementation SBXYPadCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mWidth = mHeight = 100;
		mRadius = 10;
		
		mBackImage = nil;
		mFrontImage = nil;
	}
	return self;
}

- (void) dealloc
{
	if (mBackImage) ogReleaseImage(mBackImage);
	if (mFrontImage) ogReleaseImage(mFrontImage);
	
	[super dealloc];
}

- (void) setBackImage:(NSImage*)back frontImage:(NSImage*)front
{
	if (mBackImage) ogReleaseImage(mBackImage);
	if (mFrontImage) ogReleaseImage(mFrontImage);
	
	mBackImage = nil;
	mFrontImage = nil;

	if (back) mBackImage = [back toOgImage];
	if (front) mFrontImage = [front toOgImage];
		
	if (mBackImage)
	{
		mWidth = ogImageWidth(mBackImage);
		mHeight = ogImageHeight(mBackImage);
	}
		
	if (mFrontImage)
	{
		mRadius = ((ogImageWidth(mFrontImage) < ogImageHeight(mFrontImage))
					? ogImageWidth(mFrontImage) : ogImageHeight(mFrontImage)) / 2.f;
	}
}

- (void) setWidth:(float)width height:(float)height radius:(float)radius
{
	if (!mBackImage)
	{
		mWidth = width;
		mHeight = height;
	}
	
	if (!mFrontImage)
		mRadius = radius;
}

- (void) setArgument:(SBArgument*)argument
{
	mArgument = argument;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	NSRect bd = {origin, {mWidth, mHeight}};
	
	if (!mBackImage)
	{
		ogSetColor(mColorBack);
		//[NSBezierPath fillRect:bd];
		ogFillRectangle(bd.origin.x, bd.origin.y, bd.size.width, bd.size.height);
	
		ogSetColor(mColorContour);
		//[NSBezierPath strokeRect:bd];
		ogStrokeRectangle(bd.origin.x, bd.origin.y, bd.size.width, bd.size.height);
	}
	else
	{
		//NSPoint pt = origin;
		//pt.y += [mBackImage size].height;
		//[mBackImage compositeToPoint:pt operation:NSCompositeSourceOver];
		ogDrawImage(mBackImage, origin.x, origin.y);
	}
	
	BOOL logarithmic_x = [mArgument logarithmicForParameter:0];
	float cur_x = [mArgument currentValueForParameter:0];
	float min_x = [mArgument minValueForParameter:0];
	float max_x = [mArgument maxValueForParameter:0];
	if (logarithmic_x)
	{
		cur_x = lin2log(cur_x, min_x, max_x);
		float nmin = lin2log(min_x, min_x, max_x);
		max_x = lin2log(max_x, min_x, max_x);
		min_x = nmin;
	}
	
	BOOL logarithmic_y = [mArgument logarithmicForParameter:1];
	float cur_y = [mArgument currentValueForParameter:1];
	float min_y = [mArgument minValueForParameter:1];
	float max_y = [mArgument maxValueForParameter:1];
	if (logarithmic_y)
	{
		cur_y = lin2log(cur_y, min_y, max_y);
		float nmin = lin2log(min_y, min_y, max_y);
		max_y = lin2log(max_y, min_y, max_y);
		min_y = nmin;
	}
	
	float cx = origin.x+mRadius + (cur_x - min_x)/(max_x - min_x)*(mWidth - mRadius*2);
	float cy = origin.y+mRadius + (1.f - (cur_y - min_y)/(max_y - min_y))*(mHeight - mRadius*2);
	
	if (!mFrontImage)
	{
		ogSetColor(mColorFront);
		
		//NSRect r = {{cx - mRadius, cy - mRadius}, {mRadius*2, mRadius*2}};
		//NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:r];
		//[bp stroke];
		
		ogPushContext();
			ogSetLineWidth(1.5f);
			ogStrokeCircle(cx, cy, mRadius);
		ogPopContext();
	}
	else
	{
		//NSSize s = [mFrontImage size];
		//NSPoint pt = { cx - s.width/2.f, cy + s.height/2.f };
		//[mFrontImage compositeToPoint:pt operation:NSCompositeSourceOver];
		ogDrawImage(mFrontImage, cx - ogImageWidth(mFrontImage)/2.f, cy - ogImageHeight(mFrontImage)/2.f);
	}
}


- (NSSize) contentSize
{
	NSSize s = {mWidth, mHeight};
	return s;
}

- (float) padRadius
{
	return mRadius;
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	mMouseLock = NO;
	
	BOOL logarithmic_x = [mArgument logarithmicForParameter:0];
	float cur_x = [mArgument currentValueForParameter:0];
	float min_x = [mArgument minValueForParameter:0];
	float max_x = [mArgument maxValueForParameter:0];
	if (logarithmic_x)
	{
		cur_x = lin2log(cur_x, min_x, max_x);
		float nmin = lin2log(min_x, min_x, max_x);
		max_x = lin2log(max_x, min_x, max_x);
		min_x = nmin;
	}
	
	BOOL logarithmic_y = [mArgument logarithmicForParameter:1];
	float cur_y = [mArgument currentValueForParameter:1];
	float min_y = [mArgument minValueForParameter:1];
	float max_y = [mArgument maxValueForParameter:1];
	if (logarithmic_y)
	{
		cur_y = lin2log(cur_y, min_y, max_y);
		float nmin = lin2log(min_y, min_y, max_y);
		max_y = lin2log(max_y, min_y, max_y);
		min_y = nmin;
	}
	
	float cx = mRadius + (cur_x - min_x)/(max_x - min_x)*(mWidth - mRadius*2);
	float cy = mRadius + (1.f - (cur_y - min_y)/(max_y - min_y))*(mHeight - mRadius*2);
	
	x -= cx;
	y -= cy;
	
	float dist = hypotf(x, y);
	
	if (dist >= mRadius) return NO;
	
	[mArgument beginGestureForParameterAtIndex:0];
	[mArgument beginGestureForParameterAtIndex:1];
	mMouseLock = YES;
	
	return YES;
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	if (!mMouseLock) return NO;
	
	/*
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
		
	cur = cur + (mStartY - y)/kButtonMinMaxCourse * (max - min);
	if (cur < min) cur = min;
	else if (cur > max) cur = max;
	
	[mArgument takeValue:(logarithmic) ? log2lin(cur, omin, omax) : cur
				offsetToChange:0
				forParameter:mParameter];
				
	[mArgument didChangeParameterValueAtIndex:mParameter];
	*/
	
	BOOL logarithmic_x = [mArgument logarithmicForParameter:0];
	float cur_x = [mArgument currentValueForParameter:0];
	float min_x = [mArgument minValueForParameter:0], omin_x = min_x;
	float max_x = [mArgument maxValueForParameter:0], omax_x = max_x;
	if (logarithmic_x)
	{
		cur_x = lin2log(cur_x, min_x, max_x);
		float nmin = lin2log(min_x, min_x, max_x);
		max_x = lin2log(max_x, min_x, max_x);
		min_x = nmin;
	}
	
	BOOL logarithmic_y = [mArgument logarithmicForParameter:1];
	float cur_y = [mArgument currentValueForParameter:1];
	float min_y = [mArgument minValueForParameter:1], omin_y = min_y;
	float max_y = [mArgument maxValueForParameter:1], omax_y = max_y;
	if (logarithmic_y)
	{
		cur_y = lin2log(cur_y, min_y, max_y);
		float nmin = lin2log(min_y, min_y, max_y);
		max_y = lin2log(max_y, min_y, max_y);
		min_y = nmin;
	}

	cur_x = min_x + (x - mRadius)/(mWidth - 2*mRadius) * (max_x - min_x);
	cur_y = min_y + (1.f - (y - mRadius)/(mHeight - 2*mRadius)) * (max_y - min_y);
	if (cur_x < min_x) cur_x = min_x; else if (cur_x > max_x) cur_x = max_x;
	if (cur_y < min_y) cur_y = min_y; else if (cur_y > max_y) cur_y = max_y;
	
	[mArgument takeValue:(logarithmic_x) ? log2lin(cur_x, omin_x, omax_x) : cur_x
				offsetToChange:0
				forParameter:0];
	[mArgument takeValue:(logarithmic_y) ? log2lin(cur_y, omin_y, omax_y) : cur_y
				offsetToChange:0
				forParameter:1];
				
	[mArgument didChangeParameterValueAtIndex:0];
	[mArgument didChangeParameterValueAtIndex:1];
	
	return YES;
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	if (!mMouseLock) return NO;
	
	[mArgument endGestureForParameterAtIndex:1];
	[mArgument endGestureForParameterAtIndex:0];
	mMouseLock = NO;
	return YES;
}


@end
