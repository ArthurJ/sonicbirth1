/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBArgument.h"

@interface SBAudioFileArgument : SBArgument
{
	int		mNumberOfSamples;
	int		mChannelCount;
	float   *mBuffers[kMaxChannels];
	
	SBAudioBuffer mAB[kMaxChannels];
	
	NSMutableString *mName;
	int mPresetChannelCount;
	
	NSString	*mFileName;
	
	IBOutlet	NSView			*mSettingsView;
	IBOutlet	NSTextField		*mNameTF;
	IBOutlet	NSTextField		*mPresetChannelCountTF;
}

- (void) loadAudioFile:(NSString*)path;
- (NSString*) findAudioFile;

@end
