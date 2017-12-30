/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBPointsCell.h"
#import "SBPointCalculation.h"
#import "SBElement.h"

@implementation SBPointsCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mSize.width = 300;
		mSize.height = 100;
		
		mUptodate = NO;
		mSelectedPoint = -1;
		mPointsBuffer = nil;
		
		//mBezierPath = [[NSBezierPath alloc] init];
		//if (!mBezierPath)
		//{
		//	[self release];
		//	return nil;
		//}
	}
	return self;
}

- (void) dealloc
{
	//if (mBezierPath) [mBezierPath release];
	[super dealloc];
}

- (void) setPointsBuffer:(SBPointsBuffer*)pointsBuffer
{
	mPointsBuffer = pointsBuffer;
	mUptodate = NO;
}

- (void) setContentSize:(NSSize)size
{
	mSize = size;
	if (mSize.width < 50) mSize.width = 50;
	if (mSize.height < 50) mSize.height = 50;
	
	mUptodate = NO;
}

- (NSSize) contentSize
{
	return mSize;
}

- (void) update
{
	if (mUptodate) return;
	mUptodate = YES;
/*	
	int save = 0;

	[mBezierPath removeAllPoints];
	if (!mPointsBuffer) return;
	
	SBPointsBuffer pts = *mPointsBuffer;
	
	NSPoint pt = { 0, mSize.height - pointCalculate(&pts, 0, &save) * mSize.height };
	[mBezierPath moveToPoint:pt];
	
	int c = mSize.width, i;
	for (i = 1; i < c; i++)
	{
		pt.x = (float)i/(float)c;
		pt.y = mSize.height - pointCalculate(&pts, pt.x, &save) * mSize.height;
		pt.x = i;
		
		[mBezierPath lineToPoint:pt];
	}
*/
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	//if (!mUptodate) [self update];

	NSRect bound = { origin, mSize };
	
	//NSBezierPath *back = [NSBezierPath bezierPathWithRect:bound];
	
	// draw back
	ogSetColor(mColorBack);
	//[back fill];
	ogFillRectangle(bound.origin.x, bound.origin.y, bound.size.width, bound.size.height);
	
	// draw contour
	ogSetColor(mColorContour);
	//[back stroke];
	ogStrokeRectangle(bound.origin.x, bound.origin.y, bound.size.width, bound.size.height);

	[self drawFunctionAtPoint:origin];
}

