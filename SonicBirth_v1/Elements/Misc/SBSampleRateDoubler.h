/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/#import "SBElement.h"

@class SBCircuit;

@interface SBSampleRateDoubler : SBElement
{
@public
	SBCircuit	*mCircuit;

	int				mInputAudioBuffersCount;
	SBBuffer		mInputAudioBuffers[kMaxChannels];
	
	int				mLastPos;
	
	BOOL			mLockIsHeld;
	
	IBOutlet NSView			*mSettingsView;
	
	IBOutlet NSTextField	*mInputTF;
	IBOutlet NSTextField	*mOutputTF;
}

- (void) redoInputs;

@end
