/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBLog10.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBLog10 *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *s = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->mAudioBuffers[0].floatData + offset;
		vvlog10f(d, s, &count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *s = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->mAudioBuffers[0].doubleData + offset;
		vvlog10(d, s, &count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBLog10 *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *s = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *d++ = log10f(*s++);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *s = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *d++ = log10(*s++);
	}
}

@implementation SBLog10

+ (NSString*) name
{
	return @"Logarithm base 10";
}

- (NSString*) name
{
	return @"log10";
}

+ (SBElementCategory) category
{
	return kFunction;
}

- (NSString*) informations
{
	return @"Outputs log10(x).";
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
		
		[mOutputNames addObject:@"log10(x)"];
	}
	return self;
}

@end
