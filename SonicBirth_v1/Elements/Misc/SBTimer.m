/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBTimer.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBTimer *obj = inObj;
	
	unsigned long long cs = obj->mCurSample;
	int cr = obj->mRun;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *r = obj->pInputBuffers[0].floatData + offset;
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
			}
			else *t++ = 0.f;
			cr = run;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *r = obj->pInputBuffers[0].doubleData + offset;
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
			}
			else *t++ = 0.;
			cr = run;
		}
	}
	
	obj->mCurSample = cs;
	obj->mRun = cr;
}

@implementation SBTimer

+ (NSString*) name
{
	return @"Timer";
}

- (NSString*) name
{
	return @"timer";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return	@"Outputs the time in seconds, when run is 1, outputs 0 otherwise. "
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
		
		[mOutputNames addObject:@"time"];
	}
	return self;
}

@end
