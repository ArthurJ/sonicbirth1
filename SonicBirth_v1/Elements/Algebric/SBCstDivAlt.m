/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCstDivAlt.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBCstDivAlt *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float c = obj->mValue;
		while(count--) *o++ = c / *i++;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double c = obj->mValue;
		while(count--) *o++ = c / *i++;
	}
}

@implementation SBCstDivAlt

+ (NSString*) name
{
	return @"Constant Division Alt.";
}

- (NSString*) name
{
	return @"cst div alt";
}

- (NSString*) informations
{
	return @"Constant number divided by input.";
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

- (double) defaultValue
{
	return 2;
}

@end
