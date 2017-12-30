/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMidiMultiNote.h"

@interface SBMidiMultiNoteEnvelope : SBMidiMultiNote
{
@public
	int			mLoop[kMaxVoices];
	char		mRegion[kMaxVoices];
}

@end
