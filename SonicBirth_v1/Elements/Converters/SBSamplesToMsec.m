/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSamplesToMsec.h"
#import <Accelerate/Accelerate.h>

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSamplesToMsec *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float c = 1000.f / obj->mSampleRate;
		vDSP_vsmul(i, 1, &c, o, 1, count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double c = 1000. / obj->mSampleRate;
		vDSP_vsmulD(i, 1, &c, o, 1, count);
	}
}


@implementation SBSamplesToMsec

+ (NSString*) name
{
	return @"Samples to msec";
}

- (NSString*) name
{
	return @"samples2ms";
}

+ (SBElementCategory) category
{
	return kConverter;
}

- (NSString*) informations
{
	return @"Converts samples into milliseconds.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"smpl"];
		
		[mOutputNames addObject:@"ms"];
	}
	return self;
}

@end
