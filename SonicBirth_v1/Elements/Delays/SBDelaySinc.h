/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

@interface SBDelaySinc : SBElement
{
@public
	SBBuffer mBuffer;
	int		 mPos;
	double	 mPrevDelay;
}

@end
