/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBCell.h"

@interface SBMeterCell : SBCell
{
	double mValue;
	
	int mWidth;
	int mHeight;
	int mType;
	BOOL mInversed;
	double mMin;
	double mMax;
}

- (void) setValue:(double)value;

- (void) setWidth:(int)w;
- (void) setHeight:(int)h;
- (void) setMin:(double)m;
- (void) setMax:(double)m;
- (void) setType:(int)t;
- (void) setInversed:(BOOL)i;

@end
