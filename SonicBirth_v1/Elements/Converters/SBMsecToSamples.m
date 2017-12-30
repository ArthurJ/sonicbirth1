/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMsecToSamples.h"
#import <Accelerate/Accelerate.h>

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBMsecToSamples *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float c = obj->mSampleRate / 1000.f;
		vDSP_vsmul(i, 1, &c, o, 1, count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double c = obj->mSampleRate / 1000.;
		vDSP_vsmulD(i, 1, &c, o, 1, count);
	}
}


@implementation SBMsecToSamples

+ (NSString*) name
{
	return @"Msec to samples";
}

- (NSString*) name
{
	return @"ms2samples";
}

+ (SBElementCategory) category
{
	return kConverter;
}

- (NSString*) informations
{
	return @"Converts milliseconds into samples.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"ms"];
		
		[mOutputNames addObject:@"smpl"];
	}
	return self;
}

@end
