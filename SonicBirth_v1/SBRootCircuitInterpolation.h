/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBArgument.h"

extern NSString *kSBRootCircuitInterpolationChangeNotification;

@interface SBRootCircuitInterpolation : SBArgument
{
	int mCurMode; // 0 = no inter, 1 = lin inter
	
	IBOutlet NSView			*mSettingsView;
	IBOutlet NSMatrix		*mInterpolationMatrix;
}

- (void) changedInterpolation:(id)sender;

@end
