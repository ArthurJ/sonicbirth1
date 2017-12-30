/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

@interface SBAudioProcess : NSObject
{
@public
	SBBuffer			pInputBuffers[kMaxChannels];
	SBCalculateFuncPtr	pCalcFunc;
}

- (void) lock;
- (void) unlock;

- (int) numberOfInputs;
- (int) numberOfOutputs;

// allocate buffers
- (void) prepareForSamplingRate:(int)samplingRate
			sampleCount:(int)sampleCount
			precision:(SBPrecision)precision
			interpolation:(SBInterpolation)interpolation;

// change precision of bufffers
- (void) changePrecision:(SBPrecision)precision;

// change type of interpolation
- (void) changeInterpolation:(SBInterpolation)interpolation;

// silence buffers
- (void) reset;

- (SBBuffer) outputAtIndex:(int)idx;

- (BOOL) hasFeedback;
- (BOOL) interpolates;

- (SBPrecision) precision;
- (SBInterpolation) interpolation;

// midi stuff
- (void) dispatchMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offsetToChange;
- (BOOL) hasMidiArguments;
@end
