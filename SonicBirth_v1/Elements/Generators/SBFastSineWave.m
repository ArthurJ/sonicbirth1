/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBFastSineWave.h"

// http://www.active-web.cc/html/research/sine/sin-cos.txt
// http://web.archive.org/web/20060824042538/http://www.active-web.cc/html/research/sine/sin-cos.txt

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBFastSineWave *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *f = obj->pInputBuffers[0].floatData + offset;
		float *t = obj->mAudioBuffers[0].floatData + offset;
		float sinV = obj->mSin; if (sinV > 1.f) sinV = 1.f; else if (sinV < -1.f) sinV = -1.f;
		float cosV = obj->mCos; if (cosV > 1.f) cosV = 1.f; else if (cosV < -1.f) cosV = -1.f;
		if (isnan(sinV) ||isinf(sinV) ||isnan(cosV) || isinf(cosV)) { cosV = 1.f; sinV = 0.f; };
		float st =  (2.*M_PI) / obj->mSampleRate;
		while(count--)
		{
			float fr = *f++ * st;
			cosV -= sinV * fr;
			sinV += cosV * fr;
			*t++ = sinV;
		}
		if (sabsf(sinV*sinV + cosV*cosV - 1.f) > 1.f)
			cosV = sqrtf(1.f - sinV*sinV);
		obj->mSin = sinV;
		obj->mCos = cosV;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *f = obj->pInputBuffers[0].doubleData + offset;
		double *t = obj->mAudioBuffers[0].doubleData + offset;
		double sinV = obj->mSin; if (sinV > 1.) sinV = 1.; else if (sinV < -1.) sinV = -1.;
		double cosV = obj->mCos; if (cosV > 1.) cosV = 1.; else if (cosV < -1.) cosV = -1.;
		if (isnan(sinV) ||isinf(sinV) ||isnan(cosV) || isinf(cosV)) { cosV = 1.; sinV = 0.; };
		double st =  (2.*M_PI) / obj->mSampleRate;
		while(count--)
		{
			double fr = *f++ * st;
			cosV -= sinV * fr;
			sinV += cosV * fr;
			*t++ = sinV;
		}
		if (sabs(sinV*sinV + cosV*cosV - 1.) > 1.)
			cosV = sqrt(1. - sinV*sinV);
		obj->mSin = sinV;
		obj->mCos = cosV;
	}
}

@implementation SBFastSineWave


+ (NSString*) name
{
	return @"Fast Sine Wave";
}

- (NSString*) name
{
	return @"fswave";
}

+ (SBElementCategory) category
{
	return kGenerator;
}

- (NSString*) informations
{
	return @"Generates a sine wave, of frequency f (hz). Low cpu usage.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"f"];
		
		[mOutputNames addObject:@"tone"];
	}
	return self;
}

- (void) reset
{
	[super reset];

	mSin = 0;
	mCos = 1;
}

@end
