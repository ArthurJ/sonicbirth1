/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBTriangleWave.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBTriangleWave *obj = inObj;
	
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
			wp = *p++ * (4.f / (2.f * (float)M_PI));
			if (wp < 0.f) wp = 0.f; else if (wp > 4.f) wp = 4.f;
			
			wp += phase;
			while (wp > 4.f) wp -= 4.f;
			
			if (wp < 2.f) *twave++ = wp - 1.f;
			else *twave++ = 3.f - wp;
			
			phase += (4.f * (*f++)) * sr;
			if (phase > 4.f)
			{
				phase = fmodf(phase, 4.f);
				if (phase < 0.f) phase += 4.f;
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
			wp = *p++ * (4. / (2. * M_PI));
			if (wp < 0.) wp = 0.; else if (wp > 4.) wp = 4.;
			
			wp += phase;
			while (wp > 4.) wp -= 4.;
			
			if (wp < 2.) *twave++ = wp - 1.;
			else *twave++ = 3. - wp;
			
			phase += (4. * (*f++)) * sr;
			if (phase > 4.)
			{
				phase = fmod(phase, 4.);
				if (phase < 0.) phase += 4.;
			}
		}
		obj->mPhase = phase;
	}
}

@implementation SBTriangleWave


+ (NSString*) name
{
	return @"Triangle Wave";
}

- (NSString*) name
{
	return @"twave";
}

+ (SBElementCategory) category
{
	return kGenerator;
}

- (NSString*) informations
{
	return @"Generates a triangle wave, of frequency f (hz) and phase p (0 to 2pi).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"f"];
		[mInputNames addObject:@"p"];
		
		[mOutputNames addObject:@"twave"];
	}
	return self;
}

- (void) reset
{
	[super reset];

	mPhase = 0.;
}


@end
