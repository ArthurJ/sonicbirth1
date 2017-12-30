/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBDelaySample.h"

#define kMaxSamples (100000)

static void privateCalcFunc(void *inObj, int count, int offset)
{
	if (!count) return;
	
	SBDelaySample *obj = inObj;
	int pos = obj->mPos;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float *b = obj->mBuffer.floatData;
		
		while(count--)
		{
			b[pos] = *i++;
			
			int delay = *d++;
			if (delay < 0) delay = 0;
			else if (delay > (kMaxSamples-1)) delay = kMaxSamples-1;
			
			int off = pos - delay;
			if (off < 0) off += kMaxSamples;
			
			*o++ = b[off];
			
			pos++;
			if (pos >= kMaxSamples) pos = 0;
		}
	}
	else
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double *b = obj->mBuffer.doubleData;
		
		while(count--)
		{
			b[pos] = *i++;
			
			int delay = *d++;
			if (delay < 0) delay = 0;
			else if (delay > (kMaxSamples-1)) delay = kMaxSamples-1;
			
			int off = pos - delay;
			if (off < 0) off += kMaxSamples;
			
			*o++ = b[off];
			
			pos++;
			if (pos >= kMaxSamples) pos = 0;
		}
	}
	
	obj->mPos = pos;
}

@implementation SBDelaySample

+ (NSString*) name
{
	return @"Delay (samples)";
}

- (NSString*) name
{
	return @"dly smp";
}

+ (SBElementCategory) category
{
	return kDelay;
}

- (NSString*) informations
{
	return	[NSString stringWithFormat:@"Delays the input signal by a variable time in samples (max: %i).", kMaxSamples];
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;

		mBuffer.ptr = malloc(kMaxSamples * sizeof(double));
		if (!mBuffer.ptr)
		{
			[self release];
			return nil;
		}
	
		[mInputNames addObject:@"in"];
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

- (void) reset
{
	[super reset];
	memset(mBuffer.ptr, 0, kMaxSamples * sizeof(double));
	mPos = 0;
}

- (void) changePrecision:(SBPrecision)precision
{
	if (mPrecision == precision) return;
	
	int i;
	if (mPrecision == kFloatPrecision)
	{
		// float to double
		for (i = kMaxSamples - 1; i >= 0; i--)
			mBuffer.doubleData[i] = mBuffer.floatData[i];
	}
	else
	{
		// double to float
		for (i = 0; i < kMaxSamples; i++)
			mBuffer.floatData[i] = mBuffer.doubleData[i];
	}
	
	[super changePrecision:precision];
}

@end
