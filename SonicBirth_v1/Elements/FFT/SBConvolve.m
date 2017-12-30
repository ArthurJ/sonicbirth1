/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBConvolve.h"

#include "SBPow2Table.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBConvolve *obj = inObj;
	if (!count) return;
	
	SBFFTSyncData *data = obj->pInputBuffers[0].fftSyncData;
	if (!data->size) return;
	
	int dataPos = data->offset;
	int fftCountHalf = POW2Table[data->size - 1];
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *ir1 = obj->pInputBuffers[1].floatData + offset;
		float *ii1 = obj->pInputBuffers[2].floatData + offset;
		float *ir2 = obj->pInputBuffers[3].floatData + offset;
		float *ii2 = obj->pInputBuffers[4].floatData + offset;
		
		float *or = obj->mAudioBuffers[0].floatData + offset;
		float *oi = obj->mAudioBuffers[1].floatData + offset;
		
		while(count--)
		{
			float r1 = *ir1++;
			float i1 = *ii1++;
			float r2 = *ir2++;
			float i2 = *ii2++;
			float r3, i3;

			if (!dataPos)
			{
				r3 = r1 * r2;
				i3 = i1 * i2;
			}
			else
			{
				r3 = r1 * r2 - i1 * i2;
				i3 = r2 * i1 + r1 * i2;
			}
			
			#if 0
			static int test = 2;
			if (test == 1) fprintf(stderr, "dp: %i r1: %f i1: %f r2: %f i2: %f r3: %f i3: %f\n", dataPos, r1, i1, r2, i2, r3, i3);
			#endif
			
			*or++ = r3;
			*oi++ = i3;
			
			dataPos++;
			if (dataPos >= fftCountHalf) dataPos = 0; //{ dataPos = 0; if (test > 0) test--; }
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *ir1 = obj->pInputBuffers[1].doubleData + offset;
		double *ii1 = obj->pInputBuffers[2].doubleData + offset;
		double *ir2 = obj->pInputBuffers[3].doubleData + offset;
		double *ii2 = obj->pInputBuffers[4].doubleData + offset;
		
		double *or = obj->mAudioBuffers[0].doubleData + offset;
		double *oi = obj->mAudioBuffers[1].doubleData + offset;
		
		while(count--)
		{
			double r1 = *ir1++;
			double i1 = *ii1++;
			double r2 = *ir2++;
			double i2 = *ii2++;
			
			if (!dataPos)
			{
				*or++ = r1 * r2;
				*oi++ = i1 * i2;
			}
			else
			{
				*or++ = r1 * r2 - i1 * i2;
				*oi++ = r2 * i1 + r1 * i2;
			}
			
			dataPos++;
			if (dataPos >= fftCountHalf) dataPos = 0;
		}
	}

}

@implementation SBConvolve

+ (SBElementCategory) category
{
	return kFFT;
}

+ (NSString*) name
{
	return @"Convolve";
}

- (NSString*) name
{
	return @"conv";
}

- (NSString*) informations
{
	return	@"Convolve two fft signals (in the complex plane).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		[mInputNames addObject:@"sync"];
		[mInputNames addObject:@"r1"];
		[mInputNames addObject:@"i1"];
		[mInputNames addObject:@"r2"];
		[mInputNames addObject:@"i2"];
		
		[mOutputNames addObject:@"ro"];
		[mOutputNames addObject:@"io"];
	}
	return self;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx == 0) return kFFTSync;
	return kNormal;
}


@end
