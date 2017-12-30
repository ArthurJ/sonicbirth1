/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBElement.h"

typedef enum
{
	kSilence = 0,
	kPlay,
	kRecord
} SBBufMode;

@interface SBBufferizer : SBElement
{
@public
	IBOutlet	NSTextField		*mTF;
	IBOutlet	NSView			*mSettingsView;
	
	double		mMaxRecordingTime;
	
	SBBufMode	mLastMode; // 0 silence, 1 play, 2 record
	double		mPlayPosition;
	int			mRecordPosition;
	
	SBBuffer	mBuffer;
	int			mBufferSize;
}

- (void) updateBufferSize:(int)sampleRate;
- (void) resetBuffer;

@end
