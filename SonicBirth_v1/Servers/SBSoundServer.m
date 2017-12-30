/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBSoundServer.h"
#import "SBSoundFile.h"
#import "SBCircuitDocument.h"
#import "SBElementServer.h"

SBSoundServer *gSoundServer = nil;


@implementation SBSoundServer

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mCpuUsage = 0;
		mCpuUsageDisplayDelay = 0;

		mAudioProcess = nil;
		mTempo = 120;
	
		mCalculatingOffset = 0;
		mBufferCount = 0;
		mSampleCount = 0;
		mCurSample = 0;
		mIsPlaying = NO;
		
		mDevice = [[MTCoreAudioDevice defaultOutputDevice] retain];
		if (!mDevice) { [self release]; return nil; }
		
		[mDevice	setIOTarget:self
					withSelector:@selector(ioCycleForDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:)
					withClientData:nil];
		
		mSampleRate = [mDevice nominalSampleRate];
		mMinFeedbackTime = mSampleRate * kMinFeedbackTime;
		
		int max = [mDevice deviceMaxBufferSizeInFrames];
		int cur = mSampleRate/10;
		if (cur > max) cur = max;
		
		[mDevice setDeviceBufferSizeInFrames:cur];
		
		mFramePerBuffer = [mDevice deviceBufferSizeInFrames];
		mInverseHostTicksPerBuffer = mSampleRate / (mFramePerBuffer * AudioGetHostClockFrequency());
		
		int size = mSampleRate * sizeof(double);
		
		mSilence.ptr = malloc(size);
		if (!mSilence.ptr) { [self release]; return nil; }
		memset(mSilence.ptr, 0, size);
		
		mTempoBuf.ptr = malloc(size);
		if (!mTempoBuf.ptr) { [self release]; return nil; }
		memset(mTempoBuf.ptr, 0, size);
		
		mBeatBuf.ptr = malloc(size);
		if (!mBeatBuf.ptr) { [self release]; return nil; }
		memset(mBeatBuf.ptr, 0, size);

		mDeviceChannels = 0;
		NSArray *a = [mDevice channelsByStreamForDirection:kMTCoreAudioDevicePlaybackDirection];
		if (a && [a count] > 0)
			mDeviceChannels = [(NSNumber*)[a objectAtIndex:0] intValue];
			
		mLock = [[NSLock alloc] init];
		if (!mLock) { [self release]; return nil; }
	}
	gSoundServer = self;
	return self;
}

- (void) dealloc
{
	gSoundServer = nil;
	
	int i;
	for (i = 0; i < mBufferCount; i++) free(mBuffers[i]);
	for (i = 0; i < mBufferCount; i++) free(mTempBuffers[i].ptr);
	
	if (mLock) [mLock release];
	if (mDevice) [mDevice release];
	if (mAudioProcess) [mAudioProcess release];
	if (mSilence.ptr) free(mSilence.ptr);
	if (mTempoBuf.ptr) free(mTempoBuf.ptr);
	if (mBeatBuf.ptr) free(mBeatBuf.ptr);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	//[super awakeFromNib];

	mLoops = ([mLoopButton state] == NSOnState);
	
	[mDeviceInfo setStringValue:[NSString stringWithFormat:@"Device: %i channels %.0f hz %.0f millisecs", 
					mDeviceChannels,
					[mDevice nominalSampleRate],
					(1000.f * (float)mFramePerBuffer) / (float)[mDevice nominalSampleRate] ]];
					
	[mTempoTF setDoubleValue:mTempo];
	[mCpuUsageTF setDoubleValue:0];
	
	NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:@"soundPanelShouldOpen"];
	if (!n || ([n intValue] == 2)) [mSoundPanel makeKeyAndOrderFront:self];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[mLock lock];
	mTempo = [mTempoTF doubleValue];
	if (mTempo < 0.1) mTempo = 0.1;
	else if (mTempo > 9999) mTempo = 9999;
	[mTempoTF setDoubleValue:mTempo];
	[mLock unlock];
}

