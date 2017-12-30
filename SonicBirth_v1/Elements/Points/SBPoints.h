/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBArgument.h"

@interface SBPoints : SBArgument
{
	SBPointsBuffer mPointsBuffer;
	
	SBBuffer	mBuffer;
	
	NSSize		mViewSize;
	
	NSMutableString *mName;
	
	IBOutlet	NSView			*mSettingsView;
	IBOutlet	NSTextField		*mWidthTF;
	IBOutlet	NSTextField		*mHeightTF;
	IBOutlet	NSTextField		*mNameTF;
}

@end
