/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAllpass.h"

#import "SBInterpolation.h"

// y(t) = a*x(t) + x(t-dly) - b*y(t-dly)

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBAllpass *obj = inObj;
	
	if (count <= 0) return;
	
	int samplerate = obj->mSampleRate;
	int curPos = obj->mCurSample;
	
#define CALCULATE_FOR_INTERPOLATION(_interpf, _interpd) \
	if (obj->mPrecision == kFloatPrecision) \
	{ \
		float *i = obj->pInputBuffers[0].floatData + offset; \
		float *a = obj->pInputBuffers[1].floatData + offset; \
		float *b = obj->pInputBuffers[2].floatData + offset; \
		float *d = obj->pInputBuffers[3].floatData + offset; \
		float *o = obj->mAudioBuffers[0].floatData + offset; \
		float *buf1 = obj->mBuffer1.floatData; \
		float *buf2 = obj->mBuffer2.floatData; \
		float fsrm1 = samplerate - 1; \
		while(count--) \
		{ \
			float ci = *i++; \
			buf1[curPos] = ci; \
			float cd = *d++; \
			cd *= samplerate; \
			if (cd < 1.f) cd = 1.f; else if (cd > fsrm1) cd = fsrm1; \
			float no = *a++ * ci + _interpf(curPos - cd, buf1, samplerate) - *b++ * _interpf(curPos - cd, buf2, samplerate); \
			*o++ = no; \
			buf2[curPos] = no; \
			curPos++; if (curPos >= samplerate) curPos = 0; \
		} \
	} \
	else if (obj->mPrecision == kDoublePrecision) \
	{ \
		double *i = obj->pInputBuffers[0].doubleData + offset; \
		double *a = obj->pInputBuffers[1].doubleData + offset; \
		double *b = obj->pInputBuffers[2].doubleData + offset; \
		double *d = obj->pInputBuffers[3].doubleData + offset; \
		double *o = obj->mAudioBuffers[0].doubleData + offset; \
		double *buf1 = obj->mBuffer1.doubleData; \
		double *buf2 = obj->mBuffer2.doubleData; \
		double fsrm1 = samplerate - 1; \
		while(count--) \
		{ \
			double ci = *i++; \
			buf1[curPos] = ci; \
			double cd = *d++; \
			cd *= samplerate; \
			if (cd < 1.f) cd = 1.f; else if (cd > fsrm1) cd = fsrm1; \
			double no = *a++ * ci + _interpd(curPos - cd, buf1, samplerate) - *b++ * _interpd(curPos - cd, buf2, samplerate); \
			*o++ = no; \
			buf2[curPos] = no; \
			curPos++; if (curPos >= samplerate) curPos = 0; \
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
	
	obj->mCurSample = curPos;
}

@implementation SBAllpass

+ (SBElementCategory) category
{
	return kFilter;
}

+ (NSString*) name
{
	return @"Allpass";
}

- (NSString*) name
{
	return @"apass";
}

- (NSString*) informations
{
	return	@"Allpass, with variable delay, clamped between 0 and 1 sec. "
			@"Equivalent to a feedback comb filter followed by a "
			@"feedforward comb filter. "
			@"y(t) = a*x(t) + x(t-dly) - b*y(t-dly)";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		mBuffer1.ptr = nil;
		mBuffer2.ptr = nil;
		
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"a"];
		[mInputNames addObject:@"b"];
		[mInputNames addObject:@"dly"];
		
		[mOutputNames addObject:@"out"];
	}
	return self;
}

- (void) dealloc
{
	if (mBuffer1.ptr) free(mBuffer1.ptr);
	if (mBuffer2.ptr) free(mBuffer2.ptr);
	[super dealloc];
}

- (void) specificPrepare
{
	if (mBuffer1.ptr) free(mBuffer1.ptr);
	if (mBuffer2.ptr) free(mBuffer2.ptr);
	mBuffer1.ptr = malloc(mSampleRate * sizeof(double));
	mBuffer2.ptr = malloc(mSampleRate * sizeof(double));
}

- (void) changePrecision:(SBPrecision)precision
{
	if (mPrecision == precision) return;
	
	int i;
	int size = mSampleRate;
	
	if (mPrecision == kFloatPrecision)
	{
		// float to double
		for (i = size - 1; i >= 0; i--)
			mBuffer1.doubleData[i] = mBuffer1.floatData[i];
			
		for (i = size - 1; i >= 0; i--)
			mBuffer2.doubleData[i] = mBuffer2.floatData[i];
	}
	else
	{
		// double to float
		for (i = 0; i < size; i++)
			mBuffer1.floatData[i] = mBuffer1.doubleData[i];
			
		for (i = 0; i < size; i++)
			mBuffer2.floatData[i] = mBuffer2.doubleData[i];
	}
	
	[super changePrecision:precision];
}

- (void) reset
{
	[super reset];

	mCurSample = 0;
	
	if (mPrecision == kFloatPrecision)
	{
		memset(mBuffer1.floatData, 0, mSampleRate * sizeof(float));
		memset(mBuffer2.floatData, 0, mSampleRate * sizeof(float));
	}
	else
	{
		memset(mBuffer1.doubleData, 0, mSampleRate * sizeof(double));
		memset(mBuffer2.doubleData, 0, mSampleRate * sizeof(double));
	}
}

- (BOOL) interpolates
{
	return YES;
}

@end
