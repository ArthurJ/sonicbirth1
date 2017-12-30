/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBDelay.h"

#import "SBInterpolation.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBDelay *obj = inObj;

	int samplerate = obj->mSampleRate;
	int bufSize = obj->mBufferSize;
	int curPos = obj->mCurSample;

#define CALCULATE_FOR_INTERPOLATION(_interpf, _interpd) \
	if (obj->mPrecision == kFloatPrecision) \
	{ \
		float *input = obj->pInputBuffers[0].floatData + offset; \
		float *delay = obj->pInputBuffers[1].floatData + offset; \
		float *output = obj->mAudioBuffers[0].floatData + offset; \
		float *buf = obj->mBuffer.floatData; \
		float max = obj->mValue * samplerate - 1; \
		while(count--) \
		{ \
			buf[curPos] = *input++;  \
			float ndelay = *delay++; \
			if (ndelay <= 0.) *output++ = buf[curPos]; \
			else \
			{ \
				ndelay *= samplerate; \
				if (ndelay > max) ndelay = max; \
				*output++ = _interpf(curPos - ndelay, buf, bufSize); \
			} \
			curPos++; if (curPos >= bufSize) curPos = 0; \
		} \
	} \
	else if (obj->mPrecision == kDoublePrecision) \
	{ \
		double *input = obj->pInputBuffers[0].doubleData + offset; \
		double *delay = obj->pInputBuffers[1].doubleData + offset; \
		double *output = obj->mAudioBuffers[0].doubleData + offset; \
		double *buf = obj->mBuffer.doubleData; \
		double max = obj->mValue * samplerate - 1; \
		while(count--) \
		{ \
			buf[curPos] = *input++;  \
			double ndelay = *delay++; \
			if (ndelay <= 0.) *output++ = buf[curPos]; \
			else \
			{ \
				ndelay *= samplerate; \
				if (ndelay > max) ndelay = max; \
				*output++ = _interpd(curPos - ndelay, buf, bufSize); \
			} \
			curPos++; if (curPos >= bufSize) curPos = 0; \
		} \
	}
	
	switch(obj->mInterpolation)
	{
		case kNoInterpolation:
			CALCULATE_FOR_INTERPOLATION(interpolate_float_no, interpolate_double_no)
			break;
			
		case kInterpolationLinear:
			CALCULATE_FOR_INTERPOLATION(interpolate_float_lin, interpolate_double_lin)
			break;
	}
	
	#undef CALCULATE_FOR_INTERPOLATION
	
	obj->mCurSample = curPos;
}

@implementation SBDelay

+ (NSString*) name
{
	return @"Delay";
}

- (NSString*) name
{
	return @"dly";
}

+ (SBElementCategory) category
{
	return kDelay;
}

- (NSString*) informations
{
	return	@"Delays the input signal by a variable time (maximum is user specified - clamped to 60 seconds). "
			@"The dly input is in seconds.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		mValue = 1.;
		mBuffer.ptr = nil;
	
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"dly"];
		
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
	int size = mValue * sampleRate;
	if (size == 0) size = 1;
	mBuffer.ptr = malloc(size * sizeof(double));
	mBufferSize = size;
}

- (void) resetBuffer
{
	mCurSample = 0;
	
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
		[NSBundle loadNibNamed:@"SBDelay" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mTF setDoubleValue:mValue * 1000.];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[self willChangeAudio];
	mValue = [mTF doubleValue] / 1000.;
	if (mValue < 0.) mValue = 0.0001;
	if (mValue > 60.) mValue = 60.; // 60 sec should be enough
	[mTF setDoubleValue:mValue * 1000.];
	[self updateBufferSize:mSampleRate];
	[self resetBuffer];
	[self didChangeAudio];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mValue] forKey:@"val"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	NSNumber *n;
	
	n = [data objectForKey:@"val"];
	if (n) mValue = [n doubleValue];
	
	if (mValue < 0.) mValue = 0.0001;
	if (mValue > 60.) mValue = 60.;
	
	return YES;
}

- (BOOL) interpolates
{
	return YES;
}

@end
