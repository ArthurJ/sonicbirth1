/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBElement.h"

@interface SBLookAhead : SBElement
{
@public
	IBOutlet	NSTextField		*mTF;
	IBOutlet	NSView			*mSettingsView;
	
	double		mDelay;

	int			mCurSample;
	int			mEnvPos;
	
	SBBuffer	mDelayBuffer;
	SBBuffer	mAbsBuffer;
	int			mBuffersSize;
}

- (void) updateBufferSize:(int)sampleRate;
- (void) resetBuffer;

@end
