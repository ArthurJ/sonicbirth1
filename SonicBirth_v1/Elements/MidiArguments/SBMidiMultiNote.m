/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMidiMultiNote.h"
#import "SBCircuit.h"

#define kNoteOff (-1)
#define kNeverEnd (-1)

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBMidiMultiNote *obj = inObj;

	int	*note = obj->mState->mNote;
	int	*position = obj->mState->mPosition;
	int	*start = obj->mState->mStart;
	int	*end = obj->mState->mEnd;
	int *useCount = obj->mState->mUseCount;
	double *noteHertz = obj->mState->mNoteHertz;
	SBBuffer *noteBuffers = obj->mState->mNoteBuffers;
	int internalInputs = obj->mInternalInputs;
	
	int	*attack = obj->mAttack;
	int	*release = obj->mRelease;
	
	BOOL ownState = obj->mOwnState;
	
	SBCircuit **circuits = obj->mCircuits;
	
	int outputs = obj->mOutputCount;
	SBPrecision precision = obj->mPrecision;
	int i;
	
	if (ownState)
	{
		for (i = 0; i < kMaxVoices; i++)
		{
			if (note[i] != kNoteOff)
			{
				// splat the note
				if (precision == kFloatPrecision)
				{
					float cnote = noteHertz[i];
					float *notedst = noteBuffers[i].floatData + offset;
					int j;
					for (j = 0; j < count; j++)
						*notedst++ = cnote;
				}
				else // double precision
				{
					double cnote = noteHertz[i];
					double *notedst = noteBuffers[i].doubleData + offset;
					int j;
					for (j = 0; j < count; j++)
						*notedst++ = cnote;
				}
			}
		}
	}
	
	// get attack and release
	int sr = obj->mSampleRate, sr60 = sr * 60;
	int cattack, crelease;
	if (obj->mPrecision == kFloatPrecision)
	{
		cattack = obj->pInputBuffers[0].floatData[offset] * 0.001f * sr;
		crelease = obj->pInputBuffers[1].floatData[offset] * 0.001f * sr;
	}
	else
	{
		cattack = obj->pInputBuffers[0].doubleData[offset] * 0.001 * sr;
		crelease = obj->pInputBuffers[1].doubleData[offset] * 0.001 * sr;
	}
	if (cattack < 0) cattack = 0;
	else if (cattack > sr60) cattack = sr60;
	
	if (crelease < 0) crelease = 0;
	else if (crelease > sr60) crelease = sr60;
	
	// clear outputs
	if (obj->mPrecision == kFloatPrecision)
	{
		for (i = 0; i < outputs; i++)
			memset(obj->mAudioBuffers[i].floatData + offset,
					0, count * sizeof(float));
	}
	else // double precision
	{
		for (i = 0; i < outputs; i++)
			memset(obj->mAudioBuffers[i].doubleData + offset,
					0, count * sizeof(double));
	}
	
	// execute active note
	for (i = 0; i < kMaxVoices; i++)
	{
		if (note[i] != kNoteOff)
		{
			SBCircuit *c = circuits[i];
			
			int pos = position[i];
			
			if (pos == 0)
			{
				[c reset];
				attack[i] = cattack;
				release[i] = crelease;
			}
			
			int cr = release[i];
			int ca = attack[i];

			int cstart = start[i] - pos;
			if (cstart < 0) cstart = 0;
			
			int oend = end[i], cend = (oend - pos) + cr;
			if ((oend == kNeverEnd) || (cend > count)) 
				cend = count;

			// if we end our use of this note this turn, mark it
			if (oend != kNeverEnd && pos <= (oend + cr) && (pos + count) > (oend + cr))
				useCount[i]--;

			int copycount = cend - cstart;
			if (copycount > 0)
			{
				// connect the inputs
				int inputCount = obj->mInputCount, inputIndex;
				for (inputIndex = 0; inputIndex < inputCount; inputIndex++)
					c->pInputBuffers[inputIndex + 2] = obj->pInputBuffers[inputIndex + internalInputs];
					
				// splat the velocity
				if (precision == kFloatPrecision)
				{
					float velo = obj->mState->mVelo[i];
					float *dst = obj->mVeloBuffers[i].floatData + offset + cstart;

					int k;
					if (pos < ca && oend != kNeverEnd && (pos + count) > oend) // attack _and_ release
					{
						float inva = 1.f / ca;
						float invr = 1.f / cr;
						int cpa = pos;
						int cpr = oend + cr - pos;
						
						for (k = 0; k < copycount && cpa < ca && cpr > cr; k++, cpr--)
							*dst++ = velo * cpa++ * inva;
							
						float max = oend * inva;
						if (max > 1.f) max = 1.f;	
						
						for (; k < copycount && cpr > 0; k++)
						{
							float cur = cpr-- * invr;
							if (cur > max) cur = max;
							
							*dst++ = velo * cur;
						}
					}
					else if (pos < ca) // attacking
					{
						float inva = 1.f / ca;
						int cpa = pos;
						
						for (k = 0; k < copycount && cpa < ca; k++)
							*dst++ = velo * cpa++ * inva;
							
						for (; k < copycount; k++)
							*dst++ = velo;
					}
					else if (oend != kNeverEnd && (pos + count) > oend) // releasing
					{
						float invr = 1.f / cr;
						int cpr = oend + cr - pos;
						
						for (k = 0; k < copycount && cpr >= cr; k++, cpr--)
							*dst++ = velo;
							
						float max = (float)oend / (float)ca;
						if (max > 1.f) max = 1.f;	
						
						for (; k < copycount && cpr > 0; k++)
						{
							float cur = cpr-- * invr;
							if (cur > max) cur = max;
							
							*dst++ = velo * cur;
						}
					}
					else // normal case
					{
						for (k = 0; k < copycount; k++)
							*dst++ = velo;
					}
				}
				else // double precision
				{
					double velo = obj->mState->mVelo[i];
					double *dst = obj->mVeloBuffers[i].doubleData + offset + cstart;

					int k;
					if (pos < ca && oend != kNeverEnd && (pos + count) > oend) // attack _and_ release
					{
						double inva = 1. / ca;
						double invr = 1. / cr;
						int cpa = pos;
						int cpr = oend + cr - pos;
						
						for (k = 0; k < copycount && cpa < ca && cpr > cr; k++, cpr--)
							*dst++ = velo * cpa++ * inva;
							
						float max = oend * inva;
						if (max > 1.f) max = 1.f;	
						
						for (; k < copycount && cpr > 0; k++)
						{
							float cur = cpr-- * invr;
							if (cur > max) cur = max;
							
							*dst++ = velo * cur;
						}
					}
					else if (pos < ca) // attacking
					{
						double inva = 1. / ca;
						int cpa = pos;
						
						for (k = 0; k < copycount && cpa < ca; k++)
							*dst++ = velo * cpa++ * inva;
							
						for (; k < copycount; k++)
							*dst++ = velo;
					}
					else if (oend != kNeverEnd && (pos + count) > oend) // releasing
					{
						double invr = 1. / cr;
						int cpr = oend + cr - pos;
						
						for (k = 0; k < copycount && cpr >= cr; k++, cpr--)
							*dst++ = velo;
							
						double max = (double)oend / (double)ca;
						if (max > 1.) max = 1.;	
						
						for (; k < copycount && cpr > 0; k++)
						{
							double cur = cpr-- * invr;
							if (cur > max) cur = max;
							
							*dst++ = velo * cur;
						}
					}
					else // normal case
					{
						for (k = 0; k < copycount; k++)
							*dst++ = velo;
					}
				}

				// execute
				(c->pCalcFunc)(c, copycount, offset + cstart);
			
				// accumulate output
				if (precision == kFloatPrecision)
				{
					int j;
					for (j = 0; j < outputs; j++)
					{
						float *src = c->pOutputBuffers[j].floatData + offset + cstart;
						float *dst = obj->mAudioBuffers[j].floatData + offset + cstart;

						int k;
						for (k = 0; k < copycount; k++)
							*dst++ += *src++;
					}
				}
				else // double precision
				{
					int j;
					for (j = 0; j < outputs; j++)
					{
						double *src = c->pOutputBuffers[j].doubleData + offset + cstart;
						double *dst = obj->mAudioBuffers[j].doubleData + offset + cstart;

						int k;
						for (k = 0; k < copycount; k++)
							*dst++ += *src++;
					}
				}
			}
		}
	}
}

