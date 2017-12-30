/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCstSub.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBCstSub *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float c = obj->mValue;
		while(count--) *o++ = *i++ - c;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double c = obj->mValue;
		while(count--) *o++ = *i++ - c;
	}
}

@implementation SBCstSub

+ (NSString*) name
{
	return @"Constant Subtraction";
}

- (NSString*) name
{
	return @"cst sub";
}

- (NSString*) informations
{
	return @"Subtracts a constant number.";
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
