/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFeedforwardComb.h"

#import "SBInterpolation.h"

// y(t) = a*x(t) + b*x(t-dly)

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBFeedforwardComb *obj = inObj;
	
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
		float *buf = obj->mBuffer.floatData; \
		float fsrm1 = samplerate - 1; \
		while(count--) \
		{ \
			float ci = *i++; \
			buf[curPos] = ci; \
			float cd = *d++; \
			cd *= samplerate; \
			if (cd < 0.f) cd = 0.f; else if (cd > fsrm1) cd = fsrm1; \
			*o++ = *a++ * ci + *b++ * _interpf(curPos - cd, buf, samplerate); \
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
		double *buf = obj->mBuffer.doubleData; \
		double fsrm1 = samplerate - 1; \
		while(count--) \
		{ \
			double ci = *i++; \
			buf[curPos] = ci; \
			double cd = *d++; \
			cd *= samplerate; \
			if (cd < 0.) cd = 0.; else if (cd > fsrm1) cd = fsrm1; \
			*o++ = *a++ * ci + *b++ * _interpd(curPos - cd, buf, samplerate); \
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

@implementation SBFeedforwardComb

+ (SBElementCategory) category
{
	return kFilter;
}

+ (NSString*) name
{
	return @"Feedforward Comb";
}

- (NSString*) name
{
	return @"ff comb";
}

- (NSString*) informations
{
	return	@"Feedforward comb, with variable delay, clamped between 0 and 1 sec. "
			@"y(t) = a*x(t) + b*x(t-dly)";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		mBuffer.ptr = nil;
	
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
	if (mBuffer.ptr) free(mBuffer.ptr);
	[super dealloc];
}

- (void) specificPrepare
{
	if (mBuffer.ptr) free(mBuffer.ptr);
	mBuffer.ptr = malloc(mSampleRate * sizeof(double));
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
			mBuffer.doubleData[i] = mBuffer.floatData[i];
	}
	else
	{
		// double to float
		for (i = 0; i < size; i++)
			mBuffer.floatData[i] = mBuffer.doubleData[i];
	}
	
	[super changePrecision:precision];
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

- (BOOL) interpolates
{
	return YES;
}

@end