static void privateFinishFunc(void *inObj, int count, int offset)
{
	SBMidiMultiNote *obj = inObj;

	int	*note = obj->mState->mNote;
	int	*position = obj->mState->mPosition;
	int	*end = obj->mState->mEnd;
	int *useCount = obj->mState->mUseCount;
	int sr60 = obj->mSampleRate * 60;
	int i;
	
	for (i = 0; i < kMaxVoices; i++)
		if (note[i] != kNoteOff)
		{
			position[i] += count;
			if (position[i] > (end[i] + sr60) || useCount[i] <= 0)
				note[i] = kNoteOff;
		}
}

@implementation SBMidiMultiNote

+ (NSString*) name
{
	return @"Midi multi note";
}

- (NSString*) informations
{
	return	[NSString stringWithFormat:
			@"Duplicates the subcircuit on the fly for each pressed note, up to a maximum of %i. "
			@"The outputs of these subcircuits are summed, then outputed. "
			@"You can specify the attack and release time in milliseconds. "
			@"Both are clamped to 0 .. 60000 milliseconds. "
			@"You must stop/start for changes to take effect.", kMaxVoices];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBMidiMultiNote" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mInputTF setIntValue:mInputCount];
	[mOutputTF setIntValue:mOutputCount];
}

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		mInternalInputs = 2;
	
		pCalcFunc = privateCalcFunc;
		pFinishFunc = privateFinishFunc;
	
		mMainCircuit = [[SBCircuit alloc] init];
		if (!mMainCircuit)
		{
			[self release];
			return nil;
		}
		
		mShareCount = 1;
		mOwnState = YES;
		mState = malloc(sizeof(SBMidiMultiNoteState));
		if (!mState)
		{
			[self release];
			return nil;
		}
		memset(mState, 0, sizeof(SBMidiMultiNoteState));
		
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementWillChangeAudio:)
						name:kSBElementWillChangeAudioNotification
						object:mMainCircuit];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeAudio:)
						name:kSBElementDidChangeAudioNotification
						object:mMainCircuit];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeConnections:)
						name:kSBElementDidChangeConnectionsNotification
						object:mMainCircuit];

		[self updateSubCircuitsForInputs];

		[mName setString:@"midi multi note"];

	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	int i;
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		if (c) [c release];
	}
	
	if (mOwnState && mState)
	{
		for (i = 0; i < kMaxVoices; i++)			
			if (mState->mNoteBuffers[i].ptr) free(mState->mNoteBuffers[i].ptr);

		free(mState);
	}
	
	for (i = 0; i < kMaxVoices; i++)
		if (mVeloBuffers[i].ptr) free(mVeloBuffers[i].ptr);

	if (mMainCircuit) [mMainCircuit release];
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (void) controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if (tf == mInputTF)
	{
		mInputCount = [mInputTF intValue];
		[self updateSubCircuitsForInputs];
		[mInputTF setIntValue:mInputCount];
	}
	else if (tf == mOutputTF)
	{
		mOutputCount = [mOutputTF intValue];
		[self updateSubCircuitsForOutputs];
		[mOutputTF setIntValue:mOutputCount];
	}
}

