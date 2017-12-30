/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCstMul.h"
#import <Accelerate/Accelerate.h>

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBCstMul *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float c = obj->mValue;
		vDSP_vsmul(i, 1, &c, o, 1, count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double c = obj->mValue;
		vDSP_vsmulD(i, 1, &c, o, 1, count);
	}
}

@implementation SBCstMul

+ (NSString*) name
{
	return @"Constant Multiplication";
}

- (NSString*) name
{
	return @"cst mul";
}

- (NSString*) informations
{
	return @"Multiply by a constant number.";
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
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"i"];
		
		// output 'o' has been added by superclass sbconstant
	}
	return self;
}

@end
