/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBElement.h"

@interface SBConstant : SBElement
{
@public
	IBOutlet NSTextField	*mValueEdit, *mValueShow;
	IBOutlet NSView			*mSettingsView;
	
	double	mValue;
	BOOL	mUpdateBuffer;
}

- (void) setValue:(double)value; // overriden by some subclasses (SBSlow) - do not remove!
- (double) defaultValue; // overriden by subclasses

@end
