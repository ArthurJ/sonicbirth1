/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBNegate.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBNegate *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		unsigned int *x = (unsigned int *)(obj->pInputBuffers[0].floatData + offset);
		unsigned int *mx = (unsigned int *)(obj->mAudioBuffers[0].floatData + offset);
		while(count--) *mx++ = *x++ ^ 0x80000000;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		unsigned int *x = (unsigned int *)(obj->pInputBuffers[0].doubleData + offset);
		unsigned int *mx = (unsigned int *)(obj->mAudioBuffers[0].doubleData + offset);
		while(count--) { *mx++ = *x++ ^ 0x80000000; *mx++ = *x++; }
	}
}


@implementation SBNegate

+ (NSString*) name
{
	return @"Negation";
}

- (NSString*) name
{
	return @"neg";
}

+ (SBElementCategory) category
{
	return kAlgebraic;
}

- (NSString*) informations
{
	return @"Outputs -x.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"x"];
		
		[mOutputNames addObject:@"-x"];
	}
	return self;
}

@end
