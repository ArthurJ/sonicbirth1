/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SB2Zeros2PolesFilter.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SB2Zeros2PolesFilter *obj = inObj;
	
	if (count <= 0) return;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *input = obj->pInputBuffers[0].floatData + offset;
		float *infreq = obj->pInputBuffers[1].floatData + offset;
		float *output = obj->mAudioBuffers[0].floatData + offset;
		SB2Z2PCoeffFloat *coeff = obj->mCoeffFloat;
		SB2Z2PCoeffFloat *cc;
		if (count > 1)
		{
			float *x2 = input, *x1 = x2 + 1, *y2 = output, *y1 = y2 + 1;
			
			int freq = ((int)(*infreq++)) - kCoeffBase;
			if (freq < 0) freq = 0; else if (freq > kCoeffIndexMax) freq = kCoeffIndexMax;
			cc = coeff + freq;
			*output++ = cc->a0**input++ + cc->a1*((float)obj->mX1) + cc->a2*((float)obj->mX2) + cc->b1*((float)obj->mY1) + cc->b2*((float)obj->mY2);
			
			freq = ((int)(*infreq++)) - kCoeffBase;
			if (freq < 0) freq = 0; else if (freq > kCoeffIndexMax) freq = kCoeffIndexMax;
			cc = coeff + freq;
			*output++ = cc->a0**input++ + cc->a1**x2 + cc->a2*((float)obj->mX1) + cc->b1**y2 + cc->b2*((float)obj->mY1);
			
			count -= 2;
			while(count--)
			{
				freq = ((int)(*infreq++)) - kCoeffBase;
				if (freq < 0) freq = 0; else if (freq > kCoeffIndexMax) freq = kCoeffIndexMax;
				cc = coeff + freq;
				*output++ = cc->a0**input++ + cc->a1**x1++ + cc->a2**x2++ + cc->b1**y1++ + cc->b2**y2++;
			}
			obj->mX2 = *x2;	obj->mY2 = *y2;
			obj->mX1 = *x1;	obj->mY1 = *y1;
		}
		else // count == 1
		{
			int freq = ((int)(infreq[0])) - kCoeffBase;
			if (freq < 0) freq = 0; else if (freq > kCoeffIndexMax) freq = kCoeffIndexMax;
			cc = coeff + freq;
			output[0] = cc->a0*input[0] + cc->a1*((float)obj->mX1) + cc->a2*((float)obj->mX2) + cc->b1*((float)obj->mY1) + cc->b2*((float)obj->mY2);
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = input[0];	obj->mY1 = output[0];
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *input = obj->pInputBuffers[0].doubleData + offset;
		double *infreq = obj->pInputBuffers[1].doubleData + offset;
		double *output = obj->mAudioBuffers[0].doubleData + offset;
		SB2Z2PCoeffDouble *coeff = obj->mCoeffDouble;
		SB2Z2PCoeffDouble *cc;
		if (count > 1)
		{
			double *x2 = input, *x1 = x2 + 1, *y2 = output, *y1 = y2 + 1;
			
			int freq = ((int)(*infreq++)) - kCoeffBase;
			if (freq < 0) freq = 0; else if (freq > kCoeffIndexMax) freq = kCoeffIndexMax;
			cc = coeff + freq;
			*output++ = cc->a0**input++ + cc->a1*obj->mX1 + cc->a2*obj->mX2 + cc->b1*obj->mY1 + cc->b2*obj->mY2;
			
			freq = ((int)(*infreq++)) - kCoeffBase;
			if (freq < 0) freq = 0; else if (freq > kCoeffIndexMax) freq = kCoeffIndexMax;
			cc = coeff + freq;
			*output++ = cc->a0**input++ + cc->a1**x2 + cc->a2*obj->mX1 + cc->b1**y2 + cc->b2*obj->mY1;
			
			count -= 2;
			while(count--)
			{
				freq = ((int)(*infreq++)) - kCoeffBase;
				if (freq < 0) freq = 0; else if (freq > kCoeffIndexMax) freq = kCoeffIndexMax;
				cc = coeff + freq;
				*output++ = cc->a0**input++ + cc->a1**x1++ + cc->a2**x2++ + cc->b1**y1++ + cc->b2**y2++;
			}
			obj->mX2 = *x2;	obj->mY2 = *y2;
			obj->mX1 = *x1;	obj->mY1 = *y1;
		}
		else // count == 1
		{
			int freq = ((int)(infreq[0])) - kCoeffBase;
			if (freq < 0) freq = 0; else if (freq > kCoeffIndexMax) freq = kCoeffIndexMax;
			cc = coeff + freq;
			output[0] = cc->a0*input[0] + cc->a1*obj->mX1 + cc->a2*obj->mX2 + cc->b1*obj->mY1 + cc->b2*obj->mY2;
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = input[0];	obj->mY1 = output[0];
		}
	}
}

@implementation SB2Zeros2PolesFilter


- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	}
	return self;
}

- (void) reset
{
	[super reset];
	mX1 = mX2 = mY1 = mY2 = 0.;
}

@end
