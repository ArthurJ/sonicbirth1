/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBElement.h"
#include <Accelerate/Accelerate.h>

@interface SBPointsToFFT : SBElement
{
@public
	int				mFFTBlockSize;

	SBBuffer		mFFTDataBuffer;
	
	FFTSetup	mFFFTSetup;
	FFTSetupD	mFFFTSetupD;
	FFTSetup	mIFFTSetup;
	FFTSetupD	mIFFTSetupD;
}

- (void) updateFFTBuffers;

@end
