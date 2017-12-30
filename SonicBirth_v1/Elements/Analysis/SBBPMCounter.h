/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

#define kMaxEventCount 4
#define kMaxEventCountString @"4"

@interface SBBPMCounter : SBElement
{
@public
	int		mEventCount;
	int		mEvents[kMaxEventCount];
	int		mSamplesSinceLastEvent;
	double	mCurrentBpm;
	double	mLastVal;
}

@end
