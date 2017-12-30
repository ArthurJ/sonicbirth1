/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBElement.h"
#include <Accelerate/Accelerate.h>

@interface SBFFTGenerator : SBElement
{
@public
	FFTSetupD	mFFTSetup;
	
	double		*mBuf;

	int			mPosition;
	SBPointsBuffer mPts;
}

@end
