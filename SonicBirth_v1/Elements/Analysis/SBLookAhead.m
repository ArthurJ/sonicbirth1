/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBLookAhead.h"

// buffer is expected to be all positive
static inline float maxInBufferFloat(float *buf, int size, int *outPos) __attribute__((always_inline));
static inline float maxInBufferFloat(float *buf, int size, int *outPos)
{
	float max = 0.f;
	int i, pos = 0, sizem8 = size - 8;
	
	// do it in block of 8
	for(i = 0; i < sizem8; i += 8)
	{
		float c0 = *buf++;
		float c1 = *buf++;
		float c2 = *buf++;
		float c3 = *buf++;
		float c4 = *buf++;
		float c5 = *buf++;
		float c6 = *buf++;
		float c7 = *buf++;
		
		if (c0 > max) { max = c0; pos = i + 0; }
		if (c1 > max) { max = c1; pos = i + 1; }
		if (c2 > max) { max = c2; pos = i + 2; }
		if (c3 > max) { max = c3; pos = i + 3; }
		if (c4 > max) { max = c4; pos = i + 4; }
		if (c5 > max) { max = c5; pos = i + 5; }
		if (c6 > max) { max = c6; pos = i + 6; }
		if (c7 > max) { max = c7; pos = i + 7; }
	}
	
	// do the remaining
	for(; i < size; i++)
	{
		float c = *buf++;
		
		if (c > max) { max = c; pos = i; }
	}
	
	*outPos = pos;
	return max;
}

static inline double maxInBufferDouble(double *buf, int size, int *outPos) __attribute__((always_inline));
static inline double maxInBufferDouble(double *buf, int size, int *outPos)
{
	double max = 0.;
	int i, pos = 0, sizem8 = size - 8;
	
	// do it in block of 8
	for(i = 0; i < sizem8; i += 8)
	{
		double c0 = *buf++;
		double c1 = *buf++;
		double c2 = *buf++;
		double c3 = *buf++;
		double c4 = *buf++;
		double c5 = *buf++;
		double c6 = *buf++;
		double c7 = *buf++;
		
		if (c0 > max) { max = c0; pos = i + 0; }
		if (c1 > max) { max = c1; pos = i + 1; }
		if (c2 > max) { max = c2; pos = i + 2; }
		if (c3 > max) { max = c3; pos = i + 3; }
		if (c4 > max) { max = c4; pos = i + 4; }
		if (c5 > max) { max = c5; pos = i + 5; }
		if (c6 > max) { max = c6; pos = i + 6; }
		if (c7 > max) { max = c7; pos = i + 7; }
	}
	
	// do the remaining
	for(; i < size; i++)
	{
		double c = *buf++;
		
		if (c > max) { max = c; pos = i; }
	}
	
	*outPos = pos;
	return max;
}

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBLookAhead *obj = inObj;

	int bufSize = obj->mBuffersSize;
	int curPos = obj->mCurSample;
	int envPos = obj->mEnvPos;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float *e = obj->mAudioBuffers[1].floatData + offset;
		
		float *dlyBuf = obj->mDelayBuffer.floatData;
		float *absBuf = obj->mAbsBuffer.floatData;
		
		float add, env;

		while(count--)
		{
			*o++ = dlyBuf[curPos];
			dlyBuf[curPos] = add = *i++; 
			
			add = sabsf(add);
			absBuf[curPos] = add;

			if (curPos == envPos)
			{
				// we've just overwritten what was the current max
				// so recalculate it
				*e++ = maxInBufferFloat(absBuf, bufSize, &envPos);
			}
			else
			{
				env = absBuf[envPos];
				if (add > env)
				{
					// in that case, add is the new max
					*e++ = add;
					envPos = curPos;
				}
				else
				{
					// env is still the max
					*e++ = env;
				}
			}
			
			if (++curPos >= bufSize) curPos = 0;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double *e = obj->mAudioBuffers[1].doubleData + offset;
		
		double *dlyBuf = obj->mDelayBuffer.doubleData;
		double *absBuf = obj->mAbsBuffer.doubleData;
		
		double add, env;

		while(count--)
		{
			*o++ = dlyBuf[curPos];
			dlyBuf[curPos] = add = *i++; 
			
			add = sabsf(add);
			absBuf[curPos] = add;

			if (curPos == envPos)
			{
				// we've just overwritten what was the current max
				// so recalculate it
				*e++ = maxInBufferDouble(absBuf, bufSize, &envPos);
			}
			else
			{
				env = absBuf[envPos];
				if (add > env)
				{
					// in that case, add is the new max
					*e++ = add;
					envPos = curPos;
				}
				else
				{
					// env is still the max
					*e++ = env;
				}
			}
			
			if (++curPos >= bufSize) curPos = 0;
		}
	}

	obj->mCurSample = curPos;
	obj->mEnvPos = envPos;
}


