/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSineWave.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSineWave *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *f = obj->pInputBuffers[0].floatData + offset;
		float *p = obj->pInputBuffers[1].floatData + offset;
		float *tone = obj->mAudioBuffers[0].floatData + offset;
		float phase = obj->mPhase;
		float sr = 1.f / obj->mSampleRate;
		float pi_x_2 = 2.*M_PI;
		while(count--)
		{
			*tone++ = sinf(phase + *p++);
			phase += ((pi_x_2)*(*f++)) * sr;
			if (phase > pi_x_2)
			{
				phase = fmodf(phase, pi_x_2);
				if (phase < 0.f) phase += pi_x_2;
			}
		}
		obj->mPhase = phase;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *f = obj->pInputBuffers[0].doubleData + offset;
		double *p = obj->pInputBuffers[1].doubleData + offset;
		double *tone = obj->mAudioBuffers[0].doubleData + offset;
		double phase = obj->mPhase;
		double sr = 1. / obj->mSampleRate;
		double pi_x_2 = 2.*M_PI;
		while(count--)
		{
			*tone++ = sin(phase + *p++);
			phase += ((pi_x_2)*(*f++)) * sr;
			if (phase > pi_x_2)
			{
				phase = fmod(phase, pi_x_2);
				if (phase < 0.) phase += pi_x_2;
			}
		}
		obj->mPhase = phase;
	}
}


@implementation SBSineWave


+ (NSString*) name
{
	return @"Sine Wave";
}

- (NSString*) name
{
	return @"swave";
}

+ (SBElementCategory) category
{
	return kGenerator;
}

- (NSString*) informations
{
	return @"Generates a sine wave, of frequency f (hz) and phase p (0 to 2pi).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"f"];
		[mInputNames addObject:@"p"];
		
		[mOutputNames addObject:@"tone"];
	}
	return self;
}

- (void) reset
{
	[super reset];

	mPhase = 0.;
}


@end
