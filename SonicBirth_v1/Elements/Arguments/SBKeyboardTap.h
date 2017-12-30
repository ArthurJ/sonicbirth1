/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSimpleArgument.h"

@interface SBKeyboardTap : SBSimpleArgument
{
@public
	IBOutlet NSView			*mSettingsView;
	IBOutlet NSTextField	*mCellRadiusTF;
	
	BOOL					mTapped;
	float					mCellRadius;
}

@end
