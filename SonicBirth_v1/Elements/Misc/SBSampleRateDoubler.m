/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSampleRateDoubler.h"
#import "SBCircuit.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSampleRateDoubler *obj = inObj;

	if (count <= 0) return;

	int i, j, c, o2 = offset*2, c2 = count*2;
	SBCircuit *cir = obj->mCircuit;
	
	// convert input
	c = obj->mInputAudioBuffersCount;
	if (obj->mPrecision == kFloatPrecision)
	{
		for (i = 0; i < c; i++)
		{
			float *inp = obj->pInputBuffers[i].floatData + offset;
			float *buf = obj->mInputAudioBuffers[i].floatData + o2;
			j = 0;
			if (offset == 0)
			{
				*buf++ = (obj->mInputAudioBuffers[i].floatData[obj->mLastPos] + *inp) * 0.5f;
				*buf++ = *inp++;
				j++;
			}
			for(; j < count; j++)
			{
				*buf++ = (inp[-1] + *inp) * 0.5f;
				*buf++ = *inp++;
			}
		}
	}
	else // double precision
	{
		for (i = 0; i < c; i++)
		{
			double *inp = obj->pInputBuffers[i].doubleData + offset;
			double *buf = obj->mInputAudioBuffers[i].doubleData + o2;
			j = 0;
			if (offset == 0)
			{
				*buf++ = (obj->mInputAudioBuffers[i].doubleData[obj->mLastPos] + *inp) * 0.5;
				*buf++ = *inp++;
				j++;
			}
			for(; j < count; j++)
			{
				*buf++ = (inp[-1] + *inp) * 0.5;
				*buf++ = *inp++;
			}
		}
	}
	obj->mLastPos = (o2 + c2) - 1;

	// execute it
	(cir->pCalcFunc)(cir, c2, o2);
	
	// copy back the output
	c = obj->mAudioBuffersCount;
	if (obj->mPrecision == kFloatPrecision)
	{
		for (i = 0; i < c; i++)
		{
			float *oup = cir->pOutputBuffers[i].floatData + o2;
			float *buf = obj->mAudioBuffers[i].floatData + offset;
			for (j = 0; j < count; j++)
			{
				float t = *oup++; t += *oup++; t *= 0.5f;
				*buf++ = t;
			}
		}
	}
	else // double precision
	{
		for (i = 0; i < c; i++)
		{
			double *oup = cir->pOutputBuffers[i].doubleData + o2;
			double *buf = obj->mAudioBuffers[i].doubleData + offset;
			for (j = 0; j < count; j++)
			{
				double t = *oup++; t += *oup++; t *= 0.5;
				*buf++ = t;
			}
		}
	}
}


@implementation SBSampleRateDoubler

+ (NSString*) name
{
	return @"Samplerate Doubler";
}

- (NSString*) name
{
	return @"sr dbl";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return	@"Audio processing inside this circuit is done at double sample rate, "
			@"which can be useful (sounds better) for some type of calculations (filters).";
}


- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		mCircuit = [[SBCircuit alloc] init];
		if (!mCircuit)
		{
			[self release];
			return nil;
		}
		
		[mCircuit setCanChangeNumberOfInputsOutputs:NO];
		[mCircuit setCanChangeInputsOutputsTypes:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementWillChangeAudio:)
						name:kSBElementWillChangeAudioNotification
						object:mCircuit];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeAudio:)
						name:kSBElementDidChangeAudioNotification
						object:mCircuit];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeConnections:)
						name:kSBElementDidChangeConnectionsNotification
						object:mCircuit];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeName:)
						name:kSBCircuitDidChangeNameNotification
						object:mCircuit];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (mCircuit) [mCircuit release];
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBSampleRateDoubler" owner:self];
		return mSettingsView;
	}
}

- (NSString*) nameOfInputAtIndex:(int)idx
{
	return [mCircuit nameOfInputAtIndex:idx];
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	return [mCircuit nameOfOutputAtIndex:idx];
}

- (int) numberOfInputs
{
	return [mCircuit numberOfInputs];
}
- (int) numberOfOutputs
{
	return [mCircuit numberOfOutputs];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mInputTF setIntValue:[mCircuit numberOfInputs]];
	[mOutputTF setIntValue:[mCircuit numberOfOutputs]];
}

- (SBCircuit*)subCircuit
{
	return mCircuit;
}

