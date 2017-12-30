/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMidiArgument.h"

#define kMaxVoices (16)

@class SBCircuit;

typedef struct
{
	int			mUseCount[kMaxVoices];

	int			mNote[kMaxVoices];
	
	double		mNoteHertz[kMaxVoices];
	SBBuffer	mNoteBuffers[kMaxVoices];
	
	double		mVelo[kMaxVoices];

	int			mPosition[kMaxVoices];
	int			mStart[kMaxVoices]; // in absolute offset
	int			mEnd[kMaxVoices]; // in absolute offset
	
	
	BOOL		mPitchBend;
	double		mPitchCoeff;
} SBMidiMultiNoteState;

@interface SBMidiMultiNote : SBMidiArgument
{
@public
	IBOutlet NSView			*mSettingsView;
	IBOutlet NSTextField	*mInputTF;
	IBOutlet NSTextField	*mOutputTF;
	
	int	mInputCount, mOutputCount;
	
	SBCircuit	*mMainCircuit;
	SBCircuit	*mCircuits[kMaxVoices];
	int			mAttack[kMaxVoices];
	int			mRelease[kMaxVoices];
	
	SBBuffer	mVeloBuffers[kMaxVoices];
	
	SBMidiMultiNoteState *mState;
	BOOL		mOwnState;
	int			mShareCount;
	
	BOOL		mLockIsHeld;
	
	int			mInternalInputs;
	BOOL		mUpdatingTypes;
}

- (void) updateMirrors;
- (void) updateSubCircuitsForInputs;
- (void) updateSubCircuitsForOutputs;

- (void) subElementWillChangeAudio:(NSNotification *)notification;
- (void) subElementDidChangeAudio:(NSNotification *)notification;
- (void) subElementDidChangeConnections:(NSNotification *)notification;
@end
