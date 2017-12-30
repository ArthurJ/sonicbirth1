/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSawWave.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSawWave *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *f = obj->pInputBuffers[0].floatData + offset;
		float *p = obj->pInputBuffers[1].floatData + offset;
		float *twave = obj->mAudioBuffers[0].floatData + offset;
		float phase = obj->mPhase;
		float sr = 1.f / obj->mSampleRate;
		float wp;
		while(count--)
		{
			wp = *p++ * (2.f / (2.f * (float)M_PI));
			if (wp < 0.f) wp = 0.f; else if (wp > 2.f) wp = 2.f;
			
			wp += phase;
			while (wp > 2.f) wp -= 2.f;
		
			*twave++ = wp - 1.f;
			
			phase += (2.f * (*f++)) * sr;
			if (phase > 2.f)
			{
				phase = fmodf(phase, 2.f);
				if (phase < 0.f) phase += 2.f;
			}
		}
		obj->mPhase = phase;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *f = obj->pInputBuffers[0].doubleData + offset;
		double *p = obj->pInputBuffers[1].doubleData + offset;
		double *twave = obj->mAudioBuffers[0].doubleData + offset;
		double phase = obj->mPhase;
		double sr = 1. / obj->mSampleRate;
		double wp;
		while(count--)
		{
			wp = *p++ * (2. / (2. * M_PI));
			if (wp < 0.) wp = 0.; else if (wp > 2.) wp = 2.;
			
			wp += phase;
			while (wp > 2.) wp -= 2.;
		
			*twave++ = wp - 1.;
			
			phase += (2. * (*f++)) * sr;
			if (phase > 2.)
			{
				phase = fmod(phase, 2.);
				if (phase < 0.) phase += 2.;
			}
		}
		obj->mPhase = phase;
	}
}

@implementation SBSawWave


+ (NSString*) name
{
	return @"Saw Wave";
}

- (NSString*) name
{
	return @"sawave";
}

+ (SBElementCategory) category
{
	return kGenerator;
}

- (NSString*) informations
{
	return @"Generates a saw wave, of frequency f (hz) and phase p (0 to 2pi).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"f"];
		[mInputNames addObject:@"p"];
		
		[mOutputNames addObject:@"sawave"];
	}
	return self;
}

- (void) reset
{
	[super reset];

	mPhase = 0.;
}


@end
