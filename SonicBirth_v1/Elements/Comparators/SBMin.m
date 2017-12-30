/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMin.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBMin *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *a = obj->pInputBuffers[0].floatData + offset;
		float *b = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *o++ = sminf(*a++, *b++);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *a = obj->pInputBuffers[0].doubleData + offset;
		double *b = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		vDSP_vminD(a, 1, b, 1, o, 1, count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBMin *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *a = obj->pInputBuffers[0].floatData + offset;
		float *b = obj->pInputBuffers[1].floatData + offset;
		float *min = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *min++ = sminf(*a++, *b++);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *a = obj->pInputBuffers[0].doubleData + offset;
		double *b = obj->pInputBuffers[1].doubleData + offset;
		double *min = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *min++ = smin(*a++, *b++);
	}
}

@implementation SBMin

+ (NSString*) name
{
	return @"Minimum";
}

- (NSString*) name
{
	return @"min";
}

+ (SBElementCategory) category
{
	return kComparator;
}

- (NSString*) informations
{
	return @"Outputs the smallest of both inputs.";
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
	
		[mInputNames addObject:@"a"];
		[mInputNames addObject:@"b"];
		
		[mOutputNames addObject:@"min(a,b)"];
	}
	return self;
}

@end
