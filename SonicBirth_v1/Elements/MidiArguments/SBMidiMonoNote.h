/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/#import "SBMidiArgument.h"

#define kMaxNotes (128)

@interface SBMidiMonoNote : SBMidiArgument
{
	IBOutlet NSView			*mSettingsView;
	IBOutlet NSTextField	*mDefaultNoteTF;
	IBOutlet NSTextField	*mDefaultVelocityTF;
	
	IBOutlet NSButton		*mHoldNoteBt;
	
	BOOL	mHoldNote;
	double	mDefaultNote;
	double	mDefaultVelocity;
	
	BOOL mPitchBend;
	double mCurNote;
	double mPitchCoeff;
	int mStackCount;
	int mNoteStack[kMaxNotes];
	int mVelocityStack[kMaxNotes];
}

- (void) holdNote:(id)sender;

@end
