/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

#define kMaxSubCircuits (100)

@class SBCircuit;

@interface SBPiecewiseCircuit : SBElement
{
@public
	NSMutableArray *mSubCircuits;
	NSMutableArray *mRanges;
	int	mInputCount, mOutputCount;
	
	// caches
	int			mCachedSubCircuitsCount;
	SBCircuit	*mCachedSubCircuits[kMaxSubCircuits];
	
	int			mCachedRangesCount;
	double		mCachedRanges[kMaxSubCircuits];
	
	IBOutlet NSView			*mSettingsView;
	
	IBOutlet NSTextField	*mInputTF;
	IBOutlet NSTextField	*mOutputTF;
	
	IBOutlet NSTableView	*mRangesTableView;
	IBOutlet NSButton		*mRangeDelete;
	
	BOOL		mLockIsHeld;
	BOOL		mUpdatingNames;
	BOOL		mUpdatingTypes;
}

- (IBAction) createRange:(id)sender;
- (IBAction) deleteRange:(id)sender;

- (void) sortRanges;
- (void) updateSubCircuitsForInputs;
- (void) updateSubCircuitsForOutputs;

- (void) subElementWillChangeAudio:(NSNotification *)notification;
- (void) subElementDidChangeAudio:(NSNotification *)notification;
- (void) subElementDidChangeConnections:(NSNotification *)notification;
- (void) subElementDidChangeName:(NSNotification *)notification;
@end

