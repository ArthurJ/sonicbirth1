/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBPolarToComplex.h"

#include "SBPow2Table.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBPolarToComplex *obj = inObj;
	if (!count) return;
	
	SBFFTSyncData *data = obj->pInputBuffers[0].fftSyncData;
	if (!data->size) return;
	
	int dataPos = data->offset;
	int fftCountHalf = POW2Table[data->size - 1];
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *ia = obj->pInputBuffers[1].floatData + offset;
		float *ip = obj->pInputBuffers[2].floatData + offset;
		
		float *or = obj->mAudioBuffers[0].floatData + offset;
		float *oi = obj->mAudioBuffers[1].floatData + offset;
		
		while(count--)
		{
			float a = *ia++;
			float p = *ip++;
			
			if (!dataPos)
			{
				*or++ = a;
				*oi++ = p;
			}
			else
			{
				*or++ = a * cosf(p);
				*oi++ = a * sinf(p);
			}
			
			dataPos++;
			if (dataPos >= fftCountHalf) dataPos = 0;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *ia = obj->pInputBuffers[1].doubleData + offset;
		double *ip = obj->pInputBuffers[2].doubleData + offset;
		
		double *or = obj->mAudioBuffers[0].doubleData + offset;
		double *oi = obj->mAudioBuffers[1].doubleData + offset;
		
		while(count--)
		{
			double a = *ia++;
			double p = *ip++;
			
			if (!dataPos)
			{
				*or++ = a;
				*oi++ = p;
			}
			else
			{
				*or++ = a * cos(p);
				*oi++ = a * sin(p);
			}
			
			dataPos++;
			if (dataPos >= fftCountHalf) dataPos = 0;
		}
	}

}

@implementation SBPolarToComplex

+ (SBElementCategory) category
{
	return kFFT;
}

+ (NSString*) name
{
	return @"Polar to Complex";
}

- (NSString*) name
{
	return @"pl2cpl";
}

- (NSString*) informations
{
	return	@"Converts polar fft blocks into complex fft blocks.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		[mInputNames addObject:@"sync"];
		[mInputNames addObject:@"ampl"];
		[mInputNames addObject:@"phas"];
		
		[mOutputNames addObject:@"real"];
		[mOutputNames addObject:@"imag"];
	}
	return self;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx == 0) return kFFTSync;
	return kNormal;
}


@end
