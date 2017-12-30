/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBRootCircuit.h"
#import "SBCircuitView.h"

@interface SBCircuitDocument : NSDocument
{
	IBOutlet SBCircuitView *mCircuitView;
	SBRootCircuit *mCircuit;
	
	BOOL mWriteSuccess;
	
	NSData *mUndoData;
}

- (SBRootCircuit*) circuit;
- (SBCircuitView*) circuitView;
- (void) undoMark;
- (void) snapShot;
- (void) snapShotMark;
@end
