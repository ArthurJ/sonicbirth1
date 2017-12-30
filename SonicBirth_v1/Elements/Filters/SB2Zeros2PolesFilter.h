/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFilter.h"

#define kCoeffBase (1)
#define kCoeffCount (20000)
#define kCoeffIndexMax (kCoeffCount - 1)

typedef struct
{
	float a0, a1, a2, b1, b2;
}SB2Z2PCoeffFloat;

typedef struct
{
	double a0, a1, a2, b1, b2;
}SB2Z2PCoeffDouble;

@interface SB2Zeros2PolesFilter : SBFilter
{
@public
	SB2Z2PCoeffFloat mCoeffFloat[kCoeffCount];
	SB2Z2PCoeffDouble mCoeffDouble[kCoeffCount];
	double mX1, mX2, mY1, mY2;
}

@end
