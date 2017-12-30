/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

#define kGainBase (-150)
#define kGainIndexMax (300)
#define kGainCount (301)

#define kFreqBase (20)
#define kFreqIndexMax (19979)
#define kFreqCount (19980)

@interface SBParametricEq : SBElement
{
@public
	float mGainFloatTable[kGainCount];
	float mSinFreqFloatTable[kFreqCount];
	float mCosFreqFloatTable[kFreqCount];
	
	double mGainDoubleTable[kGainCount];
	double mSinFreqDoubleTable[kFreqCount];
	double mCosFreqDoubleTable[kFreqCount];
	
	double mX1, mX2, mY1, mY2;
}

@end
