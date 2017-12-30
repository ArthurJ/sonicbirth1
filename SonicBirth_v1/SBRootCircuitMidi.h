/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBArgument.h"


@class SBRootCircuit;
@class SBMidiArgument;

@interface SBRootCircuitMidi : SBArgument
{
	SBRootCircuit	*mParent;
	SBMidiArgument	*mCurrentMidiArgument;
	NSMutableArray	*mItemNames;
	
	int mCurrentMidiArgumentIndex;
	int mCurrentChannel;
	int mCurrentController;
}

- (void) setParent:(SBRootCircuit*)parent;
- (void) updateItems;
- (void) updatedController:(SBMidiArgument*)arg;

@end
