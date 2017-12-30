/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBScraperQuick.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBScraperQuick *obj = inObj;
	
	int samplerate = obj->mSampleRate;
	int bufsize = samplerate;
	int cursample = obj->mCurSample;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *a = obj->pInputBuffers[0].floatData + offset;
		float *sr = obj->pInputBuffers[1].floatData + offset;
		float *bd = obj->pInputBuffers[2].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float *buf = obj->mBuffer.floatData;
		while(count--)
		{
			buf[cursample] = *a++;
			float tsr = *sr++;
			float tbd = *bd++;
			float nval;
			
			if (tsr < 1.f)
			{
				int mod = 2.f / (tsr * tsr);
				if (mod > samplerate) mod = samplerate;
				else if (mod < 1) mod = 1;
				
				int idx = cursample - cursample % mod;
				while (idx >= bufsize) idx -= bufsize;
				while (idx < 0) idx += bufsize;
				
				nval = buf[idx];
			}
			else
				nval = buf[cursample];
			
			if (tbd <= 0.f)
			{
				nval = signf(nval);
			}
			else if (tbd < 1.f)
			{
				if (nval > 1.f) nval = 1.f;
				else if (nval < -1.f) nval = -1.f;
				else
				{
					int data = nval * (1 << 12);
					if (!data) nval = 0.f;
					else
					{
						int mod = (1 << (int)((1.f - tbd) * 12));
						if (data > 0) data = data + mod - data % mod;
						else data = data - mod + data % mod;
						nval = (float)data / (1 << 12);
					}
				}
			}
			
			*o++ = nval;
			cursample++; if (cursample >= bufsize) cursample = 0;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *a = obj->pInputBuffers[0].doubleData + offset;
		double *sr = obj->pInputBuffers[1].doubleData + offset;
		double *bd = obj->pInputBuffers[2].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double *buf = obj->mBuffer.doubleData;
		while(count--)
		{
			buf[cursample] = *a++;
			double tsr = *sr++;
			double tbd = *bd++;
			double nval;
			
			if (tsr < 1.)
			{
				int mod = 2. / (tsr * tsr);
				if (mod > samplerate) mod = samplerate;
				else if (mod < 1) mod = 1;
				
				int idx = cursample - cursample % mod;
				while (idx >= bufsize) idx -= bufsize;
				while (idx < 0) idx += bufsize;
				
				nval = buf[idx];
			}
			else
				nval = buf[cursample];
			
			if (tbd <= 0.)
			{
				nval = signf(nval);
			}
			else if (tbd < 1.)
			{
				if (nval > 1.) nval = 1.;
				else if (nval < -1.) nval = -1.;
				else
				{
					int data = nval * (1 << 12);
					if (!data) nval = 0.f;
					else
					{
						int mod = (1 << (int)((1. - tbd) * 12));
						if (data > 0) data = data + mod - data % mod;
						else data = data - mod + data % mod;
						nval = (double)data / (1 << 12);
					}
				}
			}
			
			*o++ = nval;
			cursample++; if (cursample >= bufsize) cursample = 0;
		}
	}

	obj->mCurSample = cursample;
}

@implementation SBScraperQuick

+ (NSString*) name
{
	return @"Scraper (quick)";
}

- (NSString*) name
{
	return @"scrap qck";
}

+ (SBElementCategory) category
{
	return kDistortion;
}

- (NSString*) informations
{
	return	@"Degrades quality of sampling rate, and bit depth (parameters in the range [0, 1], "
			@"where 0 is lowest quality and 1 is original signal). "
			@"Less precise but faster version.";
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

@end
