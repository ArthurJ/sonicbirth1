/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAtan2.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBAtan2 *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *x = obj->pInputBuffers[0].floatData + offset;
		float *y = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		vvatan2f(o, y, x, &count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *x = obj->pInputBuffers[0].doubleData + offset;
		double *y = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		vvatan2(o, y, x, &count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBAtan2 *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *x = obj->pInputBuffers[0].floatData + offset;
		float *y = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *o++ = atan2f(*y++, *x++);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *x = obj->pInputBuffers[0].doubleData + offset;
		double *y = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *o++ = atan2(*y++, *x++);
	}
}

@implementation SBAtan2

+ (NSString*) name
{
	return @"Arc tangent (x, y)";
}

- (NSString*) name
{
	return @"atan2";
}

+ (SBElementCategory) category
{
	return kTrigonometric;
}

- (NSString*) informations
{
	return @"Outputs the arc tangent of y/x.";
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
		
		[mOutputNames addObject:@"atan(y/x)"];
	}
	return self;
}

@end
