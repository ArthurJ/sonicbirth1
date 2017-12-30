/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFloor.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBFloor *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *s = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->mAudioBuffers[0].floatData + offset;
		vvfloorf(d, s, &count);
		
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *s = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->mAudioBuffers[0].doubleData + offset;
		vvfloor(d, s, &count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBFloor *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *s = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *d++ = floorf(*s++);
		
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *s = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *d++ = floor(*s++);
	}
}

@implementation SBFloor

+ (NSString*) name
{
	return @"Floor";
}

- (NSString*) name
{
	return @"floor";
}

+ (SBElementCategory) category
{
	return kFunction;
}

- (NSString*) informations
{
	return @"Rounds to largest integral value not greater than x.";
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
		
		[mOutputNames addObject:@"o"];
	}
	return self;
}

@end
