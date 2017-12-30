/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBFastFilter.h"

#include <math.h> // for M_PI

#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBFastFilter *obj = inObj;
	if (count <= 0) return;
	
	float cf[5];
	double cd[5];
	
	double f = 0, r = 0;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		switch(obj->mType)
		{
			case 2: // res lp
			case 3: // res hp
				r = obj->pInputBuffers[2].floatData[offset];
				// passthrough
		
			case 0: // lp
			case 1: // hp
				f = obj->pInputBuffers[1].floatData[offset];
				break;
		}
	}
	else
	{
		switch(obj->mType)
		{
			case 2: // res lp
			case 3: // res hp
				r = obj->pInputBuffers[2].doubleData[offset];
				// passthrough
		
			case 0: // lp
			case 1: // hp
				f = obj->pInputBuffers[1].doubleData[offset];
				break;
		}
	}
	
	double sampleRate = obj->mSampleRate;
	double sampleRateHalf = sampleRate * 0.5;
	
	if (f < 1) f = 1;
	else if (f > sampleRateHalf) f = sampleRateHalf;
	
	switch(obj->mType)
	{
		case 0: // lp
			{
				double c = 1. / tan(M_PI * f / sampleRate);
				double g = 1.;
				double p = sqrt(2.);
			
				double k = c*c + p*c + g;
			
				double a0 = 1. / (g*k);
				double a1 = a0+a0;
				double a2 = a0;
				double b1 = 2. * (g - c*c) / k;
				double b2 = (c*c - p*c +g) / k;
				
				cd[0] = a0;
				cd[1] = a1;
				cd[2] = a2;
				cd[3] = b1;
				cd[4] = b2;
			}
			break;
			
		case 1: // hp
			{
				double c = tan(M_PI * f / sampleRate);
				double g = 1.;
				double p = sqrt(2.);
				
				double k = c*c + p*c + g;
				
				double a0 = 1. / (g*k);
				double a1 = a0+a0;
				double a2 = a0;
				double b1 = 2. * (g - c*c) / k;
				double b2 = (c*c - p*c +g) / k;
				
				cd[0] = a0;
				cd[1] = -a1;
				cd[2] = a2;
				cd[3] = -b1;
				cd[4] = b2;
			}
			break;
			
		case 2: // res lp
			{
				if (r < 0.1) r = 0.1; else if (r > 1.415) r = 1.415;
				
				double c = 1. / tan(M_PI * f / sampleRate);
				double g = 1.;
				double k = c*c + r*c + g;
				
				double a0 = 1. / (g*k);
				double a1 = a0+a0;
				double a2 = a0;
				double b1 = 2. * (g - c*c) / k;
				double b2 = (c*c - r*c +g) / k;
				
				cd[0] = a0;
				cd[1] = a1;
				cd[2] = a2;
				cd[3] = b1;
				cd[4] = b2;
			}
			break;
			
		case 3: // res hp
			{
				if (r < 0.1) r = 0.1; else if (r > 1.415) r = 1.415;

				double c = tan(M_PI * f / sampleRate);
				double g = 1.;
				double k = c*c + r*c + g;
				
				double a0 = 1. / (g*k);
				double a1 = -(a0+a0);
				double a2 = a0;
				double b1 = -(2. * (g - c*c) / k);
				double b2 = (c*c - r*c +g) / k;
				
				cd[0] = a0;
				cd[1] = a1;
				cd[2] = a2;
				cd[3] = b1;
				cd[4] = b2;
			}
			break;
	}
	

	if (obj->mPrecision == kFloatPrecision)
	{
		cf[0] = cd[0]; cf[1] = cd[1]; cf[2] = cd[2]; cf[3] = cd[3]; cf[4] = cd[4];
	
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		
		if (count > 1)
		{
			float *oi = i, *oo = o;
		
			*o++ = cf[0]**i++ + cf[1]*((float)obj->mX1) + cf[2]*((float)obj->mX2) - cf[3]*((float)obj->mY1) - cf[4]*((float)obj->mY2);
			*o++ = cf[0]**i++ + cf[1]**oi				+ cf[2]*((float)obj->mX1) - cf[3]**oo				- cf[4]*((float)obj->mY1);
			
			vDSP_deq22(oi, 1, cf, oo, 1, count - 2);
		
			obj->mX2 = oi[count - 2]; obj->mY2 = oo[count - 2];
			obj->mX1 = oi[count - 1]; obj->mY1 = oo[count - 1];
		}
		else // count == 1
		{
			o[0] = cf[0]*i[0] + cf[1]*((float)obj->mX1) + cf[2]*((float)obj->mX2) - cf[3]*((float)obj->mY1) - cf[4]*((float)obj->mY2);
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = i[0];		obj->mY1 = o[0];
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		
		if (count > 1)
		{
			double *oi = i, *oo = o;
		
			*o++ = cd[0]**i++ + cd[1]*obj->mX1 + cd[2]*obj->mX2 - cd[3]*obj->mY1 - cd[4]*obj->mY2;
			*o++ = cd[0]**i++ + cd[1]**oi	   + cd[2]*obj->mX1 - cd[3]**oo		 - cd[4]*obj->mY1;
			
			vDSP_deq22D(oi, 1, cd, oo, 1, count - 2);
		
			obj->mX2 = oi[count - 2]; obj->mY2 = oo[count - 2];
			obj->mX1 = oi[count - 1]; obj->mY1 = oo[count - 1];
		}
		else // count == 1
		{
			o[0] = cd[0]*i[0] + cd[1]*obj->mX1 + cd[2]*obj->mX2 - cd[3]*obj->mY1 - cd[4]*obj->mY2;
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = i[0];		obj->mY1 = o[0];
		}
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBFastFilter *obj = inObj;
	if (count <= 0) return;
	
	float cf[5];
	double cd[5];
	
	double f = 0, r = 0;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		switch(obj->mType)
		{
			case 2: // res lp
			case 3: // res hp
				r = obj->pInputBuffers[2].floatData[offset];
				// passthrough
		
			case 0: // lp
			case 1: // hp
				f = obj->pInputBuffers[1].floatData[offset];
				break;
		}
	}
	else
	{
		switch(obj->mType)
		{
			case 2: // res lp
			case 3: // res hp
				r = obj->pInputBuffers[2].doubleData[offset];
				// passthrough
		
			case 0: // lp
			case 1: // hp
				f = obj->pInputBuffers[1].doubleData[offset];
				break;
		}
	}
	
	double sampleRate = obj->mSampleRate;
	double sampleRateHalf = sampleRate * 0.5;
	
	if (f < 1) f = 1;
	else if (f > sampleRateHalf) f = sampleRateHalf;
	
	switch(obj->mType)
	{
		case 0: // lp
			{
				double c = 1. / tan(M_PI * f / sampleRate);
				double g = 1.;
				double p = sqrt(2.);
			
				double k = c*c + p*c + g;
			
				double a0 = 1. / (g*k);
				double a1 = a0+a0;
				double a2 = a0;
				double b1 = 2. * (g - c*c) / k;
				double b2 = (c*c - p*c +g) / k;
				
				cd[0] = a0;
				cd[1] = a1;
				cd[2] = a2;
				cd[3] = b1;
				cd[4] = b2;
			}
			break;
			
		case 1: // hp
			{
				double c = tan(M_PI * f / sampleRate);
				double g = 1.;
				double p = sqrt(2.);
				
				double k = c*c + p*c + g;
				
				double a0 = 1. / (g*k);
				double a1 = a0+a0;
				double a2 = a0;
				double b1 = 2. * (g - c*c) / k;
				double b2 = (c*c - p*c +g) / k;
				
				cd[0] = a0;
				cd[1] = -a1;
				cd[2] = a2;
				cd[3] = -b1;
				cd[4] = b2;
			}
			break;
			
		case 2: // res lp
			{
				if (r < 0.1) r = 0.1; else if (r > 1.415) r = 1.415;
				
				double c = 1. / tan(M_PI * f / sampleRate);
				double g = 1.;
				double k = c*c + r*c + g;
				
				double a0 = 1. / (g*k);
				double a1 = a0+a0;
				double a2 = a0;
				double b1 = 2. * (g - c*c) / k;
				double b2 = (c*c - r*c +g) / k;
				
				cd[0] = a0;
				cd[1] = a1;
				cd[2] = a2;
				cd[3] = b1;
				cd[4] = b2;
			}
			break;
			
		case 3: // res hp
			{
				if (r < 0.1) r = 0.1; else if (r > 1.415) r = 1.415;

				double c = tan(M_PI * f / sampleRate);
				double g = 1.;
				double k = c*c + r*c + g;
				
				double a0 = 1. / (g*k);
				double a1 = -(a0+a0);
				double a2 = a0;
				double b1 = -(2. * (g - c*c) / k);
				double b2 = (c*c - r*c +g) / k;
				
				cd[0] = a0;
				cd[1] = a1;
				cd[2] = a2;
				cd[3] = b1;
				cd[4] = b2;
			}
			break;
	}
	

	if (obj->mPrecision == kFloatPrecision)
	{
		cf[0] = cd[0]; cf[1] = cd[1]; cf[2] = cd[2]; cf[3] = cd[3]; cf[4] = cd[4];
	
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		
		if (count > 1)
		{
			float *x2 = i, *x1 = x2 + 1, *y2 = o, *y1 = y2 + 1;
		
			*o++ = cf[0]**i++ + cf[1]*((float)obj->mX1) + cf[2]*((float)obj->mX2) - cf[3]*((float)obj->mY1) - cf[4]*((float)obj->mY2);
			*o++ = cf[0]**i++ + cf[1]**x2				+ cf[2]*((float)obj->mX1) - cf[3]**y2				- cf[4]*((float)obj->mY1);
			
			count -= 2;
			while(count--)
			*o++ = cf[0]**i++ + cf[1]**x1++				+ cf[2]**x2++			  - cf[3]**y1++				- cf[4]**y2++;
		
			obj->mX2 = *x2;	obj->mY2 = *y2;
			obj->mX1 = *x1;	obj->mY1 = *y1;
		}
		else // count == 1
		{
			o[0] = cf[0]*i[0] + cf[1]*((float)obj->mX1) + cf[2]*((float)obj->mX2) - cf[3]*((float)obj->mY1) - cf[4]*((float)obj->mY2);
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = i[0];		obj->mY1 = o[0];
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		
		if (count > 1)
		{
			double *x2 = i, *x1 = x2 + 1, *y2 = o, *y1 = y2 + 1;
		
			*o++ = cd[0]**i++ + cd[1]*obj->mX1 + cd[2]*obj->mX2 - cd[3]*obj->mY1 - cd[4]*obj->mY2;
			*o++ = cd[0]**i++ + cd[1]**x2	   + cd[2]*obj->mX1 - cd[3]**y2		 - cd[4]*obj->mY1;
			
			count -= 2;
			while(count--)
			*o++ = cd[0]**i++ + cd[1]**x1++	   + cd[2]**x2++	- cd[3]**y1++	 - cd[4]**y2++;
		
			obj->mX2 = *x2;	obj->mY2 = *y2;
			obj->mX1 = *x1;	obj->mY1 = *y1;
		}
		else // count == 1
		{
			o[0] = cd[0]*i[0] + cd[1]*obj->mX1 + cd[2]*obj->mX2 - cd[3]*obj->mY1 - cd[4]*obj->mY2;
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = i[0];		obj->mY1 = o[0];
		}
	}
}


@implementation SBFastFilter
- (id) init
{
	self = [super init];
	if (self != nil)
	{
#if (MAX_OS_VERSION_USE >= 4)
		pCalcFunc = (frameworkOSVersion() >= 4) ? privateCalcFuncFast : privateCalcFunc;
#else
		pCalcFunc = privateCalcFunc;
#endif
	}
	return self;
}

- (void) reset
{
	[super reset];
	mX1 = mX2 = mY1 = mY2 = 0.;
}
@end

@implementation SBFastLowpass
- (id) init { self = [super init]; if (self != nil) { mType = 0; } return self; }
+ (NSString*) name { return @"Lowpass (fast)"; }
- (NSString*) name { return @"flpass"; }
- (NSString*) informations { return @"Same as lowpass, but only checks its parameter once per audio cycle."; }
@end

@implementation SBFastHighpass
- (id) init { self = [super init]; if (self != nil) { mType = 1; } return self; }
+ (NSString*) name { return @"Highpass (fast)"; }
- (NSString*) name { return @"fhpass"; }
- (NSString*) informations { return @"Same as highpass, but only checks its parameter once per audio cycle."; }
@end

@implementation SBFastResonantLowpass
- (id) init { self = [super init]; if (self != nil) { mType = 2; [mInputNames addObject:@"r"]; } return self; }
+ (NSString*) name { return @"Resonant lowpass (fast)"; }
- (NSString*) name { return @"res.flpass"; }
- (NSString*) informations { return @"Same as resonant lowpass, but only checks its parameters once per audio cycle."; }
@end

@implementation SBFastResonantHighpass
- (id) init { self = [super init]; if (self != nil) { mType = 3; [mInputNames addObject:@"r"]; } return self; }
+ (NSString*) name { return @"Resonant highpass (fast)"; }
- (NSString*) name { return @"res.fhpass"; }
- (NSString*) informations { return @"Same as resonant highpass, but only checks its parameters once per audio cycle."; }
@end


