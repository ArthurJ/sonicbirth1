/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBElement.h"

@interface SBFFTSync : SBElement
{
@public
	IBOutlet	NSPopUpButton   *mFFTBlockSizePopUp;
	IBOutlet	NSView			*mSettingsView;
	
	int				mFFTBlockSize;
	int				mDataPos;

	SBBuffer		mFFTSyncBuffer;
	SBFFTSyncData   mFFTSync;
}

- (void) FFTBlockSizeChanged:(id)sender;

@end
