/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAudioProcess.h"
#import <MTCoreAudio/MTCoreAudio.h>

@interface SBSoundServer : NSObject
{
	IBOutlet NSPanel		*mSoundPanel;
	IBOutlet NSSlider		*mPlaybackPos;
	
	IBOutlet NSButton		*mPlayButton;
	IBOutlet NSButton		*mLoopButton;
	IBOutlet NSButton		*mOpenButton;
	
	IBOutlet NSTextField	*mFilePath;
	IBOutlet NSTextField	*mFileInfo;
	IBOutlet NSTextField	*mDeviceInfo;
	
	IBOutlet NSTextField	*mTempoTF;
	IBOutlet NSTextField	*mCpuUsageTF;
	
	int		mCpuUsageDisplayDelay;
	double	mCpuUsage;
	double	mInverseHostTicksPerBuffer;
	
	BOOL					mLoops;
	BOOL					mIsPlaying;
	MTCoreAudioDevice		*mDevice;
	long long				mCurSample;
	
	int						mCalculatingOffset;
	int						mMinFeedbackTime;
	
	int						mSampleRate;
	int						mFramePerBuffer;
	int						mDeviceChannels;
	
	double					mTempo;
	
	// lock
	NSLock					*mLock;
	
	// silence and scratch buffers
	SBBuffer				mSilence;
	SBBuffer				mTempoBuf, mBeatBuf;
	SBBuffer				mTempBuffers[kMaxChannels];
	
	// sound file
	int						mBufferCount;
	long long				mSampleCount;
	float					*mBuffers[kMaxChannels];
	
	// cur effect
	SBAudioProcess			*mAudioProcess;
	
	// all elements speed test
	IBOutlet NSWindow		*mSpeedResultsWindow;
	IBOutlet NSTextView		*mSpeedResultsText;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification;

- (IBAction) showPanel:(id)server;
- (IBAction) changedPlaybackPos:(id)sender;

- (IBAction) pushedPlayButton:(id)sender;
- (IBAction) pushedLoopButton:(id)sender;
- (IBAction) pushedOpenButton:(id)sender;

- (SBAudioProcess*) currentAudioProcess;
- (void) stop;

- (IBAction) doSpeedTest:(id)sender;
- (IBAction) doSpeedTestAllElements:(id)sender;
- (void) speedTestAllElements;
@end

extern SBSoundServer *gSoundServer;

