/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBSimpleArgument.h"

@interface SBGraphicObject : SBSimpleArgument
{
	IBOutlet NSView			*mSettingsView;

	NSImage *mGOImage;
	IBOutlet NSImageView *mGOImageView;
}

- (IBAction) changedImage:(id)sender;

@end
