/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBScraper.h"

#import "SBInterpolation.h"

/*
	Readable code:
	
	float *a = obj->pInputBuffers[0].floatData + offset;
	float *sr = obj->pInputBuffers[1].floatData + offset;
	float *bd = obj->pInputBuffers[2].floatData + offset;
	float *o = obj->mAudioBuffers[0].floatData + offset;
	float *buf = obj->mBuffer.floatData;
	float cursr = obj->mSampleRate;
	
	while(count--)
	{
		buf[cursample] = *a++;
		if (cursample >= bufsize) cursample = 0;
		
		// get params
		float tsr = *sr++;
		float tbd = *bd++;
		if (tsr > 1.f) tsr = 1.f; else if (tsr < 0.f) tsr = 0.f;
		if (tbd > 1.f) tbd = 1.f; else if (tbd < 0.f) tbd = 0.f;
		
		// degrade sample rate
		float nval;
		if (tsr == 0.f) nval = buf[0];
		else if (tsr < 1.f)
		{
			// start at half sample rate
			// apply curve to tsr
			float mod = 2.f / (tsr * tsr);
			if (mod > cursr) mod =  cursr;
			float index = cursample - fmodf(cursample, mod);

			nval = interpolate(index, buf, bufsize);
		}
		else nval = buf[cursample];
		
		// degrade bit depth
		if (tbd < 1.f)
		{
			float mod = 1.f / powf(2.f, tbd * 12.f);
			
			// quant away from zero
			if (nval > 0.f) nval = nval + mod - fmodf(nval, mod);
			else nval = nval - mod + fmodf(nval, mod);
		}
		
		cursample++;
		if (cursample >= bufsize) cursample = 0;
		*o++ = nval;
	}
*/

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBScraper *obj = inObj;
	
	int cursample = obj->mCurSample;
	int bufsize = obj->mSampleRate;

#define CALCULATE_FOR_INTERPOLATION(_interpf, _interpd) \
	if (obj->mPrecision == kFloatPrecision) \
	{ \
		float *a = obj->pInputBuffers[0].floatData + offset; \
		float *sr = obj->pInputBuffers[1].floatData + offset; \
		float *bd = obj->pInputBuffers[2].floatData + offset; \
		float *o = obj->mAudioBuffers[0].floatData + offset; \
		float *buf = obj->mBuffer.floatData; \
		float cursr = obj->mSampleRate - 1; \
		while(count--) \
		{ \
			buf[cursample] = *a++; if (cursample >= bufsize) cursample = 0; \
			float tsr = *sr++; float tbd = *bd++; \
			if (tsr > 1.f) tsr = 1.f; else if (tsr < 0.f) tsr = 0.f; \
			if (tbd > 1.f) tbd = 1.f; else if (tbd < 0.f) tbd = 0.f; \
			float nval; if (tsr == 0.f) nval = buf[0]; \
			else if (tsr < 1.f) \
			{ \
				float mod = 2.f / (tsr * tsr); \
				if (mod > cursr) mod = cursr; \
				float index = cursample - fmodf(cursample, mod); \
				nval = _interpf(index, buf, bufsize); \
			} else nval = buf[cursample]; \
			if (tbd < 1.f) \
			{ \
				float mod = 1.f / powf(2.f, tbd * 12.f); \
				if (nval > 0.f) nval = nval + mod - fmodf(nval, mod); \
				else nval = nval - mod + fmodf(nval, mod); \
			} \
			cursample++; \
			if (cursample >= bufsize) cursample = 0; \
			*o++ = nval; \
		} \
	} \
	else if (obj->mPrecision == kDoublePrecision) \
	{ \
		double *a = obj->pInputBuffers[0].doubleData + offset; \
		double *sr = obj->pInputBuffers[1].doubleData + offset; \
		double *bd = obj->pInputBuffers[2].doubleData + offset; \
		double *o = obj->mAudioBuffers[0].doubleData + offset; \
		double *buf = obj->mBuffer.doubleData; \
		double cursr = obj->mSampleRate - 1; \
		while(count--) \
		{ \
			buf[cursample] = *a++; \
			if (cursample >= bufsize) cursample = 0; \
			double tsr = *sr++; double tbd = *bd++; \
			if (tsr > 1.) tsr = 1.; else if (tsr < 0.) tsr = 0.; \
			if (tbd > 1.) tbd = 1.; else if (tbd < 0.) tbd = 0.; \
			double nval; if (tsr == 0.f) nval = buf[0]; \
			else if (tsr < 1.) \
			{ \
				double mod = 2. / (tsr * tsr); \
				if (mod > cursr) mod = cursr; \
				double index = cursample - fmod(cursample, mod); \
				nval = _interpd(index, buf, bufsize); \
			} else nval = buf[cursample]; \
			if (tbd < 1.) \
			{ \
				double mod = 1. / pow(2., tbd * 12.); \
				if (nval > 0.) nval = nval + mod - fmod(nval, mod); \
				else nval = nval - mod + fmod(nval, mod); \
			} \
			cursample++; \
			if (cursample >= bufsize) cursample = 0; \
			*o++ = nval; \
		} \
	}
	
	switch(obj->mInterpolation)
	{
		case kNoInterpolation:
			CALCULATE_FOR_INTERPOLATION(interpolate_float_no, interpolate_double_no)
			break;
			
		case kInterpolationLinear:
			CALCULATE_FOR_INTERPOLATION(interpolate_float_lin, interpolate_double_lin)
			break;
	}
	
	#undef CALCULATE_FOR_INTERPOLATION
	
	obj->mCurSample = cursample;
}

@implementation SBScraper

+ (NSString*) name
{
	return @"Scraper";
}

- (NSString*) name
{
	return @"scrap";
}

+ (SBElementCategory) category
{
	return kDistortion;
}

- (NSString*) informations
{
	return @"Degrades quality of sampling rate, and bit depth (parameters in the range [0, 1], "
			@"where 0 is lowest quality and 1 is original signal).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"sr"];
		[mInputNames addObject:@"bd"];
		
		[mOutputNames addObject:@"out"];
		
		mBuffer.ptr = nil;
	}
	return self;
}

- (void) dealloc
{
	if (mBuffer.ptr) free(mBuffer.ptr);
	[super dealloc];
}

- (void) reset
{
	[super reset];
	
	mCurSample = 0;
	
	if (mPrecision == kFloatPrecision)
		memset(mBuffer.floatData, 0, mSampleRate * sizeof(float));
	else
		memset(mBuffer.doubleData, 0, mSampleRate * sizeof(double));
}

- (void) specificPrepare
{
	if (mBuffer.ptr) free(mBuffer.ptr);
	mBuffer.ptr = malloc(mSampleRate * sizeof(double));
}

- (void) changePrecision:(SBPrecision)precision
{
	int i;
	
	if (mPrecision == precision) return;
	if (mPrecision == kFloatPrecision)
	{
		// float to double
		for (i = mSampleRate - 1; i >= 0; i--)
			mBuffer.doubleData[i] = mBuffer.floatData[i];
	}
	else
	{
		// double to float
		for (i = 0; i < mSampleRate; i++)
			mBuffer.floatData[i] = mBuffer.doubleData[i];
	}
	
	[super changePrecision:precision];
}

- (BOOL) interpolates
{
	return YES;
}

@end
