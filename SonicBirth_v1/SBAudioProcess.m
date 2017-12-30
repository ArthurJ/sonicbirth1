/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAudioProcess.h"


static void privateCalcFunc(void *inObj, int count, int offset)
{

}

@implementation SBAudioProcess

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		int i;
		for (i = 0; i < kMaxChannels; i++)
			pInputBuffers[i].ptr = nil;
	}
	return self;
}

- (void) lock
{

}

- (void) unlock
{

}

- (int) numberOfInputs
{
	return 0;
}

- (int) numberOfOutputs
{
	return 0;
}

- (void) prepareForSamplingRate:(int)samplingRate
			sampleCount:(int)sampleCount
			precision:(SBPrecision)precision
			interpolation:(SBInterpolation)interpolation
{

}

- (void) changePrecision:(SBPrecision)precision
{
	
}

- (void) changeInterpolation:(SBInterpolation)interpolation
{

}

- (void) reset
{

}

- (SBBuffer) outputAtIndex:(int)idx
{
	SBBuffer b;
	b.ptr = nil;
	return b;
}

- (BOOL) hasFeedback
{
	return NO;
}

- (BOOL) interpolates
{
	return NO;
}

- (void) dispatchMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offsetToChange
{

}

- (BOOL) hasMidiArguments
{
	return NO;
}

- (SBPrecision) precision
{
	return kFloatPrecision;
}

- (SBInterpolation) interpolation
{
	return kNoInterpolation;
}

@end
