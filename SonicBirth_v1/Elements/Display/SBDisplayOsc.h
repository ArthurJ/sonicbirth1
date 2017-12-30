/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBArgument.h"

@interface SBDisplayOsc : SBArgument
{
	IBOutlet NSTextField	*mBottomTF;
	IBOutlet NSTextField	*mTopTF;
	IBOutlet NSTextField	*mWidthTF;
	IBOutlet NSTextField	*mHeightTF;
	IBOutlet NSTextField	*mResolutionTF;
	IBOutlet NSSlider		*mResolutionSlider;
	IBOutlet NSView			*mSettingsView;
	IBOutlet NSButton		*mFreezeWhenFullBt;
	
	int						mWidth;
	int						mHeight;
	double					mMs;
	double					mBottom;
	double					mTop;
	
	BOOL					mFreezeWhenFull;
	
	NSMutableString			*mName;
	IBOutlet NSTextField	*mNameTF;
}

- (void) updateCell;
- (void) changedResolution:(id)sender;
- (void) changedFreezeWhenFull:(id)sender;

@end

@interface SBDisplayOscVarRes : SBDisplayOsc
{}
@end