- (void) updateSubCircuitsForInputs
{
	[self willChangeAudio];
	mLockIsHeld = YES;
	
	if (mInputCount < 0) mInputCount = 0;
	else if (mInputCount > kMaxChannels - 2) mInputCount = kMaxChannels - 2; // reserve 1 for note, 1 for vel

	[mMainCircuit setNumberOfInputs:mInputCount + 2];
	[mMainCircuit changeInputName:0 newName:@"note"];
	[mMainCircuit changeInputName:1 newName:@"velocity"];
	[self updateMirrors];
	
	[self didChangeConnections];
	
	mLockIsHeld = NO;
	[self didChangeAudio];
	
	[self didChangeGlobalView];
}

- (void) updateSubCircuitsForOutputs
{
	[self willChangeAudio];
	mLockIsHeld = YES;

	if (mOutputCount < 0) mOutputCount = 0;
	else if (mOutputCount > kMaxChannels) mOutputCount = kMaxChannels;
	
	[mMainCircuit setNumberOfOutputs:mOutputCount];
	// [self updateMirrors]; // done in self prepare
	
	// as we may have more output than before, we need to allocate them...
	[self prepareForSamplingRate:mSampleRate
			sampleCount:mSampleCount
			precision:mPrecision
			interpolation:mInterpolation];
			
	[self didChangeConnections];
	
	mLockIsHeld = NO;
	[self didChangeAudio];
	
	[self didChangeGlobalView];
}


