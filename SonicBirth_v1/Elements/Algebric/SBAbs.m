/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAbs.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBAbs *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		vDSP_vabs(i, 1, o, 1, count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		vDSP_vabsD(i, 1, o, 1, count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBAbs *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		unsigned int *x = (unsigned int *)(obj->pInputBuffers[0].floatData + offset);
		unsigned int *ax = (unsigned int *)(obj->mAudioBuffers[0].floatData + offset);
		while(count--) *ax++ = *x++ & 0x7FFFFFFF;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		unsigned int *x = (unsigned int *)(obj->pInputBuffers[0].doubleData + offset);
		unsigned int *ax = (unsigned int *)(obj->mAudioBuffers[0].doubleData + offset);
		while(count--) { *ax++ = *x++ & 0x7FFFFFFF; *ax++ = *x++; }
	}
}

@implementation SBAbs

+ (NSString*) name
{
	return @"Absolute";
}

- (NSString*) name
{
	return @"abs";
}

+ (SBElementCategory) category
{
	return kAlgebraic;
}

- (NSString*) informations
{
	return @"Outputs |x| (x if x>=0, -x if x<0).";
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
		
		[mOutputNames addObject:@"|x|"];
	}
	return self;
}

@end
