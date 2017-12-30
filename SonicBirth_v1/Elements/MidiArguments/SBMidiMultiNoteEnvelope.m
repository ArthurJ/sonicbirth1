/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBMidiMultiNoteEnvelope.h"
#import "SBPointCalculation.h"
#import "SBCircuit.h"

#define kNoteOff (-1)
#define kNeverEnd (-1)

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBMidiMultiNoteEnvelope *obj = inObj;

	int	*note = obj->mState->mNote;
	int	*position = obj->mState->mPosition;
	int	*start = obj->mState->mStart;
	int	*end = obj->mState->mEnd;
	int *useCount = obj->mState->mUseCount;
	double *noteHertz = obj->mState->mNoteHertz;
	SBBuffer *noteBuffers = obj->mState->mNoteBuffers;
	int internalInputs = obj->mInternalInputs;
	
	SBPointsBuffer pts = *(obj->pInputBuffers[3].pointsData);
	
	int	*attack = obj->mAttack;
	int *loop = obj->mLoop;
	int	*release = obj->mRelease;
	char *region = obj->mRegion;
	
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
	int cattack, cloop, crelease;
	if (obj->mPrecision == kFloatPrecision)
	{
		cattack = obj->pInputBuffers[0].floatData[offset] * 0.001f * sr;
		cloop = obj->pInputBuffers[1].floatData[offset] * 0.001f * sr;
		crelease = obj->pInputBuffers[2].floatData[offset] * 0.001f * sr;
	}
	else
	{
		cattack = obj->pInputBuffers[0].doubleData[offset] * 0.001 * sr;
		cloop = obj->pInputBuffers[1].doubleData[offset] * 0.001f * sr;
		crelease = obj->pInputBuffers[2].doubleData[offset] * 0.001 * sr;
	}
	
	if (cattack < 1) cattack = 1;
	else if (cattack > sr60) cattack = sr60;
	
	if (cloop < 0) cloop = 0;
	else if (cloop > sr60) cloop = sr60;
	
	if (crelease < 1) crelease = 1;
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
				loop[i] = cloop;
				release[i] = crelease;
				region[i] = 0;
			}
			
			int cr = release[i];
			int cl = loop[i];
			int ca = attack[i];
			int reg = region[i];
			
			if (reg >= 3) continue; // already completed

			int cstart = start[i] - pos;
			if (cstart < 0) cstart = 0;
			
			int oend = end[i];
			if (reg == 2 && oend == kNeverEnd) oend = ca;
			else if (oend != kNeverEnd && oend < ca) oend = ca;
			
			int looprelease = 0;
			if (oend != kNeverEnd && oend > ca)
			{
				if (reg < 2 && cl> 0)
					looprelease = cl - ((oend - ca) % cl);
				else
					looprelease = cl;
			}
			
			int cend = (oend - pos) + cr + looprelease;
			if (oend == kNeverEnd || cend > count) 
				cend = count;

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

					int k = copycount;

					// attack
					if (reg == 0)
					{
						float inva = 1.f / (3*ca);
						while(k > 0 && pos < ca)
						{
							*dst++ = pos++ * inva;
							k--;
						}
						
						if (pos >= ca) reg++;
					}
					
					// no loop
					if (reg == 1 && cl == 0)
						reg++;
					
					// loop
					if (reg == 1)
					{
						float invl = 1.f / (3*cl);
						int cpl = (pos - ca) % cl;
						if (oend == kNeverEnd)
						{
							while(k > 0)
							{
								*dst++ = cpl++ * invl + (1.f/3.f); 
								if (cpl >= cl) cpl = 0;
								k--;
							}
						}
						else
						{
							oend += looprelease;
							while(k > 0 && pos < oend)
							{
								*dst++ = cpl++ * invl + (1.f/3.f); 
								if (cpl >= cl) cpl = 0;
								pos++;
								k--;
							}
							
							if (pos >= oend)
							{
								reg++;
								loop[i] = looprelease;
								cl = 0;
							}
						}
					}
					
					if (reg == 2)
					{
						float invr = 1.f / (3*cr);
						oend += cl;
						int cpr = pos - oend;
						oend += cr;
						while(k > 0 && pos++ < oend)
						{
							*dst++ = cpr++ * invr + (2.f/3.f);
							k--;
						}
					
						while(k-- > 0)
							*dst++ = 1.f;
							
						if (pos >= oend)
						{
							reg++;
							useCount[i]--;
						}
					}
					
					region[i] = reg;
					
					int save = 0;
					dst = obj->mVeloBuffers[i].floatData + offset + cstart;
					k = copycount;
					while(k-- > 0)
					{
						*dst = pointCalculate(&pts, *dst, &save) * velo;
						dst++;
					}
				}
				else // double precision
				{
					double velo = obj->mState->mVelo[i];
					double *dst = obj->mVeloBuffers[i].doubleData + offset + cstart;

					int k = copycount;

					// attack
					if (reg == 0)
					{
						double inva = 1. / (3*ca);
						while(k > 0 && pos < ca)
						{
							*dst++ = pos++ * inva;
							k--;
						}
						
						if (pos >= ca) reg++;
					}
					
					// no loop
					if (reg == 1 && cl == 0)
						reg++;
					
					// loop
					if (reg == 1)
					{
						double invl = 1. / (3*cl);
						int cpl = (pos - ca) % cl;
						if (oend == kNeverEnd)
						{
							while(k > 0)
							{
								*dst++ = cpl++ * invl + (1./3.); 
								if (cpl >= cl) cpl = 0;
								k--;
							}
						}
						else
						{
							oend += looprelease;
							while(k > 0 && pos < oend)
							{
								*dst++ = cpl++ * invl + (1./3.); 
								if (cpl >= cl) cpl = 0;
								pos++;
								k--;
							}
							
							if (pos >= oend)
							{
								reg++;
								loop[i] = looprelease;
								cl = 0;
							}
						}
					}
					
					if (reg == 2)
					{
						double invr = 1. / (3*cr);
						oend += cl;
						int cpr = pos - oend;
						oend += cr;
						while(k > 0 && pos++ < oend)
						{
							*dst++ = cpr++ * invr + (2./3.);
							k--;
						}
					
						while(k-- > 0)
							*dst++ = 1.;
							
						if (pos >= oend)
						{
							reg++;
							useCount[i]--;
						}
					}
					
					region[i] = reg;
					
					int save = 0;
					dst = obj->mVeloBuffers[i].doubleData + offset + cstart;
					k = copycount;
					while(k-- > 0)
					{
						*dst = pointCalculate(&pts, *dst, &save) * velo;
						dst++;
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

@implementation SBMidiMultiNoteEnvelope

+ (NSString*) name
{
	return @"Midi multi note envelope";
}

- (NSString*) informations
{
	return	[NSString stringWithFormat:
			@"Duplicates the subcircuit on the fly for each pressed note, up to a maximum of %i. "
			@"The outputs of these subcircuits are summed, then outputed. "
			@"You can specify the attack, loop and release time in milliseconds. "
			@"All are clamped to 0 .. 60000 milliseconds. "
			@"You must stop/start for changes to take effect.", kMaxVoices];
}

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		mInternalInputs = 4;
	
		pCalcFunc = privateCalcFunc;

		[mName setString:@"midi multi note env"];

	}
	return self;
}

- (NSString*) nameOfInputAtIndex:(int)idx
{
	if (idx == 0) return @"atck";
	else if (idx == 1) return @"loop";
	else if (idx == 2) return @"rlse";
	else if (idx == 3) return @"pts";
	else return [mMainCircuit nameOfInputAtIndex:idx - mInternalInputs + 2];
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx == 3) return kPoints;
	else return [super typeOfInputAtIndex:idx];
}

@end
