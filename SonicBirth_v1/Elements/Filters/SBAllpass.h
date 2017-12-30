/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"


@interface SBAllpass : SBElement
{
@public
	int			mCurSample;
	SBBuffer	mBuffer1;
	SBBuffer	mBuffer2;
}

@end