- (IBAction) showPanel:(id)server
{
	if (!mSoundPanel) return;
	if ([mSoundPanel isVisible])
	{
		[mSoundPanel orderOut:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"soundPanelShouldOpen"];
	}
	else
	{
		[mSoundPanel makeKeyAndOrderFront:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:2] forKey:@"soundPanelShouldOpen"];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([aNotification object] == mSoundPanel)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"soundPanelShouldOpen"];
	}
}

- (IBAction) changedPlaybackPos:(id)sender
{
	if (mIsPlaying)
	{
		[mLock lock];
		mCurSample = [mPlaybackPos doubleValue] * mSampleCount;
		[mLock unlock];
	}
}

- (IBAction) pushedPlayButton:(id)sender
{
	[mPlayButton setState:NSOffState];
	[mPlayButton setTitle:@"Start"];
	[mOpenButton setEnabled:YES];
	
	mCpuUsage = 0;
	mCpuUsageDisplayDelay = 0;
	[mCpuUsageTF setDoubleValue:0];
	
	if (mIsPlaying)
	{
		[mDevice deviceStop]; mIsPlaying = NO;
		[mAudioProcess release]; mAudioProcess = nil;
	}
	else
	{
		// get the object
		NSDocumentController *dc = [NSDocumentController sharedDocumentController];
		NSDocument *cur = [dc currentDocument];
		if (cur)
		{
			if ([cur isKindOfClass:[SBCircuitDocument class]])
			{
				SBCircuitDocument *cdoc = (SBCircuitDocument *)cur;
				
				assert(mAudioProcess == nil);
				mAudioProcess = [[cdoc circuit] retain];
				
				[mAudioProcess  prepareForSamplingRate:mSampleRate
								sampleCount:kSamplesPerCycle
								precision:[mAudioProcess precision]
								interpolation:[mAudioProcess interpolation]];

				mCalculatingOffset = 0;
				mCurSample = [mPlaybackPos doubleValue] * mSampleCount;
				mIsPlaying = [mDevice deviceStart];
				if (mIsPlaying)
				{
					[mPlayButton setState:NSOnState];
					[mPlayButton setTitle:@"Stop"];
					[mOpenButton setEnabled:NO];
				}
				else NSLog(@"Problem while trying to start device (%@).\n", [mDevice description]);

			}
		}
	}
}

- (IBAction) pushedLoopButton:(id)sender
{
	[mLock lock];
	mLoops = ([mLoopButton state] == NSOnState);
	[mLock unlock];
}

- (IBAction) pushedOpenButton:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:YES];

	int result = [panel runModalForTypes:[SBSoundFile supportedExtensions]];

	if (result != NSOKButton) return;

	NSString *path = [panel filename];
	
	SBSoundFile *file = [[SBSoundFile alloc] initForPath:path forceSampleRate:mSampleRate];
	if (!file)
	{
		NSRunAlertPanel(@"SonicBirth", @"Could not open file.", @"", @"", @"");
		return;
	}
	
	int i;
	for (i = 0; i < mBufferCount; i++) free(mBuffers[i]);
	for (i = 0; i < mBufferCount; i++) free(mTempBuffers[i].ptr);
	mBufferCount = 0;
	
	mSampleCount = [file numberOfFrames];
	mBufferCount = [file numberOfChannels];
	for (i = 0; i < mBufferCount; i++)
	{
		mBuffers[i] = malloc(mSampleCount * sizeof(float));
		mTempBuffers[i].ptr = malloc(mSampleRate * sizeof(double));
		assert(mBuffers[i]);
		assert(mTempBuffers[i].ptr);
	}
	
	BOOL isOK = [file readSamples:mSampleCount offset:0 baseChannel:0 countChannel:mBufferCount inBuffers:mBuffers];
	if (!isOK)
	{
		NSRunAlertPanel(@"SonicBirth", @"Problem reading file.", @"", @"", @"");
		for (i = 0; i < mBufferCount; i++) free(mBuffers[i]);
		for (i = 0; i < mBufferCount; i++) free(mTempBuffers[i].ptr);
		mBufferCount = 0;
		[mFilePath setStringValue:@"No file open."];
		[mFileInfo setStringValue:@"No file open."];
		[file release];
		return;
	}

	[mFilePath setStringValue:path];
	[mFileInfo setStringValue:[NSString stringWithFormat:@"File: %i channels %i hz %.1f secs", 
						[file numberOfChannels], [file sampleRate],
						(float)[file numberOfFrames] / (float)[file sampleRate] ]];
	
	[file release];
}

