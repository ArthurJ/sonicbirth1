/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"
#import <AudioUnit/AudioUnit.h>
#import "SBAudioUnitEditor.h"
#import "SBArgument.h"

@interface SBAudioUnit : SBArgument
{
@public
	IBOutlet	NSView			*mSettingsView;
	IBOutlet	NSPopUpButton	*mAudioUnitListPopUp;
	IBOutlet	NSPopUpButton	*mAudioUnitChannelConfigPopUp;
	IBOutlet	NSTableView		*mParameterTable;
	
	SBAudioUnitEditor *mAuGui;

	AudioUnit	mAudioUnit;
	OSType		mType, mSubType, mManufacturer;
	int			mInputCount, mOutputCount;
	
	NSMutableArray *mAudioUnitList;
	NSMutableArray *mAudioUnitChannelConfig;
	
	int mParameterCount;
	AudioUnitParameterID *mParameterList; // 

	int mParameterExportedCount;
	AudioUnitParameterID *mParameterExportedList;
	float	*mParameterExportedMins;
	float	*mParameterExportedMaxs;
	float	*mParameterExportedLastValue;
	
	NSMutableString *mIntName;
	
	AudioTimeStamp mTimeStamp;
	
	int	mCycleOffset;
	int mCycleCount;
	int mMaxPerCycle;
	
	double mTempo, mBeat;
}

- (void) showAuGui:(id)sender;
- (void) chooseAudioUnit:(id)sender;
- (void) chooseChannelConfig:(id)sender;
- (void) ui_listAllAUs;
- (void) ui_updateChannelConfig;

- (void) openAudioUnitType:(OSType)type subType:(OSType)subType manuf:(OSType)manuf;
- (BOOL) setChannelConfigInputs:(int)inputs outputs:(int)outputs;
- (void) setUpParameterList;

- (void) reorderExportedList;

@end
