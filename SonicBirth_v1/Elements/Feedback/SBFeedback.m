/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFeedback.h"

#import "SBInterpolation.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBFeedback *obj = inObj;
	
	int feedbackOffset = obj->mSampleRate * kMinFeedbackTime;
	int sampleCount = obj->mSampleCount;

	// a feedback element is executed _after_ the element
	// reading from its output
	// therefore, it should copy data from its current cycle
	// into the buffer pos for the _next_ cycle
	
	//printf("count: %4i read: [%4i .. %4i] write: [%4i .. %4i (%4i)]\n",
	//			count, offset, offset + count - 1,
	//			offset + feedbackOffset, offset + feedbackOffset + count - 1,
	//			(offset + feedbackOffset + count - 1) % sampleCount);

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData;
		while(count--)
		{
			int p = offset++ + feedbackOffset;
			p %= sampleCount;
			o[p] = *i++;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData;
		while(count--)
		{
			int p = offset++ + feedbackOffset;
			p %= sampleCount;
			o[p] = *i++;
		}
	}
}

@implementation SBFeedback

+ (NSString*) name
{
	return @"Feedback";
}

- (NSString*) name
{
	return @"fdbck";
}

+ (SBElementCategory) category
{
	return kFeedback;
}

- (NSString*) informations
{
	return [NSString stringWithFormat:
				@"Allows a feedback loop, with fixed delay (%f seconds).",
				kMinFeedbackTime];
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"in"];		
		[mOutputNames addObject:@"out"];
	}
	return self;
}

@end
