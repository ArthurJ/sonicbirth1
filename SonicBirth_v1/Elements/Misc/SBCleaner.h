/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"


@interface SBCleaner : SBElement
{
@public
	IBOutlet NSButton		*mClampButton;
	IBOutlet NSView			*mSettingsView;

	BOOL mClamp;
}

- (void) changedClamp:(id)sender;

@end
