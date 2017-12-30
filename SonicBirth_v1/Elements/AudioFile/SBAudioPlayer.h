/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

@interface SBAudioPlayer : SBElement
{
@public
	SBTimeStamp		mLastTS;
	double			mPos;
	BOOL			mPlaying;
}

@end