// MTCoreAudio callback
- (OSStatus)	ioCycleForDevice:(MTCoreAudioDevice *)theDevice
				timeStamp:(const AudioTimeStamp *)inNow
				inputData:(const AudioBufferList *)inInputData
				inputTime:(const AudioTimeStamp *)inInputTime
				outputData:(AudioBufferList *)outOutputData
				outputTime:(const AudioTimeStamp *)inOutputTime
				clientData:(void *)inClientData
{
	unsigned long long entryTime = AudioGetCurrentHostTime();

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[mLock lock];
	[mAudioProcess lock];

	AudioBuffer *ab = outOutputData->mBuffers;
	int channels = ab->mNumberChannels;
	int framesPerBuffer = ab->mDataByteSize / (channels * sizeof(float));
	float *outbuf = (float*)ab->mData;
	float *outptr = outbuf;
	int i, samplesToZero, inputs = [mAudioProcess numberOfInputs];
	int outputs = [mAudioProcess numberOfOutputs];
	SBBuffer buffers[kMaxChannels];

	if (outOutputData->mNumberBuffers <= 0) goto stop;
	if (mBufferCount && mCurSample >= mSampleCount) goto stop;
	if (framesPerBuffer != mFramePerBuffer) goto stop;
	
	SBPrecision precision = [mAudioProcess precision];
	
	BOOL needsTempo = [(SBRootCircuit*)mAudioProcess needsTempo];
	int inBufOffset = (needsTempo) ? 2 : 0;
	if (needsTempo)
	{
		if (precision == kFloatPrecision)
		{
			for (i = 0; i < framesPerBuffer; i++)
				mTempoBuf.floatData[i] = mTempo;
				
			
			float scale = mTempo / (mSampleRate * 60);
			if (mBufferCount)
				for (i = 0; i < framesPerBuffer; i++)
					mBeatBuf.floatData[i] = ((mCurSample + i) % mSampleCount) * scale;
			else
				for (i = 0; i < framesPerBuffer; i++)
					mBeatBuf.floatData[i] = (mCurSample + i) * scale;
		}
		else
		{
			for (i = 0; i < framesPerBuffer; i++)
				mTempoBuf.doubleData[i] = mTempo;
				
			double scale = mTempo / (mSampleRate * 60);
			if (mBufferCount)
				for (i = 0; i < framesPerBuffer; i++)
					mBeatBuf.doubleData[i] = ((mCurSample + i) % mSampleCount) * scale;
			else
				for (i = 0; i < framesPerBuffer; i++)
					mBeatBuf.doubleData[i] = (mCurSample + i) * scale;
		}
		buffers[0] = mTempoBuf;
		buffers[1] = mBeatBuf;
	}

	// -----------------------------------------------------------------------
	// prepare input buffers
	// -----------------------------------------------------------------------
	if (mBufferCount && (mSampleCount - mCurSample >= framesPerBuffer) && (precision == kFloatPrecision))
	{
		// reuse buffer
		int j;
		for (i = inBufOffset, j = 0; i < mBufferCount + inBufOffset; i++, j++)
			buffers[i].floatData = mBuffers[j] + mCurSample;

		mCurSample += framesPerBuffer;
	}
	else if (mBufferCount)
	{
		int curj = 0, j = curj;
		int curk = mCurSample, k = curk;
		int curf = framesPerBuffer, f = curf;
	
process:
		if (precision == kFloatPrecision)
		{
			for (i = 0; i < mBufferCount; i++)
				for(j = curj, k = curk, f = curf; f > 0 && k < mSampleCount; f--, k++, j++)
					(mTempBuffers[i].floatData)[j] = mBuffers[i][k];
		}
		else
		{
			for (i = 0; i < mBufferCount; i++)
				for(j = curj, k = curk, f = curf; f > 0 && k < mSampleCount; f--, k++, j++)
					(mTempBuffers[i].doubleData)[j] = mBuffers[i][k];
		}		
		
		curj = j;
		mCurSample = curk = k;
		framesPerBuffer = curf = f;
				
		if (framesPerBuffer > 0)
		{
			if (mLoops)
			{
				mCurSample = curk = 0;
				goto process;
			}
			else
			{   
				// silence remaining portion
				if (precision == kFloatPrecision)
				{
					for (i = 0; i < mBufferCount; i++)
						for(j = curj, f = curf; f > 0; f--, j++)
							(mTempBuffers[i].floatData)[j] = 0.f;
				}
				else
				{
					for (i = 0; i < mBufferCount; i++)
						for(j = curj, f = curf; f > 0; f--, j++)
							(mTempBuffers[i].doubleData)[j] = 0.f;
				}
			}
		}
		
		for (i = inBufOffset, j = 0; i < mBufferCount + inBufOffset; i++, j++)
			buffers[i] = mTempBuffers[j];
	}
	else
		mCurSample += framesPerBuffer;
	
	for (i = mBufferCount + inBufOffset; i < inputs; i++)
			buffers[i] = mSilence;

	for (i = 0; i < inputs; i++)
			mAudioProcess->pInputBuffers[i] =  buffers[i];

	#define CHECK_OUTPUT_BUFFER \
	if (outputs == 1) \
	{ \
		buffers[0] = [mAudioProcess outputAtIndex:0]; \
		for (i = 1; i < channels; i++) \
			buffers[i] = buffers[0]; \
	} \
	else \
	{ \
		for (i = 0; i < outputs; i++) \
			buffers[i] = [mAudioProcess outputAtIndex:i]; \
			 \
		for (i = outputs; i < channels; i++) \
			buffers[i] = mSilence; \
	}

	// -----------------------------------------------------------------------
	// calculate
	// -----------------------------------------------------------------------
	if ([mAudioProcess hasFeedback])
	{
		framesPerBuffer = mFramePerBuffer;
		while(framesPerBuffer > 0)
		{
			if (mCalculatingOffset >= kSamplesPerCycle) mCalculatingOffset = 0;
		
			int todo = framesPerBuffer;
			int offset = mCalculatingOffset;
			int place = kSamplesPerCycle - offset;
			
			if (todo > place) todo = place; 
			if (todo > mMinFeedbackTime) todo = mMinFeedbackTime;

			if (precision == kFloatPrecision)
				for (i = 0; i < inputs; i++) mAudioProcess->pInputBuffers[i].floatData -= offset;
			else
				for (i = 0; i < inputs; i++) mAudioProcess->pInputBuffers[i].doubleData -= offset;

			(mAudioProcess->pCalcFunc)(mAudioProcess, todo, offset);
			
			if (precision == kFloatPrecision)
				for (i = 0; i < inputs; i++) mAudioProcess->pInputBuffers[i].floatData += offset + todo;
			else
				for (i = 0; i < inputs; i++) mAudioProcess->pInputBuffers[i].doubleData += offset + todo;
			
			mCalculatingOffset += todo;
			framesPerBuffer -= todo;

			// -----------------------------------------------------------------------
			// copy back to interleaved data
			// -----------------------------------------------------------------------
			CHECK_OUTPUT_BUFFER
			
			int j;
			if (precision == kFloatPrecision)
			{
				for(j = offset; todo--; j++)
					for (i = 0; i < channels; i++)
						*outptr++ = (buffers[i].floatData)[j];
			}
			else
			{
				for(j = offset; todo--; j++)
					for (i = 0; i < channels; i++)
						*outptr++ = (buffers[i].doubleData)[j];
			}
		}
	}
	else // no feedback
	{
		// simple case
		framesPerBuffer = mFramePerBuffer;
		while(framesPerBuffer > 0)
		{
			int todo = framesPerBuffer;
			if (todo > kSamplesPerCycle) todo = kSamplesPerCycle;
						
			(mAudioProcess->pCalcFunc)(mAudioProcess, todo, 0);
			
			framesPerBuffer -= todo;
			if (precision == kFloatPrecision)
				for (i = 0; i < inputs; i++) mAudioProcess->pInputBuffers[i].floatData += todo;
			else
				for (i = 0; i < inputs; i++) mAudioProcess->pInputBuffers[i].doubleData += todo;

			// -----------------------------------------------------------------------
			// copy back to interleaved data
			// -----------------------------------------------------------------------
			CHECK_OUTPUT_BUFFER
			
			int count = todo;
			if (precision == kFloatPrecision)
			{
				while(count--)
					for (i = 0; i < channels; i++)
						*outptr++ = *(buffers[i].floatData)++;
			}
			else
			{
				while(count--)
					for (i = 0; i < channels; i++)
						*outptr++ = *(buffers[i].doubleData)++;
			}
		}
	}
	
	if (mBufferCount) [mPlaybackPos setDoubleValue: (double)mCurSample / (double)mSampleCount ];

	[mAudioProcess unlock];
	[mLock unlock];

	// cpu usage calculation
	unsigned long long exitTime = AudioGetCurrentHostTime();
	unsigned long long totalTime = exitTime - entryTime;
	double newUsage = totalTime * mInverseHostTicksPerBuffer;
	mCpuUsage = (mCpuUsage * 0.95) + (newUsage * 0.05); // lowpass it a bit
	mCpuUsageDisplayDelay += mFramePerBuffer;
	if (mCpuUsageDisplayDelay > (mSampleRate << 1)) // update every 2 sec
	{
		mCpuUsageDisplayDelay = 0;
		[mCpuUsageTF setDoubleValue:mCpuUsage * 100.];
	}
	
	[pool release];
	return 0;

stop:
	[mLock unlock];
	[mAudioProcess unlock];

	samplesToZero = framesPerBuffer * channels;
	while(samplesToZero--) *outptr++ = 0.f;
	
	/*[mDevice deviceStop];*/ mIsPlaying = NO;
	[mAudioProcess release]; mAudioProcess = nil;
	[mPlayButton setState:NSOffState];
	[mPlayButton setTitle:@"Start"];
	[mOpenButton setEnabled:YES];
	
	[mPlaybackPos setDoubleValue: 0. ];

	[pool release];
	return 1;

}