- (void) drawFunctionAtPoint:(NSPoint)origin
{
	NSRect bound = { origin, mSize };
	//NSBezierPath *back = [NSBezierPath bezierPathWithRect:bound];
	
	//[NSGraphicsContext saveGraphicsState];
	//[back addClip];
	ogEnableClipRegion(bound.origin.x, bound.origin.y, bound.size.width, bound.size.height);

	//NSAffineTransform *trans = [NSAffineTransform transform];
	//[trans translateXBy:origin.x yBy:origin.y];
	
	//NSBezierPath *front = [mBezierPath copy];
	//[front transformUsingAffineTransform:trans];
	
	// draw front
	ogSetColor(mColorFront);
	
	//[front stroke];
	
	SBPointsBuffer pts = *mPointsBuffer;
	int save = 0;
	
	NSPoint pt = { origin.x, mSize.height - pointCalculate(&pts, 0, &save) * mSize.height + origin.y }, pt2;
	//[mBezierPath moveToPoint:pt];
	
	int c = mSize.width, i;
	for (i = 1; i < c; i++)
	{
		pt2.x = (float)i/(float)c;
		pt2.y = mSize.height - pointCalculate(&pts, pt2.x, &save) * mSize.height + origin.y;
		pt2.x = i + origin.x;
		
		//[mBezierPath lineToPoint:pt];
		ogStrokeLine(pt.x, pt.y, pt2.x, pt2.y);
		pt = pt2;
	}
	
	
	//[front release];

#define kPointRadius (6)
#define kPointDiameter (12)
	
	NSRect ptRect = {{0, 0}, {kPointDiameter, kPointDiameter}};
	//NSColor *hfc = nil;
	
	c = mPointsBuffer->count;
	for (i = 0; i < c; i++)
	{
		float x = origin.x + mPointsBuffer->x[i] * mSize.width;
		ptRect.origin.x = x;
		ptRect.origin.y = origin.y + mSize.height - mPointsBuffer->y[i] * mSize.height;
		
		//NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:ptRect];
		
		if (i == mSelectedPoint)
		{
			//[[NSColor selectedControlColor] set];
			ogSetColor(gSelectedColor);
			
			ogFillCircle(ptRect.origin.x, ptRect.origin.y, kPointRadius);
			//[circle fill];
			//[mColorFront set];
			ogSetColor(mColorFront);
		}
		
		//[circle stroke];
		ogStrokeCircle(ptRect.origin.x, ptRect.origin.y, kPointRadius);
		
		if (mPointsBuffer->move[i] == 1)
		{
			//if (!hfc)
			//{
			//	float r = [mColorFront redComponent];
			//	float g = [mColorFront greenComponent];
			//	float b = [mColorFront blueComponent];
			//	float a = [mColorFront alphaComponent] * 0.5;
			//	hfc = [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
			//}
		
			// NSPoint pt = { x, origin.y }, pt2 = {x, origin.y + mSize.height };
			NSPoint point1 = NSMakePoint(x,origin.y);
			NSPoint point2 = NSMakePoint(x, origin.y + mSize.height);
			
			//[hfc set];
			ogSetColorComp(mColorFront.r, mColorFront.g, mColorFront.b, mColorFront.a * 0.5f);
			
			//[NSBezierPath strokeLineFromPoint:pt toPoint:pt2];
			ogStrokeLine(point1.x, point1.y, point2.x, point2.y);
			
			//[mColorFront set];
			ogSetColor(mColorFront);
		}
	}
	

	//[NSGraphicsContext restoreGraphicsState];
	ogDisableClipRegion();
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	mMouseLock = NO;
	if (x < 0 || x >= mSize.width || y < 0 || y > mSize.height) return NO;
	
	mMouseLock = YES;
	mSelectedPoint = -1;
	BOOL created = NO;
	
	int c = mPointsBuffer->count, i;
	
find:
	for (i = 0; i < c; i++)
	{
		float dist = hypotf(mPointsBuffer->x[i] * mSize.width - x,
							(mSize.height - mPointsBuffer->y[i] * mSize.height) - y);
		if (dist < kPointRadius)
		{
			mSelectedPoint = i;
			break;
		}
	}
	
	if (mSelectedPoint == -1 && clickCount == 2 && !created && mPointsBuffer->count < kMaxNumberOfPoints)
	{
		if (x < 0) x = 0;
		else if (x > mSize.width) x = mSize.width;
	
		if (y < 0) y = 0;
		else if (y > mSize.height) y = mSize.height;
		
		mSelectedPoint = mPointsBuffer->count;
		mPointsBuffer->x[mSelectedPoint] = x / mSize.width;
		mPointsBuffer->y[mSelectedPoint] = (mSize.height - y) / mSize.height;
		mPointsBuffer->move[mSelectedPoint] = 0;
		
		mPointsBuffer->count++;
		
		pointSort(mPointsBuffer);
		if (mPointsBuffer->type == 2) pointSpline(mPointsBuffer);
		mUptodate = NO;
		created = YES;
		
		goto find;
	}
	
	return YES;
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	if (!mMouseLock) return NO;
	if (mSelectedPoint == -1) return NO;
	
	if (mPointsBuffer->move[mSelectedPoint] == 2) return NO;
	
	if (x < 0) x = 0;
	else if (x > mSize.width) x = mSize.width;
	
	if (y < 0) y = 0;
	else if (y > mSize.height) y = mSize.height;
	
	if (mPointsBuffer->move[mSelectedPoint] == 0)
		mPointsBuffer->x[mSelectedPoint] = x / mSize.width;
		
	
	float ny = (mSize.height - y) / mSize.height;
	
	if (mPointsBuffer->move[mSelectedPoint] == 1)
	{
		int c = mPointsBuffer->count, i;
		for (i = 0; i < c; i++)
			if (mPointsBuffer->move[i] == 1)
				mPointsBuffer->y[i] = ny;
	}
	else
		mPointsBuffer->y[mSelectedPoint] = ny;

	pointSort(mPointsBuffer);
	if (mPointsBuffer->type == 2) pointSpline(mPointsBuffer);
	mUptodate = NO;
	
	int c = mPointsBuffer->count, i;
	for (i = 0; i < c; i++)
	{
		float dist = hypotf(mPointsBuffer->x[i] * mSize.width - x,
							(mSize.height - mPointsBuffer->y[i] * mSize.height) - y);
		if (dist < kPointRadius)
		{
			mSelectedPoint = i;
			break;
		}
	}
	
	return YES;
}

- (BOOL) keyDown:(unichar)ukey
{
	if (ukey == NSLeftArrowFunctionKey)
	{
		int type = mPointsBuffer->type;
		
		type--;
		if (type < 0) type = 2;
		
		if (type == 2) pointSpline(mPointsBuffer);
		mPointsBuffer->type = type;
		
		mUptodate = NO;
		return YES;
	}
	
	if (ukey == NSRightArrowFunctionKey)
	{
		int type = mPointsBuffer->type;
		
		type++;
		if (type > 2) type = 0;
		
		if (type == 2) pointSpline(mPointsBuffer);
		mPointsBuffer->type = type;
		
		mUptodate = NO;
		return YES;
	}

	if (mSelectedPoint == -1) return NO;
	
	if (ukey == NSDeleteFunctionKey || ukey == 0x7F)
	{
		if (mPointsBuffer->move[mSelectedPoint] != 0) return NO;
	
		int i, c = mPointsBuffer->count - 1;
		for (i = mSelectedPoint; i < c; i++)
		{
			mPointsBuffer->x[i] = mPointsBuffer->x[i + 1];
			mPointsBuffer->y[i] = mPointsBuffer->y[i + 1];
			mPointsBuffer->move[i] = mPointsBuffer->move[i + 1];
		}

		mPointsBuffer->count--;
		if (mPointsBuffer->type == 2) pointSpline(mPointsBuffer);
	
		mSelectedPoint = -1;
		mUptodate = NO;
		
		return YES;
	}
	
	return NO;
}

@end
