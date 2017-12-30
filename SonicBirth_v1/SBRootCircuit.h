/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCircuit.h"

#include <pthread.h>

@class SBRootCircuitInterpolation;
@class SBRootCircuitPrecision;
@class SBRootCircuitMidi;

@interface SBRootCircuit : SBCircuit
{
	NSMutableArray  *mPresetArray;

	NSMutableString *mAuthor;
	NSMutableString *mCompany;
	NSMutableString *mPluginDescription;
	
	double			mLatency;
	double			mLatencySamples;
	double			mTailTime;
	
	char			mSubType[4];
	
	BOOL			mHasCustomGui;
	
	NSSize			mGuiSize;
	
	NSData			*mBgImageData;
	ogImage			*mBgImage;
	
	BOOL			mNeedsTempo;
	BOOL			mHasSideChain;
	BOOL			mCanChangeHasSideChain;
	
	IBOutlet NSButton		*mLoadBgImage;
	IBOutlet NSButton		*mClearBgImage;
	IBOutlet NSButton		*mTakeBgImageSize;
	
	IBOutlet NSButton		*mHasCustomGuiBt;
	IBOutlet NSMatrix		*mGuiModeBt;
	
	IBOutlet NSTextField	*mAuthorTF;
	IBOutlet NSTextField	*mCompanyTF;
	IBOutlet NSTextField	*mPluginDescriptionTF;
	IBOutlet NSTextField	*mLatencyTF;
	IBOutlet NSTextField	*mTailTimeTF;
	IBOutlet NSTextField	*mSubTypeTF;
	
	IBOutlet NSTextField	*mGuiWidthTF;
	IBOutlet NSTextField	*mGuiHeightTF;
	
	IBOutlet NSTableView	*mArgumentTableView;
	IBOutlet NSButton		*mArgumentMoveUp;
	IBOutlet NSButton		*mArgumentMoveDown;
	
	IBOutlet NSTableView	*mPresetTableView;
	IBOutlet NSButton		*mPresetSet;
	IBOutlet NSButton		*mPresetDelete;
	IBOutlet NSButton		*mPresetMoveUp;
	IBOutlet NSButton		*mPresetMoveDown;
	
	IBOutlet NSColorWell	*mColorWellBack;
	IBOutlet NSColorWell	*mColorWellContour;
	IBOutlet NSColorWell	*mColorWellFront;
	
	IBOutlet NSScrollView	*mMainScrollView;
	
	IBOutlet NSButton		*mSideChainButton;
	IBOutlet NSButton		*mTempoButton;
	IBOutlet NSTextField	*mLatencySamplesTF;
	
@public
	SBPrecision				pPrecision;
	pthread_mutex_t			pMutex;
}



- (int) numberOfRealInputs;
- (BOOL) hasSideChain;
- (BOOL) needsTempo;
- (void) changedHasSideChain:(id)sender;
- (void) changedNeedsTempo:(id)sender;
- (void) setHasSideChain:(BOOL)has;
- (void) setCanChangeHasSideChain:(BOOL)canChange;

- (NSString*) company;
- (void) setCompany:(NSString*)company;

- (NSString*) pluginDescription;
- (void) setPluginDescription:(NSString*)pluginDescription;

- (void) loadBgImage:(id)sender;
- (void) clearBgImage:(id)sender;
- (void) takeBgImageSize:(id)sender;

- (BOOL) minSizeIsMaxSize;

- (BOOL) hasCustomGui;
- (void) changedHasCustomGui:(id)sender;
- (void) changedGuiMode:(id)sender;

- (NSString*) author;
- (void) setAuthor:(NSString*)author;

- (double) latency;
- (double) latencyMs;
- (double) latencySamples;
- (double) tailTime;
- (char*) subType;

- (void) setLatency:(double)latency;
- (void) setLatencySamples:(double)latencySamples;
- (void) setTailTime:(double)tailTime;
- (void) setSubType:(const char *)subType;

- (NSData*) currentState;
- (void) loadState:(NSData*)state;

- (void) createPreset;
- (void) setPreset:(int)idx;
- (void) deletePreset:(int)idx;
- (void) moveUpPreset:(int)idx;
- (void) moveDownPreset:(int)idx;

- (int) numberOfPresets;
- (SBPreset*) presetAtIndex:(int)idx;

- (void) moveUpArgument:(int)idx;
- (void) moveDownArgument:(int)idx;

- (void) moveUpArgumentBt:(id)sender;
- (void) moveDownArgumentBt:(id)sender;

- (void) setPresetBt:(id)sender;
- (void) createPresetBt:(id)sender;
- (void) deletePresetBt:(id)sender;
- (void) moveUpPresetBt:(id)sender;
- (void) moveDownPresetBt:(id)sender;

- (SBPrecision) precision;
- (SBInterpolation) interpolation;

- (SBRootCircuitInterpolation*) rciElement;
- (SBRootCircuitPrecision*) rcpElement;
- (SBRootCircuitMidi*) rcmElement;

- (void) changedColor:(id)sender;

- (void)updateGUIModeMatrixFromInternalState;

@end