- (SBAudioProcess*) currentAudioProcess
{
	return mAudioProcess;
}

- (void) stop
{
	if (mIsPlaying)
	{
		[mDevice deviceStop]; mIsPlaying = NO;
		[mAudioProcess release]; mAudioProcess = nil;
		
		[mPlayButton setState:NSOffState];
		[mPlayButton setTitle:@"Start"];
		[mOpenButton setEnabled:YES];
	}
}

- (IBAction) doSpeedTest:(id)sender
{
	NSDocumentController *dc = [NSDocumentController sharedDocumentController];
	NSDocument *cur = [dc currentDocument];
	if (!cur) return;
	if (![cur isKindOfClass:[SBCircuitDocument class]]) return;
	
	SBCircuitDocument *cdoc = (SBCircuitDocument *)cur;
	SBAudioProcess *audioProcess = [cdoc circuit];	
	if (!audioProcess) return;

	[audioProcess  prepareForSamplingRate:mSampleRate
							sampleCount:kSamplesPerCycle
							precision:[audioProcess precision]
							interpolation:[audioProcess interpolation]];
							
	int i, inputs = [audioProcess numberOfInputs];
	for (i = 0; i < inputs; i++)
		audioProcess->pInputBuffers[i] =  mSilence;
		
	double secondsPerTicks = 1. / AudioGetHostClockFrequency();
	unsigned long long entryTime = AudioGetCurrentHostTime();
	double seconds = 0;
	
	int c = 10;
	for (i = 0; i < c; i++)
	{
		int j;
		for (j = 0; j < 1000; j++)
			(audioProcess->pCalcFunc)(audioProcess, kSamplesPerCycle, 0);
		
		seconds = (AudioGetCurrentHostTime() - entryTime) * secondsPerTicks;
		
		if (seconds > 5.)
			c = i + 1;
	}

	c *= 1000;
	
	int processedSamples = kSamplesPerCycle * c;
	double processedSeconds = processedSamples / 44100.;
	
	NSRunAlertPanel(@"Speed result",
						[NSString stringWithFormat:@"Took %.3f seconds to process %i samples of silence"
													@" (%.1f seconds at 44100 Hz) - %.2fx realtime. ",
							seconds, processedSamples, processedSeconds, processedSeconds / seconds ],
						nil, nil, nil);
}

