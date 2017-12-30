/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBBufferizer.h"

#import "SBInterpolation.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBBufferizer *obj = inObj;
	
	if (count <= 0) return;

	int bufSize = obj->mBufferSize;
	
	int recordPos = obj->mRecordPosition;
	double playPos = obj->mPlayPosition;
	SBBufMode mode = obj->mLastMode;

	SBInterpolation ip = obj->mInterpolation;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *m = obj->pInputBuffers[1].floatData + offset;
		float *s = obj->pInputBuffers[2].floatData + offset;
		float *e = obj->pInputBuffers[3].floatData + offset;
		float *l = obj->pInputBuffers[4].floatData + offset;
		float *v = obj->pInputBuffers[5].floatData + offset; // speed -> vitesse
		
		float *o = obj->mAudioBuffers[0].floatData + offset;
		
		float *buf = obj->mBuffer.floatData;

		int t;

		while(count--)
		{
			// check current mode
			t = *m++ + 0.5f;
			if (t < 0) t = 0; else if (t > 2) t = 2;
			
			SBBufMode cmode = (SBBufMode)t;

			switch(cmode)
			{
				case kSilence:
				{
					*o++ = 0;
					i++; s++; e++; l++; v++;
				}
				break;
					
				case kPlay:
				{
					int start = *s++ * (recordPos - 1);
					int end = *e++ * (recordPos - 1);
					BOOL loop = ((int)(*l++ + 0.5f) != 0);
					float speed = *v++;
					
					if (start >= recordPos) start = recordPos - 1;
					if (end >= recordPos) end = recordPos - 1;
					if (start < 0) start = 0; 
					if (end < 0) end = 0;
					
					if (speed < -5.f) speed = -5.f; else if (speed > 5.f) speed = 5.f;
					if (end < start)
					{
						int tVar = end;
						end = start;
						start = tVar;
						speed = -speed;
					}
				
					if (mode != kPlay) playPos = 0.f;
					
					int count = end - start;
					
					if ((count <= 0) || ((playPos < 0.f || playPos >= count) && !loop))
						*o++ = 0;
					else
					{
						if (ip == kNoInterpolation)
							*o++ = interpolate_float_no(playPos, buf + start, count);
						else
							*o++ = interpolate_float_lin(playPos, buf + start, count);
							
						playPos += speed;

						if (loop)
						{
							if (isinf(playPos) ||isnan(playPos)) playPos = 0;
							while(playPos < 0) playPos += count;
							while(playPos > count) playPos -= count;
						}
					}
					
					i++;
				}
				break;
				
				
				case kRecord:
				{
					if (mode != kRecord) recordPos = 0;
					if (recordPos < bufSize) buf[recordPos++] = *i++;
					else i++;
					*o++ = 0;
					s++; e++; l++; v++;
				}
				break;
			}
			
			mode = cmode;
		}
	}
	else
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *m = obj->pInputBuffers[1].doubleData + offset;
		double *s = obj->pInputBuffers[2].doubleData + offset;
		double *e = obj->pInputBuffers[3].doubleData + offset;
		double *l = obj->pInputBuffers[4].doubleData + offset;
		double *v = obj->pInputBuffers[5].doubleData + offset; // speed -> vitesse
		
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		
		double *buf = obj->mBuffer.doubleData;

		int t;

		while(count--)
		{
			// check current mode
			t = *m++ + 0.5;
			if (t < 0) t = 0; else if (t > 2) t = 2;
			
			SBBufMode cmode = (SBBufMode)t;

			switch(cmode)
			{
				case kSilence:
				{
					*o++ = 0;
					i++; s++; e++; l++; v++;
				}
				break;
					
				case kPlay:
				{
					int start = *s++ * (recordPos - 1);
					int end = *e++ * (recordPos - 1);
					BOOL loop = ((int)(*l++ + 0.5) != 0);
					double speed = *v++;
					
					if (start >= recordPos) start = recordPos - 1;
					if (end >= recordPos) end = recordPos - 1;
					if (start < 0) start = 0; 
					if (end < 0) end = 0;
					
					if (speed < -5.) speed = -5.; else if (speed > 5.) speed = 5.;
					if (end < start)
					{
						int tVar = end;
						end = start;
						start = tVar;
						speed = -speed;
					}
				
					if (mode != kPlay) playPos = 0.;
					
					int count = end - start;
					
					if ((count <= 0) || ((playPos < 0. || playPos >= count) && !loop))
						*o++ = 0;
					else
					{
						if (ip == kNoInterpolation)
							*o++ = interpolate_double_no(playPos, buf + start, count);
						else
							*o++ = interpolate_double_lin(playPos, buf + start, count);
							
						playPos += speed;

						if (loop)
						{
							if (isinf(playPos) ||isnan(playPos)) playPos = 0;
							while(playPos < 0) playPos += count;
							while(playPos > count) playPos -= count;
						}
					}
					
					i++;
				}
				break;
				
				
				case kRecord:
				{
					if (mode != kRecord) recordPos = 0;
					if (recordPos < bufSize) buf[recordPos++] = *i++;
					else i++;
					*o++ = 0;
					s++; e++; l++; v++;
				}
				break;
			}
			
			mode = cmode;
		}
	}
		
	obj->mRecordPosition = recordPos;
	obj->mPlayPosition = playPos;
	obj->mLastMode = mode;
}

