/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBBPMCounter.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBBPMCounter *obj = inObj;
	
	int samplesSinceLastEvent = obj->mSamplesSinceLastEvent;
	int sampleRate = obj->mSampleRate;
	int sampleRate4 = sampleRate << 2;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;

		float currentBpm = obj->mCurrentBpm;
		float lastVal = obj->mLastVal;

		while(count--)
		{
			float v = *i++;
			if (v > 0.5f && lastVal <= 0.5f)
			{
				if (samplesSinceLastEvent > sampleRate4)
				{
					obj->mEventCount = 0;
					samplesSinceLastEvent = 0;
				}
				else
				{			
					// add event
					int *events = obj->mEvents;
					int eventCount = obj->mEventCount;

					if (eventCount < kMaxEventCount)
					{
						events[eventCount] = samplesSinceLastEvent;
						eventCount++;
						obj->mEventCount = eventCount;
					}
					else
					{
						int j, k;
						for (j = 0, k = 1; k < kMaxEventCount; j++, k++) events[j] = events[k];
						events[kMaxEventCount - 1] = samplesSinceLastEvent;
					}
					samplesSinceLastEvent = 0;
					
					// calculate bpm
					int j, sum = 0;
					for (j = 0; j < eventCount; j++) sum += events[j];
					
					float avg = (float)sum / (float)eventCount;
					float sec = avg / sampleRate;
					
					currentBpm = 60.f / sec;
				}
			}
			
			lastVal = v;
			samplesSinceLastEvent++;
			
			*o++ = currentBpm;
		}
		
		obj->mLastVal = lastVal;
		obj->mCurrentBpm = currentBpm;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		
		double currentBpm = obj->mCurrentBpm;
		double lastVal = obj->mLastVal;

		while(count--)
		{
			double v = *i++;
			if (v > 0.5 && lastVal <= 0.5)
			{
				if (samplesSinceLastEvent > sampleRate4)
				{
					obj->mEventCount = 0;
					samplesSinceLastEvent = 0;
				}
				else
				{	
					// add event
					int *events = obj->mEvents;
					int eventCount = obj->mEventCount;
					if (eventCount < kMaxEventCount)
					{
						events[eventCount] = samplesSinceLastEvent;
						eventCount++;
						obj->mEventCount = eventCount;
					}
					else
					{
						int j, k;
						for (j = 0, k = 1; k < kMaxEventCount; j++, k++) events[j] = events[k];
						events[kMaxEventCount - 1] = samplesSinceLastEvent;
					}
					samplesSinceLastEvent = 0;
					
					// calculate bpm
					int j, sum = 0;
					for (j = 0; j < eventCount; j++) sum += events[j];
					
					double avg = (double)sum / (double)eventCount;
					double sec = avg / sampleRate;
					
					currentBpm = 60. / sec;
				}
			}
			
			lastVal = v;
			samplesSinceLastEvent++;
			
			*o++ = currentBpm;
		}
		
		obj->mLastVal = lastVal;
		obj->mCurrentBpm = currentBpm;
	}
	
	obj->mSamplesSinceLastEvent = samplesSinceLastEvent;
}


@implementation SBBPMCounter

+ (NSString*) name
{
	return @"BPM Counter";
}

- (NSString*) name
{
	return @"bpm";
}

+ (SBElementCategory) category
{
	return kAnalysis;
}

- (NSString*) informations
{
	return	@"BPM counter analyses its input and outputs the current bpm. Uses the last " kMaxEventCountString
			@" events to average the bpm. Is considred an event when its input passes from under or equal to"
			@" 0.5 to over 0.5.";
}

- (void) reset
{
	mEventCount = 0;
	mCurrentBpm = 0;
	mLastVal = 0;
	mSamplesSinceLastEvent = 0;
	[super reset];
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"in"];
		
		[mOutputNames addObject:@"bpm"];
	}
	return self;
}

@end
