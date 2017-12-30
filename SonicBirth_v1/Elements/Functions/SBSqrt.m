/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSqrt.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBSqrt *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *s = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->mAudioBuffers[0].floatData + offset;
		vvsqrtf(d, s, &count);
		
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *s = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->mAudioBuffers[0].doubleData + offset;
		vvsqrt(d, s, &count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSqrt *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *s = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *d++ = sqrtf(*s++);
		
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *s = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *d++ = sqrt(*s++);
	}
}

@implementation SBSqrt

+ (NSString*) name
{
	return @"Square root";
}

- (NSString*) name
{
	return @"sqrt";
}

+ (SBElementCategory) category
{
	return kFunction;
}

- (NSString*) informations
{
	return @"Outputs sqrt(x).";
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
		
		[mOutputNames addObject:@"sqrt(x)"];
	}
	return self;
}

@end
