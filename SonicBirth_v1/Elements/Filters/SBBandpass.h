/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

@interface SBBandpass : SBElement
{
@public
	SBElement *lp1, *lp2;
	SBElement *hp1, *hp2;
	SBElement *sort;
}
- (Class) lpClass;
- (Class) hpClass;
- (Class) sortClass;
@end


@interface SBFastBandpass : SBBandpass
{}
@end
