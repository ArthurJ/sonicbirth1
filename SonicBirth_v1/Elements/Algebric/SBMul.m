/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMul.h"
#import <Accelerate/Accelerate.h>

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBMul *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *a = obj->pInputBuffers[0].floatData + offset;
		float *b = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		vDSP_vmul(a, 1, b, 1, o, 1, count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *a = obj->pInputBuffers[0].doubleData + offset;
		double *b = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		vDSP_vmulD(a, 1, b, 1, o, 1, count);
	}
}

@implementation SBMul


+ (NSString*) name
{
	return @"Multiplication";
}

- (NSString*) name
{
	return @"mul";
}

+ (SBElementCategory) category
{
	return kAlgebraic;
}

- (NSString*) informations
{
	return @"Outputs (a * b).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"a"];
		[mInputNames addObject:@"b"];
		
		[mOutputNames addObject:@"a*b"];
	}
	return self;
}

@end
