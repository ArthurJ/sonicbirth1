/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBArgument.h"

extern NSString *kSBRootCircuitPrecisionChangeNotification;

@interface SBRootCircuitPrecision : SBArgument
{
	int mCurMode; // 0 = 32 bits, 1 = 64 bits
	
	IBOutlet NSView			*mSettingsView;
	IBOutlet NSMatrix		*mPrecisionMatrix;
}

- (void) changedPrecision:(id)sender;

@end
