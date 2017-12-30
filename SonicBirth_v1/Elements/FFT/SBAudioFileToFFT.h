/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBElement.h"
#include <Accelerate/Accelerate.h>

@interface SBAudioFileToFFT : SBElement
{
@public
	SBTimeStamp		mLastTS;
	
	int				mFFTBlockSize;
	SBBuffer		mFFTDataBuffer;
	
	FFTSetup	mFFTSetup;
	FFTSetupD	mFFTSetupD;
}

- (void) updateFFTBuffers;

@end
