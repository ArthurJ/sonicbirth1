/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBSimpleArgument.h"

@interface SBVisibleComment : SBSimpleArgument
{
	NSMutableString *mText;

	IBOutlet	NSView			*mSettingsView;
	IBOutlet	NSTextField		*mTextTF;
}

@end
