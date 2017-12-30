/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBComplexToPolar.h"

#include "SBPow2Table.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBComplexToPolar *obj = inObj;
	if (!count) return;
	
	SBFFTSyncData *data = obj->pInputBuffers[0].fftSyncData;
	if (!data->size) return;
	
	int dataPos = data->offset;
	int fftCountHalf = POW2Table[data->size - 1];
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *ir = obj->pInputBuffers[1].floatData + offset;
		float *ii = obj->pInputBuffers[2].floatData + offset;
		
		float *oa = obj->mAudioBuffers[0].floatData + offset;
		float *op = obj->mAudioBuffers[1].floatData + offset;
		
		while(count--)
		{
			float r = *ir++;
			float i = *ii++;
			
			if (!dataPos)
			{
				*oa++ = r;
				*op++ = i;
			}
			else
			{
				*oa++ = sqrtf(r*r + i*i);
				*op++ = atan2f(i, r);
			}
			
			dataPos++;
			if (dataPos >= fftCountHalf) dataPos = 0;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *ir = obj->pInputBuffers[1].doubleData + offset;
		double *ii = obj->pInputBuffers[2].doubleData + offset;
		
		double *oa = obj->mAudioBuffers[0].doubleData + offset;
		double *op = obj->mAudioBuffers[1].doubleData + offset;
		
		while(count--)
		{
			double r = *ir++;
			double i = *ii++;
			
			if (!dataPos)
			{
				*oa++ = r;
				*op++ = i;
			}
			else
			{
				*oa++ = sqrt(r*r + i*i);
				*op++ = atan2(i, r);
			}
			
			dataPos++;
			if (dataPos >= fftCountHalf) dataPos = 0;
		}
	}

}

@implementation SBComplexToPolar

+ (SBElementCategory) category
{
	return kFFT;
}

+ (NSString*) name
{
	return @"Complex to Polar";
}

- (NSString*) name
{
	return @"cpl2pl";
}

- (NSString*) informations
{
	return	@"Converts complex fft blocks into polar fft blocks.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		[mInputNames addObject:@"sync"];
		[mInputNames addObject:@"real"];
		[mInputNames addObject:@"imag"];
		
		[mOutputNames addObject:@"ampl"];
		[mOutputNames addObject:@"phas"];
	}
	return self;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx == 0) return kFFTSync;
	return kNormal;
}


@end
