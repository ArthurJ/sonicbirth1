/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMidiArgument.h"

#define kNoteCount (128)

@interface SBMidiNoteState : SBMidiArgument
{
	int						mNoteActiveCount;
	int						mIndexToNote[kNoteCount];
	int						mNoteToIndex[kNoteCount];
	
	BOOL					mNoteActive[kNoteCount];
	double					mNoteOnValue[kNoteCount];
	double					mNoteOffValue[kNoteCount];

	IBOutlet NSView			*mSettingsView;
	IBOutlet NSTableView	*mNoteTableView;
	IBOutlet NSButton		*mNoteDelete;
}

- (IBAction) addNote:(id)sender;
- (IBAction) removeNote:(id)sender;

- (void) update;

@end
