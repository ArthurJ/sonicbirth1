/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBElement.h"

@interface SBEquation : SBElement
{
@public
	IBOutlet NSView			*mSettingsView;
	IBOutlet NSTextField	*mInputsTF;
	IBOutlet NSTextField	*mEquationTF;
	IBOutlet NSTextView		*mExecutePlan;

	int						mInputs;
	NSMutableString			*mEquation;

	void					*mEquationState;
	
	SBBuffer				*mBuffers; // last one is our output buffer
	int						mBuffersCount;
	int						mBuffersSize;
	
	BOOL					mUpdateBuffer;
}

- (void) fixCell;
- (void) compileEquation;
- (void) setNumberOfInputs:(int)c;

@end
