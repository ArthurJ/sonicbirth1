/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBDirection.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBDirection *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *x = obj->pInputBuffers[0].floatData + offset;
		float *dir = obj->mAudioBuffers[0].floatData + offset;
		float lastVal = obj->mLastValue;
		while(count--)
		{
			float val = *x++;
			if (val > lastVal) *dir++ = 1.f;
			else if (val < lastVal) *dir++ = -1.f;
			else *dir++ = 0.f;
			lastVal = val;
		}
		obj->mLastValue = lastVal;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *x = obj->pInputBuffers[0].doubleData + offset;
		double *dir = obj->mAudioBuffers[0].doubleData + offset;
		double lastVal = obj->mLastValue;
		while(count--)
		{
			double val = *x++;
			if (val > lastVal) *dir++ = 1.;
			else if (val < lastVal) *dir++ = -1.;
			else *dir++ = 0.;
			lastVal = val;
		}
		obj->mLastValue = lastVal;
	}
}

@implementation SBDirection

+ (NSString*) name
{
	return @"Direction";
}

- (NSString*) name
{
	return @"dir";
}

+ (SBElementCategory) category
{
	return kAlgebraic;
}

- (NSString*) informations
{
	return @"Outputs 1 if input is augmenting, -1 if it is descending, 0 otherwise.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"x"];
		
		[mOutputNames addObject:@"dir"];
	}
	return self;
}

- (void) reset
{
	[super reset];
	
	mLastValue = 0.;
}

@end
