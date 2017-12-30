/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBNegMulSub.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBNegMulSub *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *a = obj->pInputBuffers[0].floatData + offset;
		float *b = obj->pInputBuffers[1].floatData + offset;
		float *c = obj->pInputBuffers[2].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *o++ = -((*a++ * *b++) - *c++);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *a = obj->pInputBuffers[0].doubleData + offset;
		double *b = obj->pInputBuffers[1].doubleData + offset;
		double *c = obj->pInputBuffers[2].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *o++ = -((*a++ * *b++) - *c++);
	}
}

@implementation SBNegMulSub

+ (NSString*) name
{
	return @"Neg. Multiply-Sub";
}

- (NSString*) name
{
	return @"negmulsub";
}

+ (SBElementCategory) category
{
	return kAlgebraic;
}

- (NSString*) informations
{
	return @"Outputs -((a*b)-c).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"a"];
		[mInputNames addObject:@"b"];
		[mInputNames addObject:@"c"];
		
		[mOutputNames addObject:@"-((a*b)-c)"];
	}
	return self;
}


@end
