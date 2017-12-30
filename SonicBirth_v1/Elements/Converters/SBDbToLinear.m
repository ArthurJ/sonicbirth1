/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBDbToLinear.h"
#import <Accelerate/Accelerate.h>

//#warning "euh... code for 10.3 is faster than for 10.4 ???"

/*#if (MAX_OS_VERSION_USE >= 4)
// sample count can be > than this because of sampleRate doubler!
static float gTenf[kSamplesPerCycle] = { 10. };
static double gTen[kSamplesPerCycle] = { 10. };

static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBDbToLinear *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float c = 0.05;
		vDSP_vsmul(i, 1, &c, o, 1, count);
		while (count > 0)
		{
			int max = (count > kSamplesPerCycle) ? kSamplesPerCycle : count;
			vvpowf(o, o, gTenf, &max);
			o += max;
			count -= max;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double c = 0.05;
		vDSP_vsmulD(i, 1, &c, o, 1, count);
		while (count > 0)
		{
			int max = (count > kSamplesPerCycle) ? kSamplesPerCycle : count;
			vvpow(o, o, gTen, &max);
			o += max;
			count -= max;
		}
	}
}
#endif*/

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBDbToLinear *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		//while (count--) *o++ = powf(*i++ * 0.05f, 10.f);
		while (count--) *o++ = powf(10.f, *i++ * 0.05f);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		//while (count--) *o++ = pow(*i++ * 0.05, 10.);
		while (count--) *o++ = pow(10., *i++ * 0.05);
	}
}

@implementation SBDbToLinear

+ (NSString*) name
{
	return @"Db to linear";
}

- (NSString*) name
{
	return @"db2lin";
}

+ (SBElementCategory) category
{
	return kConverter;
}

- (NSString*) informations
{
	return @"Converts decibels into linear values.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
//#if (MAX_OS_VERSION_USE >= 4)
//		pCalcFunc = (frameworkOSVersion() >= 4) ? privateCalcFuncFast : privateCalcFunc;
//#else
		pCalcFunc = privateCalcFunc;
//#endif
	
		[mInputNames addObject:@"db"];
		
		[mOutputNames addObject:@"lin"];
	}
	return self;
}

@end
