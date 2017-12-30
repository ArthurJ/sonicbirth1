/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCstDiv.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBCstDiv *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float c = obj->mValue;
		vDSP_vsdiv(i, 1, &c, o, 1, count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double c = obj->mValue;
		vDSP_vsdivD(i, 1, &c, o, 1, count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBCstDiv *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float c = obj->mValue;
		while(count--) *o++ = *i++ / c;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double c = obj->mValue;
		while(count--) *o++ = *i++ / c;
	}
}

@implementation SBCstDiv

+ (NSString*) name
{
	return @"Constant Division";
}

- (NSString*) name
{
	return @"cst div";
}

- (NSString*) informations
{
	return @"Divides by a constant number.";
}

+ (SBElementCategory) category
{
	return kAlgebraic;
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

		[mInputNames addObject:@"i"];
		
		// output 'o' has been added by superclass sbconstant
	}
	return self;
}

- (double) defaultValue
{
	return 2;
}

@end
