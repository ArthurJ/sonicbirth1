/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBLinearToDb.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBLinearToDb *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float c = 20.f;
		vvlog10f(o, i, &count);
		vDSP_vsmul(o, 1, &c, o, 1, count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double c = 20.;
		vvlog10(o, i, &count);
		vDSP_vsmulD(o, 1, &c, o, 1, count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBLinearToDb *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *o++ = log10f(*i++) * 20.f;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *o++ = log10(*i++) * 20.;
	}
}

@implementation SBLinearToDb

+ (NSString*) name
{
	return @"Linear to db";
}

- (NSString*) name
{
	return @"lin2db";
}

+ (SBElementCategory) category
{
	return kConverter;
}

- (NSString*) informations
{
	return @"Converts linear values into decibels.";
}

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
	
		[mInputNames addObject:@"lin"];
		
		[mOutputNames addObject:@"db"];
	}
	return self;
}

@end