- (void) controlTextDidEndEditing:(NSNotification *)aNotification
{
	[self willChangeAudio];
	mLockIsHeld = YES;

	id tf = [aNotification object];
	if (tf == mInputTF)
	{
		[mCircuit setNumberOfInputs:[mInputTF intValue]];
		[mInputTF setIntValue:[mCircuit numberOfInputs]];
	}
	else if (tf == mOutputTF)
	{
		[mCircuit setNumberOfOutputs:[mOutputTF intValue]];
		[mOutputTF setIntValue:[mCircuit numberOfOutputs]];
	}

	// as we may have more output than before, we need to allocate them...
	[self prepareForSamplingRate:mSampleRate
			sampleCount:mSampleCount
			precision:mPrecision
			interpolation:mInterpolation];
		
	// as we may have more input than before, we need to allocate them...
	if ([self numberOfInputs] != mInputAudioBuffersCount) [self redoInputs];

	[self didChangeConnections];
	[self didChangeAudio];
	mLockIsHeld = NO;

	[self didChangeGlobalView];
}

- (void) reset
{
	[super reset];
	[mCircuit reset];
	
	int i, c = mInputAudioBuffersCount, s = mSampleCount*2 * sizeof(double);
	for (i = 0; i < c; i++) memset(mInputAudioBuffers[i].ptr, 0, s);
	
	mLastPos = 0;
}

- (void) specificPrepare
{
	[mCircuit prepareForSamplingRate:mSampleRate*2
			sampleCount:mSampleCount*2
			precision:mPrecision
			interpolation:mInterpolation];

	[self redoInputs];
}

- (void) redoInputs
{
	int i, c = mInputAudioBuffersCount, s = mSampleCount*2 * sizeof(double);
	for (i = 0; i < c; i++) free(mInputAudioBuffers[i].ptr);
		
	c = mInputAudioBuffersCount = [self numberOfInputs];
	for (i = 0; i < c; i++)
	{
		mInputAudioBuffers[i].ptr = malloc(s);
		assert(mInputAudioBuffers[i].ptr);
	}
	
	for (i = 0; i < c; i++) mCircuit->pInputBuffers[i] = mInputAudioBuffers[i];
}

- (void) changePrecision:(SBPrecision)precision
{
	int i, j;
	
	if (mPrecision == precision) return;
	
	int sampleCount = mSampleCount * 2;
	if (mPrecision == kFloatPrecision)
	{
		// float to double
		for (i = 0; i < mInputAudioBuffersCount; i++)
			for (j = sampleCount - 1; j >= 0; j--)
				mInputAudioBuffers[i].doubleData[j] = mInputAudioBuffers[i].floatData[j];

	}
	else
	{
		// double to float
		for (i = 0; i < mInputAudioBuffersCount; i++)
			for (j = 0; j < sampleCount; j++)
				mInputAudioBuffers[i].floatData[j] = mInputAudioBuffers[i].doubleData[j];
	}

	[super changePrecision:precision];
	[mCircuit changePrecision:precision];
}

- (void) changeInterpolation:(SBInterpolation)interpolation
{
	[super changeInterpolation:interpolation];
	[mCircuit changeInterpolation:interpolation];
}

- (BOOL) interpolates
{
	return [mCircuit interpolates];
}

- (BOOL) hasFeedback
{
	return [mCircuit hasFeedback];
}

- (void) trimDebug
{
	[mCircuit trimDebug];
}

- (void) setMiniMode:(BOOL)mini
{
	[mCircuit setMiniMode:mini];
}

- (void) setColorsBack:(NSColor*)back contour:(NSColor*)contour front:(NSColor*)front
{
	[super	setColorsBack:back
			contour:contour
			front:front];
					
	[mCircuit	setColorsBack:back
				contour:contour
				front:front];
}

- (void) setLastCircuit:(BOOL)isLastCircuit
{
	[super setLastCircuit:isLastCircuit];
	[mCircuit setLastCircuit:isLastCircuit];
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	return [mCircuit typeOfInputAtIndex:idx];
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	return [mCircuit typeOfOutputAtIndex:idx];
}

- (void) subElementWillChangeAudio:(NSNotification *)notification
{
	if (!mLockIsHeld) [self willChangeAudio];
}

- (void) subElementDidChangeAudio:(NSNotification *)notification
{
	if (!mLockIsHeld) [self didChangeAudio];
}

- (void) subElementDidChangeConnections:(NSNotification *)notification
{
	[self didChangeConnections];
	[self didChangeGlobalView];
}

- (void) subElementDidChangeName:(NSNotification *)notification
{
	[self didChangeGlobalView];
}

- (NSMutableDictionary*) saveData
{
	return [mCircuit saveData];
}

- (BOOL) loadData:(NSDictionary*)data
{
	return [mCircuit loadData:data];
}

@end