- (SBCircuit*)subCircuit
{
	return mMainCircuit;
}

- (int) numberOfInputs
{
	return mInputCount + mInternalInputs;
}

- (NSString*) nameOfInputAtIndex:(int)idx
{
	if (idx == 0) return @"atck";
	else if (idx == 1) return @"rlse";
	else return [mMainCircuit nameOfInputAtIndex:idx - mInternalInputs + 2]; // 2 pour note/velo
}

- (int) numberOfOutputs
{
	return mOutputCount;
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	return [mMainCircuit nameOfOutputAtIndex:idx];
}

- (void) reset
{
	int i;

	if (mOwnState)
	{
		mState->mPitchBend = NO;
		mState->mPitchCoeff = 1.;
		for (i = 0; i < kMaxVoices; i++)
		{
			mState->mNote[i] = kNoteOff;
			mState->mUseCount[i] = 0;
		}
	}
	
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		if (c) [c reset];
	}
	
	// [super reset];
	// actually, we want to call SBElement reset, but SBSimpleArgument overrides it..
	// here's to copy/pasting SBElement original code, argh!
	if (mPrecision == kFloatPrecision)
	{
		for (i = 0; i < mAudioBuffersCount; i++)
			memset(mAudioBuffers[i].ptr, 0, mSampleCount * sizeof(float));
	}
	else
	{
		for (i = 0; i < mAudioBuffersCount; i++)
			memset(mAudioBuffers[i].ptr, 0, mSampleCount * sizeof(double));
	}
}

- (void) specificPrepare
{
	int i;
	if (mOwnState)
	{
		for (i = 0; i < kMaxVoices; i++)
			if (mState->mNoteBuffers[i].ptr) free(mState->mNoteBuffers[i].ptr);
		
		for (i = 0; i < kMaxVoices; i++)
		{
			mState->mNoteBuffers[i].ptr = malloc(mSampleCount * sizeof(double));
			assert(mState->mNoteBuffers[i].ptr);
		}
	}
	
	for (i = 0; i < kMaxVoices; i++)
		if (mVeloBuffers[i].ptr) free(mVeloBuffers[i].ptr);
	
	for (i = 0; i < kMaxVoices; i++)
	{
		mVeloBuffers[i].ptr = malloc(mSampleCount * sizeof(double));
		assert(mVeloBuffers[i].ptr);
	}
	
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		c->pInputBuffers[0] = mState->mNoteBuffers[i];
		c->pInputBuffers[1] = mVeloBuffers[i];
	}
}

- (void) prepareForSamplingRate:(int)samplingRate
			sampleCount:(int)sampleCount
			precision:(SBPrecision)precision
			interpolation:(SBInterpolation)interpolation
{

	if (mSettingsView)
		[self updateMirrors];

	[super prepareForSamplingRate:samplingRate
			sampleCount:sampleCount
			precision:precision
			interpolation:interpolation];

	int i;
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		[c prepareForSamplingRate:samplingRate
				sampleCount:sampleCount
				precision:precision
				interpolation:interpolation];
	}
}

- (void) changePrecision:(SBPrecision)precision
{
	[super changePrecision:precision];

	int i;
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		[c changePrecision:precision];
	}
}

