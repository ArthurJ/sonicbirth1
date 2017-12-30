/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBTimerLoop.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBTimerLoop *obj = inObj;
	
	unsigned long long cs = obj->mCurSample;
	int cr = obj->mRun;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *r = obj->pInputBuffers[0].floatData + offset;
		float *m = obj->pInputBuffers[1].floatData + offset;
		float *t = obj->mAudioBuffers[0].floatData + offset;
		float srate = obj->mSampleRate;
		float invsrate = 1.f / srate;
		while(count--)
		{
			int run = *r++ + 0.5f;
			if (run == 1)
			{
				if (cr != 1) cs = 0;
				*t++ = cs++ * invsrate;
				float max = *m++ * srate;
				if (cs > max && max > 0.f) cs = 0;
			}
			else
			{
				*t++ = 0.f;
				m++;
			}
			cr = run;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *r = obj->pInputBuffers[0].doubleData + offset;
		double *m = obj->pInputBuffers[1].doubleData + offset;
		double *t = obj->mAudioBuffers[0].doubleData + offset;
		double srate = obj->mSampleRate;
		double invsrate = 1. / srate;
		while(count--)
		{
			int run = *r++ + 0.5;
			if (run == 1)
			{
				if (cr != 1) cs = 0;
				*t++ = cs++ * invsrate;
				double max = *m++ * srate;
				if (cs > max && max > 0.) cs = 0;
			}
			else
			{
				*t++ = 0.;
				m++;
			}
			cr = run;
		}
	}

	obj->mCurSample = cs;
	obj->mRun = cr;
}

@implementation SBTimerLoop

+ (NSString*) name
{
	return @"Timer loop";
}

- (NSString*) name
{
	return @"tloop";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return	@"Outputs the time in seconds, looping back to 0 when arriving to the max time specified. "
			@"Loops back to 0 when arriving to the max time specified."
			@"If the max is equal or smaller than 0, then it does not loop. "
			@"Time is reset then run switchs to 1.";
}

- (void) reset
{
	[super reset];
	mCurSample = 0;
	mRun = 0;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"run"];
		[mInputNames addObject:@"max"];
		
		[mOutputNames addObject:@"time"];
	}
	return self;
}

@end
