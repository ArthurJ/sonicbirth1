/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBRandom.h"

#define kRandomMax ((double)(0x7FFFFFFF))

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBRandom *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *f = obj->pInputBuffers[0].floatData + offset;
		float *rnd = obj->mAudioBuffers[0].floatData + offset;
		float phase = obj->mPhase;
		float sr = 1.f / obj->mSampleRate;
		while(count--)
		{
			*rnd++ = obj->mLastValue;
			phase += (*f++) * sr;
			if (phase > 1.f)
			{
				phase = fmodf(phase, 1.f);
				obj->mLastValue = (((double)random() * 2.) /  kRandomMax) - 1.;
			}
		}
		obj->mPhase = phase;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *f = obj->pInputBuffers[0].doubleData + offset;
		double *rnd = obj->mAudioBuffers[0].doubleData + offset;
		double phase = obj->mPhase;
		double sr = 1. / obj->mSampleRate;
		while(count--)
		{
			*rnd++ = obj->mLastValue;
			phase += (*f++) * sr;
			if (phase > 1.)
			{
				phase = fmod(phase, 1.);
				obj->mLastValue = (((double)random() * 2.) /  kRandomMax) - 1.;
			}
		}
		obj->mPhase = phase;
	}
}

@implementation SBRandom


+ (NSString*) name
{
	return @"Random";
}

- (NSString*) name
{
	return @"rnd";
}

+ (SBElementCategory) category
{
	return kGenerator;
}

- (NSString*) informations
{
	return @"Generates random values between -1 and 1, changing the value at frequency f.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"f"];
	
		[mOutputNames addObject:@"rnd"];
	}
	return self;
}

- (void) reset
{
	[super reset];

	//srandom(time(0));
	mPhase = 0.;
	mLastValue = (((double)random() * 2.) /  kRandomMax) - 1.;
}

@end