- (void) changeInterpolation:(SBInterpolation)interpolation
{
	[super changeInterpolation:interpolation];
	
	int i;
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		[c changeInterpolation:interpolation];
	}
}

- (void) setMiniMode:(BOOL)mini
{
	[super setMiniMode:mini];
	
	[mMainCircuit setMiniMode:mini];
}

- (void) setLastCircuit:(BOOL)isLastCircuit
{
	[super setLastCircuit:isLastCircuit];
	
	int i;
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		[c setLastCircuit:isLastCircuit];
	}
}

- (BOOL) interpolates
{
	return [mMainCircuit interpolates];
}

- (BOOL) hasFeedback
{
	return [mMainCircuit hasFeedback];
}

- (void) trimDebug
{
	[mMainCircuit trimDebug];
}


- (void) updateMirrors
{
	int i;
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		if (c) [c release];
	}
	
	NSDictionary *d = [mMainCircuit saveData];
	
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = [[SBCircuit alloc] init];
		
		[c loadData:d];
		mCircuits[i] = c;
	}
	
	// let's prepare the subcircuits
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		[c prepareForSamplingRate:mSampleRate
				sampleCount:mSampleCount
				precision:mPrecision
				interpolation:mInterpolation];
		[c setLastCircuit:mLastCircuit];
	}
	
	// reset the inputs
	for (i = 0; i < kMaxVoices; i++)
	{
		SBCircuit *c = mCircuits[i];
		c->pInputBuffers[0] = mState->mNoteBuffers[i];
		c->pInputBuffers[1] = mVeloBuffers[i];
	}
}

- (void) subElementWillChangeAudio:(NSNotification *)notification
{
	if (!mLockIsHeld) [self willChangeAudio];
}

- (void) subElementDidChangeAudio:(NSNotification *)notification
{
	if (!mLockIsHeld)
	{
		//mLockIsHeld = YES;
		//[self updateMirrors];
		//mLockIsHeld = NO;
		[self didChangeAudio];
	}
}

- (void) subElementDidChangeConnections:(NSNotification *)notification
{
	if (mUpdatingTypes) return;
	mUpdatingTypes = YES;
	mLockIsHeld = YES;
	
	[mMainCircuit changeInputType:0 newType:kNormal];
	[mMainCircuit changeInputType:1 newType:kNormal];
	
	[self didChangeConnections];
	
	mLockIsHeld = NO;
	mUpdatingTypes = NO;
}

- (void) handleMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offset
{
	if (mChannel < 0)
		return;

	if (!mChannel || (mChannel - 1 == channel))
	{
		if (status == kMidiMessage_NoteOn && data2)
		{
			// find an empty spot
			int i;
			for (i = 0; i < kMaxVoices; i++)
			{
				if (mState->mNote[i] == kNoteOff)
				{
					mState->mStart[i] = offset;
					mState->mEnd[i] = kNeverEnd;
					mState->mUseCount[i] = mShareCount;

					// apply note
					double note = midiNoteToHertz(data1);
					double velo = data2 / 127.;
					
					if (mState->mPitchBend)
						note *= mState->mPitchCoeff;

					mState->mVelo[i] = velo;
					mState->mNoteHertz[i] = note;
					mState->mPosition[i] = 0;
					
					// activate it
					mState->mNote[i] = data1;
					
					break;
				}
			}
		}
		else if (status == kMidiMessage_NoteOff || (status == kMidiMessage_NoteOn && !data2))
		{
			// find which note to remove
			int i;
			for (i = 0; i < kMaxVoices; i++)
			{
				if (mState->mNote[i] == data1)
					mState->mEnd[i] = mState->mPosition[i] + offset;
			}

		}
		else if (status == kMidiMessage_PitchWheel)
		{
			// NSLog(@"kMidiMessage_PitchWheel data1: %i data2: %i", data1, data2);
			// at 0: data2 = 64
			// at high: data2 = 127
			// at low: data2 = 0
			
			if (data1 == 0 && data2 == 64)
			{
				if (mState->mPitchBend)
				{
					mState->mPitchBend = NO;
					
					// recalculate all buffer
					int i;
					for (i = 0; i < kMaxVoices; i++)
					{
						int playingNote = mState->mNote[i];
						if (playingNote != kNoteOff)
						{						
							// apply note
							double note = midiNoteToHertz(playingNote);
													
							mState->mNoteHertz[i] = note;
						}
					}
				}
			}
			else
			{
				mState->mPitchBend = YES;
				double val = ((data2 << 7) | data1) / 16383.; // middle is 8192./16383. (0.500030519)
				double left = 0.9438743127, right = 1.059463094, range = right - left;
				double coeff = left + val*range;
				mState->mPitchCoeff = coeff;
				
				// recalculate all buffer
				int i;
				for (i = 0; i < kMaxVoices; i++)
				{
					int playingNote = mState->mNote[i];
					if (playingNote != kNoteOff)
					{						
						// apply note
						double note = midiNoteToHertz(playingNote);
						note *= mState->mPitchCoeff;
						
						mState->mNoteHertz[i] = note;
					}
				}
			}
			
		}
	}
}

