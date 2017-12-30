/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPinkNoise.h"



// http://musicdsp.org/archive.php?classid=1#220

#define kRandomMax ((double)(0x7FFFFFFF))

static const double gA[3] = { 0.02109238, 0.07113478, 0.68873558 }; // rescaled by (1+P)/(1-P)
static const double gP[3] = { 0.3190,  0.7756,  0.9613  };
static const double gRMI2 = 2.0 / kRandomMax; // + 1.0; // change for range [0,1)

//static const double gOffset = gA[0] + gA[1] + gA[2];
static const double gOffset = 0.02109238 + 0.07113478 + 0.68873558;

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBPinkNoise *obj = inObj;
	if (count <= 0) return;

	double *state = obj->mState;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--)
		{
			// unrolled loop
			double temp;
			
			temp = (double)random();
			state[0] = gP[0] * (state[0] - temp) + temp;
			
			temp = (double)random();
			state[1] = gP[1] * (state[1] - temp) + temp;
			
			temp = (double)random();     
			state[2] = gP[2] * (state[2] - temp) + temp;
			
			double result =  ( gA[0] * state[0] + gA[1] * state[1] + gA[2] * state[2] ) * gRMI2 - gOffset;
			
			*o++ = result;
		}
	}
	else
	{
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--)
		{
			// unrolled loop
			double temp;
			
			temp = (double)random();
			state[0] = gP[0] * (state[0] - temp) + temp;
			
			temp = (double)random();
			state[1] = gP[1] * (state[1] - temp) + temp;
			
			temp = (double)random();     
			state[2] = gP[2] * (state[2] - temp) + temp;
			
			double result =  ( gA[0] * state[0] + gA[1] * state[1] + gA[2] * state[2] ) * gRMI2 - gOffset;
			
			*o++ = result;
		}
	}
}

@implementation SBPinkNoise

+ (NSString*) name
{
	return @"Pink Noise";
}

- (NSString*) name
{
	return @"pnoise";
}

+ (SBElementCategory) category
{
	return kGenerator;
}

- (NSString*) informations
{
	return @"Generates pink noise (1/f noise).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		[mOutputNames addObject:@"pnoise"];
	}
	return self;
}

- (void) reset
{
	[super reset];
	mState[0] = mState[1] = mState[2] = 0;
}

@end
