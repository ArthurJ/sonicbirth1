/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBArgument.h"

@interface SBDisplayValue : SBArgument
{
	NSMutableString			*mName;
	IBOutlet NSTextField	*mNameTF;
	IBOutlet NSView			*mSettingsView;
}

@end
