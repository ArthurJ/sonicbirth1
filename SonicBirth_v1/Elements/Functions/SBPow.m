/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPow.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBPow *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *x = obj->pInputBuffers[0].floatData + offset;
		float *y = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		vvpowf(o, y, x, &count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *x = obj->pInputBuffers[0].doubleData + offset;
		double *y = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		vvpow(o, y, x, &count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBPow *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *x = obj->pInputBuffers[0].floatData + offset;
		float *y = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *o++ = powf(*x++, *y++);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *x = obj->pInputBuffers[0].doubleData + offset;
		double *y = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *o++ = pow(*x++, *y++);
	}
}

@implementation SBPow

+ (NSString*) name
{
	return @"Power";
}

- (NSString*) name
{
	return @"pow";
}

+ (SBElementCategory) category
{
	return kFunction;
}

- (NSString*) informations
{
	return @"Outputs x^y.";
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
	
		[mInputNames addObject:@"x"];
		[mInputNames addObject:@"y"];
		
		[mOutputNames addObject:@"x^y"];
	}
	return self;
}

@end
