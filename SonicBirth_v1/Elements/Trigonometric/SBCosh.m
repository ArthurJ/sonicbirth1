/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCosh.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBCosh *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *s = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->mAudioBuffers[0].floatData + offset;
		vvcoshf(d, s, &count);
		
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *s = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->mAudioBuffers[0].doubleData + offset;
		vvcosh(d, s, &count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBCosh *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *s = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *d++ = coshf(*s++);
		
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *s = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *d++ = cosh(*s++);
	}
}

@implementation SBCosh

+ (NSString*) name
{
	return @"Hyperbolic cosinus";
}

- (NSString*) name
{
	return @"cosh";
}

+ (SBElementCategory) category
{
	return kTrigonometric;
}

- (NSString*) informations
{
	return @"Outputs the hyperbolic cosinus of the input.";
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
		
		[mOutputNames addObject:@"cosh x"];
	}
	return self;
}

@end
