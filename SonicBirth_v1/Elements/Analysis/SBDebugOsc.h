/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

@interface SBDebugOsc : SBElement
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
}

- (void) updateCell;
- (void) changedResolution:(id)sender;
- (void) changedFreezeWhenFull:(id)sender;

@end
