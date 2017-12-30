/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

@interface SBDelay : SBElement
{
@public
	IBOutlet	NSTextField		*mTF;
	IBOutlet	NSView			*mSettingsView;
	
	double		mValue;
	int			mCurSample;
	SBBuffer	mBuffer;
	int			mBufferSize;
}

- (void) updateBufferSize:(int)sampleRate;
- (void) resetBuffer;
@end
