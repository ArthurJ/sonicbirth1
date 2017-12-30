/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

@interface SBCrossover : SBElement
{
@public
	SBElement *lp1, *lp2;
	SBElement *hp1, *hp2;
}
- (Class) lpClass;
- (Class) hpClass;
@end


@interface SBFastCrossover : SBCrossover
{}
@end