@implementation SBBufferizer

+ (NSString*) name
{
	return @"Bufferizer";
}

- (NSString*) name
{
	return @"bfr";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return	@"Buffer object with three modes: silence (0), play (1), record (2). "
			@"In playing mode, start and end represents the playing offset. "
			@"If end is smaller than start, speed is negated. "
			@"Both these values should be between 0 and 1. "
			@"Playing will loop if the loop input is non-zero. "
			@"Speed give the playing speed, should be between -5 and 5. "
			@"A negative speed means the buffers is played reversed. "
			@"In record mode, the buffer is filled from start up to its capacity.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		mMaxRecordingTime = 1.;
		mBuffer.ptr = nil;
	
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"mode"];
		[mInputNames addObject:@"start"];
		[mInputNames addObject:@"end"];
		[mInputNames addObject:@"loop"];
		[mInputNames addObject:@"speed"];
		
		[mOutputNames addObject:@"out"];
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	if (mBuffer.ptr) free(mBuffer.ptr);
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
	int size = mBufferSize;
	
	if (mPrecision == kFloatPrecision)
	{
		// float to double
		for (i = size - 1; i >= 0; i--)
			mBuffer.doubleData[i] = mBuffer.floatData[i];
	}
	else
	{
		// double to float
		for (i = 0; i < size; i++)
			mBuffer.floatData[i] = mBuffer.doubleData[i];
	}
	
	[super changePrecision:precision];
}

- (void) updateBufferSize:(int)sampleRate
{
	if (mBuffer.ptr) free(mBuffer.ptr);
	int size = mMaxRecordingTime * sampleRate;
	if (size == 0) size = 1;
	mBuffer.ptr = malloc(size * sizeof(double));
	mBufferSize = size;
}

- (void) resetBuffer
{
	mLastMode = kSilence;
	
	if (mPrecision == kFloatPrecision)
		memset(mBuffer.floatData, 0, mBufferSize * sizeof(float));
	else
		memset(mBuffer.doubleData, 0, mBufferSize * sizeof(double));
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBBufferizer" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mTF setDoubleValue:mMaxRecordingTime * 1000.];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[self willChangeAudio];
	mMaxRecordingTime = [mTF doubleValue] / 1000.;
	if (mMaxRecordingTime < 0.) mMaxRecordingTime = 0.0001;
	if (mMaxRecordingTime > 60.) mMaxRecordingTime = 60.; // 60 sec should be enough
	[mTF setDoubleValue:mMaxRecordingTime * 1000.];
	[self updateBufferSize:mSampleRate];
	[self resetBuffer];
	[self didChangeAudio];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mMaxRecordingTime] forKey:@"val"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	NSNumber *n;
	
	n = [data objectForKey:@"val"];
	if (n) mMaxRecordingTime = [n doubleValue];
	
	if (mMaxRecordingTime < 0.) mMaxRecordingTime = 0.0001;
	if (mMaxRecordingTime > 60.) mMaxRecordingTime = 60.;
	
	return YES;
}

- (BOOL) interpolates
{
	return YES;
}

@end
