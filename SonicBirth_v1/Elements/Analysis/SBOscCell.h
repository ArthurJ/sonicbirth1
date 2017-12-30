/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/#import "SBCell.h"

@interface SBOscCell : SBCell
{
	int	mWidth;
	int mHeight;
	int mSamplesPerPixel;
	double mTop;
	double mBottom;

	float	*mPoints; // size: mWidth * 2, [0 .. mWidth - 1] -> mins, [mWidth .. mWidth * 2 - 1] -> maxs
	int		mCurPoint;
	int		mCurSample;
	float	mCurMin, mCurMax;
	
	BOOL	mFreezeWhenFull;
}

- (void) setFreezeWhenFull:(BOOL)freezeWhenFull;
- (void) setTop:(double)top;
- (void) setBottom:(double)bottom;
- (void) setWidth:(int)width;
- (void) setHeight:(int)height;
- (void) setSamplesPerPixel:(int)samplesPerPixel;

- (void) reset;
- (void) processFloats:(float*)data count:(int)count;
- (void) processDoubles:(double*)data count:(int)count;

@end
