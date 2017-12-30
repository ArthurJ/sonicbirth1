/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBLinearNoise.h"

#define kRandomMax ((double)(0x7FFFFFFF))
#define kRandomMaxF ((float)(0x7FFFFFFF))

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBLinearNoise *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *wnoise = obj->mAudioBuffers[0].floatData + offset;
		while(count--)
			*wnoise++ = (((float)random() * 2.f) /  kRandomMaxF) - 1.f;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *wnoise = obj->mAudioBuffers[0].doubleData + offset;
		while(count--)
			*wnoise++ = (((double)random() * 2.) /  kRandomMax) - 1.;
	}
}

@implementation SBLinearNoise

+ (NSString*) name
{
	return @"Linear Noise";
}

- (NSString*) name
{
	return @"lnoise";
}

+ (SBElementCategory) category
{
	return kGenerator;
}

- (NSString*) informations
{
	return @"Generates linear noise (random values between -1 and 1).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		[mOutputNames addObject:@"lnoise"];
	}
	return self;
}

- (void) reset
{
	[super reset];

	//srandom(time(0));
}

@end