// load/save routines
- (NSMutableDictionary*) saveData
{
	NSNumber *n;
	NSDictionary *d;
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	d = [mMainCircuit saveData];
	if (!d) d = [NSDictionary dictionary];

	[md setObject:d forKey:@"circuit"];

	n = [NSNumber numberWithInt:mInputCount];
	[md setObject:n forKey:@"inputCount"];
		
	n = [NSNumber numberWithInt:mOutputCount];
	[md setObject:n forKey:@"outputCount"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	if (!data) return NO;

	NSNumber *n;
	
	n = [data objectForKey:@"inputCount"];
	if (n) mInputCount = [n intValue];
	
	n = [data objectForKey:@"outputCount"];
	if (n) mOutputCount = [n intValue];
	
	SBCircuit *c = [[SBCircuit alloc] init];
	if (c)
	{
		[c setNumberOfInputs:mInputCount + 2];
		[c setNumberOfOutputs:mOutputCount];
	
		[c loadData:[data objectForKey:@"circuit"]];
		
		if (mMainCircuit)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self
													name:nil
													object:mMainCircuit];
			[mMainCircuit release];
		}
		
		mMainCircuit = c;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementWillChangeAudio:)
						name:kSBElementWillChangeAudioNotification
						object:mMainCircuit];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeAudio:)
						name:kSBElementDidChangeAudioNotification
						object:mMainCircuit];
	}
	
	[self updateSubCircuitsForInputs];
	[self updateSubCircuitsForOutputs];
	
	return YES;
}

// disable any gui
- (void) drawContent
{
	if (mGuiMode != kCircuitDesign) return;
	[super drawContent];
}

- (BOOL) hitTestX:(int)x Y:(int)y
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super hitTestX:x Y:y];
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super mouseDownX:x Y:y clickCount:clickCount];
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super mouseDraggedX:x Y:y lastX:lx lastY:ly];
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super mouseUpX:x Y:y];
}

- (BOOL) keyDown:(unichar)ukey
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super keyDown:ukey];
}

// multi circuit management
- (BOOL) selfManagesSharingArgumentFrom:(SBArgument*)argument shareCount:(int)shareCount
{
	SBMidiMultiNote *mn = (SBMidiMultiNote*)argument;
	
	mState = mn->mState;
	mOwnState = NO;
	
	mn->mShareCount = mShareCount = shareCount;
	
	return YES;
}

- (BOOL) executeEvenIfShared
{
	return YES;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx < mInternalInputs) return kNormal;
	else return [mMainCircuit typeOfInputAtIndex:idx - mInternalInputs + 2]; // 2 pour note/velo
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	return [mMainCircuit typeOfOutputAtIndex:idx];
}


- (void) setColorsBack:(NSColor*)back contour:(NSColor*)contour front:(NSColor*)front
{
	[super	setColorsBack:back
			contour:contour
			front:front];
	
	[mMainCircuit	setColorsBack:back
					contour:contour
					front:front];
}


@end

