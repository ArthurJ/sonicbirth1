/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBXOver.h"

#define MIN_VOLUME (-140)

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBXOver *obj = inObj;
	
	BOOL reset = obj->mReset;
	double curVolume = obj->mCurVolume;
	double curVolumeChangeSpeed = obj->mCurVolumeChangeSpeed;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i1		= obj->pInputBuffers[0].floatData + offset;
		float *i2		= obj->pInputBuffers[1].floatData + offset;
		float *sel		= obj->pInputBuffers[2].floatData + offset;
		float *time1	= obj->pInputBuffers[3].floatData + offset;
		float *time2	= obj->pInputBuffers[4].floatData + offset;
		float *o		= obj->mAudioBuffers[0].floatData + offset;
		float srate		= obj->mSampleRate;
		
		if (reset)
		{
			if (*sel <= 0) curVolume = 0;
			else curVolume = MIN_VOLUME;
		}
		
		while(count--)
		{
			const float i1v = *i1++;
			const float i2v = *i2++;
			const float selv = *sel++;
			const float time1v = *time1++;
			const float time2v = *time2++;
			const float minv = MIN_VOLUME;
			const float range = -minv;
			const float maxSpeedPerSample1 = range / (time1v * srate);
			const float speedPerSample2 = maxSpeedPerSample1 / (time2v * srate);
	
			if (selv <= 0)
			{
				curVolumeChangeSpeed += speedPerSample2;
				if (curVolumeChangeSpeed > maxSpeedPerSample1)
					curVolumeChangeSpeed = maxSpeedPerSample1;
			}
			else
			{
				curVolumeChangeSpeed -= speedPerSample2;
				if (curVolumeChangeSpeed < -maxSpeedPerSample1)
					curVolumeChangeSpeed = -maxSpeedPerSample1;
			}
			
			float linVol1;
			
			curVolume += curVolumeChangeSpeed;
			if (curVolume < minv)	{ curVolume = minv; curVolumeChangeSpeed = 0; }
			else if (curVolume > 0)	{ curVolume = 0; curVolumeChangeSpeed = 0; }
			linVol1 = powf(10.f, curVolume * 0.05f);
		
			const float linVol2 = 1 - linVol1;
			
			*o++ = linVol1 * i1v + linVol2 * i2v;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i1		= obj->pInputBuffers[0].doubleData + offset;
		double *i2		= obj->pInputBuffers[1].doubleData + offset;
		double *sel		= obj->pInputBuffers[2].doubleData + offset;
		double *time1	= obj->pInputBuffers[3].doubleData + offset;
		double *time2	= obj->pInputBuffers[4].doubleData + offset;
		double *o		= obj->mAudioBuffers[0].doubleData + offset;
		double srate	= obj->mSampleRate;
		
		if (reset)
		{
			if (*sel <= 0) curVolume = 0;
			else curVolume = MIN_VOLUME;
		}
		
		while(count--)
		{
			const double i1v = *i1++;
			const double i2v = *i2++;
			const double selv = *sel++;
			const double time1v = *time1++;
			const double time2v = *time2++;
			const double minv = MIN_VOLUME;
			const double range = -minv;
			const double maxSpeedPerSample1 = range / (time1v * srate);
			const double speedPerSample2 = maxSpeedPerSample1 / (time2v * srate);
	
			if (selv <= 0)
			{
				curVolumeChangeSpeed += speedPerSample2;
				if (curVolumeChangeSpeed > maxSpeedPerSample1)
					curVolumeChangeSpeed = maxSpeedPerSample1;
			}
			else
			{
				curVolumeChangeSpeed -= speedPerSample2;
				if (curVolumeChangeSpeed < -maxSpeedPerSample1)
					curVolumeChangeSpeed = -maxSpeedPerSample1;
			}
			
			double linVol1;
			
			curVolume += curVolumeChangeSpeed;
			if (curVolume < minv)	{ curVolume = minv; curVolumeChangeSpeed = 0; }
			else if (curVolume > 0)	{ curVolume = 0; curVolumeChangeSpeed = 0; }
			linVol1 = pow(10., curVolume * 0.05);
		
			const double linVol2 = 1 - linVol1;
			
			*o++ = linVol1 * i1v + linVol2 * i2v;
		}
	}
	
	obj->mReset = NO;
	obj->mCurVolume = curVolume;
	obj->mCurVolumeChangeSpeed = curVolumeChangeSpeed;
}

@implementation SBXOver

+ (NSString*) name
{
	return @"XOver";
}

- (NSString*) name
{
	return @"xover";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return	@"Allows you to switch form one input to the other with constant db speed. "
			@"i1 and i2 are both sound inputs. sel is 0 or negative for i1, positive for i2. "
			@"time1 is time in seconds to switch from 0 to -140 db. time2 is time to switch direction.";
}

- (void) reset
{
	[super reset];
	mReset = YES;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"i1"];
		[mInputNames addObject:@"i2"];
		[mInputNames addObject:@"sel"];
		[mInputNames addObject:@"time1"];
		[mInputNames addObject:@"time2"];
		
		[mOutputNames addObject:@"o"];
		
		mReset = YES;
	}
	return self;
}
@end