- (IBAction) doSpeedTestAllElements:(id)sender
{
	[mSpeedResultsText setString:@""];
	
	NSMutableParagraphStyle *ps = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[ps setTabStops:[NSArray arrayWithObjects:
						[[[NSTextTab alloc] initWithType:NSLeftTabStopType location:400] autorelease],
						[[[NSTextTab alloc] initWithType:NSLeftTabStopType location:600] autorelease], nil]];
	
	[mSpeedResultsText setTypingAttributes:
			[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:ps, [NSFont fontWithName:@"Courier" size:12], nil]
								      	forKeys:[NSArray arrayWithObjects:NSParagraphStyleAttributeName, NSFontAttributeName, nil]]];
	
	[mSpeedResultsWindow makeKeyAndOrderFront:self];
	[NSThread detachNewThreadSelector:@selector(speedTestAllElements) toTarget:self withObject:nil];
}

- (void) speedTestAllElements
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (!pool) return;

	NSMutableString *ms = [[NSMutableString alloc] init];
	if (!ms) return;
	
	[ms appendString:@"Beginning tests...\n"];
	[ms appendString:@"Values are times real time at 44100 Hz.\n"];
	
	#define kMaxInputs (100)
	
	// alloc float and double random
	float *floatBuffer = (float*) malloc ((kSamplesPerCycle + kMaxInputs)  * sizeof(float));
	double *doubleBuffer = (double*) malloc ((kSamplesPerCycle + kMaxInputs) * sizeof(double));
	
	if (!floatBuffer || !doubleBuffer)
	{
		if (floatBuffer) free(floatBuffer);
		if (doubleBuffer) free(doubleBuffer);
		[pool release];
		[ms release];
		return;
	}
	
	// fill them
	int i, c = (kSamplesPerCycle + kMaxInputs);
	for (i = 0; i < c; i++)
	{
		double r = (((double)random() * 2.) /  ((double)(0x7FFFFFFF))) - 1.;
		floatBuffer[i] = r;
		doubleBuffer[i] = r;
	}

	NSArray *elements = [gElementServer rawElements];
	c = [elements count];
	
	double secondsPerTicks = 1. / AudioGetHostClockFrequency();
	
	int interp;
	for (interp = 0; interp < 3; interp++)
	{
		if (interp == 0) [ms appendString:@"\nTesting non-interpolating elements...\n"];
		else if (interp == 1) [ms appendString:@"\nTesting interpolating elements (no interpolation)...\n"];
		else if (interp == 2) [ms appendString:@"\nTesting interpolating elements (linear interpolation)...\n"];
		
		[ms appendString:@"\nName (Internal name)\t32 bits\t64 bits\n"];
		[ms appendString:@"--------------------\t-------\t-------\n"];
		[mSpeedResultsText setString:ms];

		// test each element
		for (i = 0; i < c; i++)
		{
			NSAutoreleasePool *secondPool = [[NSAutoreleasePool alloc] init];
		
			SBElement *oe = [elements objectAtIndex:i];
			if ([oe category] == kInternal)
			{
				if (secondPool) [secondPool release];
				continue;
			}
			
			BOOL interpolates = [oe interpolates];
			if (!interp && interpolates)
			{
				if (secondPool) [secondPool release];
				continue;
			}
			
			if (interp && !interpolates)
			{
				if (secondPool) [secondPool release];
				continue;
			}
			
			NSString *className = [oe className];
			
			SBElement *e = [gElementServer createElement:className];
			if (!e)
			{
				NSLog(@"Cannot create: %@", className);
				if (secondPool) [secondPool release];
				continue;
			}
			
			
			NSString *elementName = [[e class] name];
			
			//NSLog(@"Testing %@ (%@)...", elementName, className);
		
			// connect inputs
			int j, inputs = [e numberOfInputs];
			
			// test 32 bits
			for (j = 0; j < inputs; j++)
			{
				if ([e typeOfInputAtIndex:j] == kNormal)
					e->pInputBuffers[j].floatData = floatBuffer + (j % kMaxInputs);
				else
					e->pInputBuffers[j] = mSilence;
			}
			
			[e  prepareForSamplingRate:44100
					sampleCount:kSamplesPerCycle
					precision:kFloatPrecision
					interpolation:(interp < 2) ? kNoInterpolation : kInterpolationLinear];
			
			unsigned long long entryTime = AudioGetCurrentHostTime();
			double seconds = 0;
			
			int c = 10;
			for (j = 0; j < c; j++)
			{
				int k;
				for (k = 0; k < 1000; k++)
					(e->pCalcFunc)(e, kSamplesPerCycle, 0);
				
				seconds = (AudioGetCurrentHostTime() - entryTime) * secondsPerTicks;
				
				if (seconds > 5.)
					c = j + 1;
			}

			c *= 1000;
			
			int processedSamples = kSamplesPerCycle * c;
			double processedSeconds = processedSamples / 44100.;
			double speed32 = processedSeconds / seconds;
			
			// test 64 bits
			for (j = 0; j < inputs; j++)
			{
				if ([e typeOfInputAtIndex:j] == kNormal)
					e->pInputBuffers[j].doubleData = doubleBuffer + (j % kMaxInputs);
				else
					e->pInputBuffers[j] = mSilence;
			}
			[e  prepareForSamplingRate:44100
					sampleCount:kSamplesPerCycle
					precision:kDoublePrecision
					interpolation:(interp < 2) ? kNoInterpolation : kInterpolationLinear];
			
			entryTime = AudioGetCurrentHostTime();
			seconds = 0;
			
			c = 10;
			for (j = 0; j < c; j++)
			{
				int k;
				for (k = 0; k < 1000; k++)
					(e->pCalcFunc)(e, kSamplesPerCycle, 0);
				
				seconds = (AudioGetCurrentHostTime() - entryTime) * secondsPerTicks;
				
				if (seconds > 5.)
					c = j + 1;
			}

			c *= 1000;
			
			processedSamples = kSamplesPerCycle * c;
			processedSeconds = processedSamples / 44100.;
			double speed64 = processedSeconds / seconds;
			
			// append result
			[ms appendFormat:@"%@ (%@)\t%.2f\t%.2f\n",
							elementName, className, speed32, speed64];
			[mSpeedResultsText setString:ms];
		
			// test if window is closed (and stop if so)
			if (![mSpeedResultsWindow isVisible])
			{
				if (secondPool) [secondPool release];
				break;
			}
				
			// reclaim memory
			if (secondPool) [secondPool release];
		}
	}
	
	[ms appendString:@"\nTests finished.\n"];
	[mSpeedResultsText setString:ms];
	
	free(floatBuffer);
	free(doubleBuffer);
	[pool release];
	[ms release];
}

@end
