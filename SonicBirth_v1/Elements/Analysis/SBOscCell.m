/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBOscCell.h"

@implementation SBOscCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mFreezeWhenFull = NO;
		mTop = 1;
		mBottom = -1;
		mWidth = 200;
		mHeight = 100;
		mSamplesPerPixel = 44100 / mWidth;
		mPoints = (float*) malloc(mWidth * 2 * sizeof(float));
		if (!mPoints)
		{
			[self release];
			return nil;
		}
		[self reset];
	}
	return self;
}

- (void) dealloc
{
	if (mPoints) free(mPoints);
	[super dealloc];
}

- (NSSize) contentSize
{
	NSSize s = { mWidth, mHeight }; 
	return s;
}

- (void) setTop:(double)top
{
	mTop = top;
	[self reset];
}

- (void) setBottom:(double)bottom
{
	mBottom = bottom;
	[self reset];
}

- (void) setWidth:(int)width
{
	if (width == mWidth) return;
	mWidth = width;
	if (mWidth < 20) mWidth = 20;
	if (mPoints) { free(mPoints); mPoints = nil; }
	mPoints = (float*) malloc(mWidth * 2 * sizeof(float));
	[self reset];
}

- (void) setHeight:(int)height
{
	mHeight = height;
	if (mHeight < 20) mHeight = 20;
	[self reset];
}

- (void) setSamplesPerPixel:(int)samplesPerPixel
{
	if (mSamplesPerPixel == samplesPerPixel) return;
	mSamplesPerPixel = samplesPerPixel;
	if (mSamplesPerPixel < 1) mSamplesPerPixel = 1;
	[self reset];
}

- (void) reset;
{
	mCurPoint = 0; mCurSample = 0; mCurMin = 0; mCurMax = 0;
	if (mPoints) memset(mPoints, 0, mWidth * 2 * sizeof(float));
}

- (void) processFloats:(float*)data count:(int)count
{
	if (!mPoints) return; float *mins = mPoints, *maxs = mins + mWidth;
	int w = mWidth, cp = mCurPoint, cs = mCurSample, sp = mSamplesPerPixel;
	float t = mTop, b = mBottom, h = mHeight - 1, s = h / (t - b), cmin = mCurMin, cmax = mCurMax;
	if (mFreezeWhenFull && cp >= w) return;
	while(count > 0)
	{
		if (cs == 0)
		{
			float d = *data++;
			cmin = d;
			cmax = d;
			cs++; count--;
		}
		else		
			for( ; cs < sp && count > 0; cs++, count--)
			{
				float d = *data++;
				if (d < cmin) cmin = d;
				else if (d > cmax) cmax = d;
			}
		
		if (cs == sp)
		{
			cs = 0;
			
			cmin = h - (cmin - b)*s;
			cmax = h - (cmax - b)*s;
			
			if (cmin < 0) cmin = 0; else if (cmin >= h) cmin = h - 1;
			if (cmax < 0) cmax = 0; else if (cmax >= h) cmax = h - 1;
			
			cp %= w;
			mins[cp] = cmin;
			maxs[cp] = cmax;
			cp++;
			if (mFreezeWhenFull && cp >= w) return;
			
			cmin = 0;
			cmax = 0;
		}
	}
	
	mCurPoint = cp;
	mCurSample = cs;
	mCurMin = cmin;
	mCurMax = cmax;
}

- (void) processDoubles:(double*)data count:(int)count
{
	if (!mPoints) return; float *mins = mPoints, *maxs = mins + mWidth;
	int w = mWidth, cp = mCurPoint, cs = mCurSample, sp = mSamplesPerPixel;
	float t = mTop, b = mBottom, h = mHeight - 1, s = h / (t - b), cmin = mCurMin, cmax = mCurMax;
	if (mFreezeWhenFull && cp >= w) return;
	while(count > 0)
	{
		if (cs == 0)
		{
			float d = *data++;
			cmin = d;
			cmax = d;
			cs++; count--;
		}
		else		
			for( ; cs < sp && count > 0; cs++, count--)
			{
				float d = *data++;
				if (d < cmin) cmin = d;
				else if (d > cmax) cmax = d;
			}
		
		if (cs == sp)
		{
			cs = 0;
			
			cmin = h - (cmin - b)*s;
			cmax = h - (cmax - b)*s;
			
			if (cmin < 0) cmin = 0; else if (cmin >= h) cmin = h - 1;
			if (cmax < 0) cmax = 0; else if (cmax >= h) cmax = h - 1;
			
			cp %= w;
			mins[cp] = cmin;
			maxs[cp] = cmax;
			cp++;
			if (mFreezeWhenFull && cp >= w) return;
			
			cmin = 0;
			cmax = 0;
		}
	}
	
	mCurPoint = cp;
	mCurSample = cs;
	mCurMin = cmin;
	mCurMax = cmax;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	// draw back
	ogSetColor(mColorBack);
	ogFillRectangle(origin.x, origin.y, mWidth, mHeight);
	
	// draw front
	if (mPoints)
	{
		ogSetColor(mColorFront);
		
		float *mins = mPoints, *maxs = mins + mWidth, j = origin.x;
		float dy1 = origin.y + 1, dy = origin.y;
		int i, c = mWidth, cp = mCurPoint;
		for (i = 0; i < c; i++, j += 1)
		{
			cp %= c;
			float min = mins[cp];
			float max = maxs[cp];
			cp++;
			
			if (min - max < 1.f)
				ogStrokeLine(j, min + dy1, j, max + dy);
			else
				ogStrokeLine(j, min + dy, j, max + dy);
		}
	}
	
	// draw contour
	ogSetColor(mColorContour);
	ogStrokeRectangle(origin.x, origin.y, mWidth, mHeight);
}

- (void) setFreezeWhenFull:(BOOL)freezeWhenFull
{
	mFreezeWhenFull = freezeWhenFull;
}

@end
