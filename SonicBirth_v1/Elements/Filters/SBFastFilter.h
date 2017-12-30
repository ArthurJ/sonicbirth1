/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFilter.h"


@interface SBFastFilter : SBFilter
{
@public
	int	mType; // 0 lp, 1 hp, 2 res lp, 3 res hp
	
	double mX1, mX2, mY1, mY2;
}
@end

@interface SBFastLowpass : SBFastFilter
{}
@end

@interface SBFastHighpass : SBFastFilter
{}
@end

@interface SBFastResonantLowpass : SBFastFilter
{}
@end

@interface SBFastResonantHighpass : SBFastFilter
{}
@end
