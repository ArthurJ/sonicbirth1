/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBArgument.h"

@interface SBDisplayMeter : SBArgument
{
	IBOutlet NSView			*mSettingsView;

	IBOutlet NSTextField	*mWidthTF;
	IBOutlet NSTextField	*mHeightTF;
	IBOutlet NSTextField	*mMinTF;
	IBOutlet NSTextField	*mMaxTF;
	IBOutlet NSButton		*mInversedBt;
	IBOutlet NSPopUpButton	*mTypePU;
	
	int mWidth;
	int mHeight;
	int mType;		// 0 vertical, 1 horizontal
	BOOL mInversed;
	double mMin;
	double mMax;
	
	NSMutableString			*mName;
	IBOutlet NSTextField	*mNameTF;
}

- (void) updateCell;
- (void) changedInversed:(id)sender;
- (void) changedType:(id)sender;

@end