@implementation SBLookAhead

+ (NSString*) name
{
	return @"Look ahead";
}

- (NSString*) name
{
	return @"lk ahead";
}

+ (SBElementCategory) category
{
	return kAnalysis;
}

- (NSString*) informations
{
	return @"Basic look ahead: outputs the current enveloppe of the input signal, and the delayed signal.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		mDelay = 0.002;

		[mInputNames addObject:@"in"];
		
		[mOutputNames addObject:@"out"];
		[mOutputNames addObject:@"env"];
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	if (mDelayBuffer.ptr) free(mDelayBuffer.ptr);
	if (mAbsBuffer.ptr) free(mAbsBuffer.ptr);
	[super dealloc];
}

- (void) reset
{
	[super reset];
	[self resetBuffer];
}

- (void) specificPrepare
{
	[self updateBufferSize:mSampleRate];
}

- (void) changePrecision:(SBPrecision)precision
{
	if (mPrecision == precision) return;
	
	int i;
	int size = mBuffersSize;
	
	if (mPrecision == kFloatPrecision)
	{
		// float to double
		for (i = size - 1; i >= 0; i--)
			mDelayBuffer.doubleData[i] = mDelayBuffer.floatData[i];
			
		for (i = size - 1; i >= 0; i--)
			mAbsBuffer.doubleData[i] = mAbsBuffer.floatData[i];
	}
	else
	{
		// double to float
		for (i = 0; i < size; i++)
			mDelayBuffer.floatData[i] = mDelayBuffer.doubleData[i];
			
		for (i = 0; i < size; i++)
			mAbsBuffer.floatData[i] = mAbsBuffer.doubleData[i];
	}
	
	[super changePrecision:precision];
}

- (void) updateBufferSize:(int)sampleRate
{
	if (mDelayBuffer.ptr) free(mDelayBuffer.ptr);
	if (mAbsBuffer.ptr) free(mAbsBuffer.ptr);
	int size = mDelay * sampleRate;
	if (size == 0) size = 1;
	mDelayBuffer.ptr = malloc(size * sizeof(double));
	mAbsBuffer.ptr = malloc(size * sizeof(double));
	mBuffersSize = size;
}

- (void) resetBuffer
{
	mCurSample = 0;
	mEnvPos = 0;
	
	if (mPrecision == kFloatPrecision)
	{
		memset(mDelayBuffer.floatData, 0, mBuffersSize * sizeof(float));
		memset(mAbsBuffer.floatData, 0, mBuffersSize * sizeof(float));
	}
	else
	{
		memset(mDelayBuffer.doubleData, 0, mBuffersSize * sizeof(double));
		memset(mAbsBuffer.doubleData, 0, mBuffersSize * sizeof(double));
	}
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBLookAhead" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mTF setDoubleValue:mDelay * 1000.];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[self willChangeAudio];
	mDelay = [mTF doubleValue] / 1000.;
	if (mDelay < 0.) mDelay = 0.0001;
	if (mDelay > 1.) mDelay = 1.; // max 1 sec
	[mTF setDoubleValue:mDelay * 1000.];
	[self updateBufferSize:mSampleRate];
	[self resetBuffer];
	[self didChangeAudio];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mDelay] forKey:@"dly"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	NSNumber *n;
	
	n = [data objectForKey:@"dly"];
	if (n) mDelay = [n doubleValue];
	
	if (mDelay < 0.) mDelay = 0.0001;
	if (mDelay > 1.) mDelay = 1.;
	
	return YES;
}

@end
