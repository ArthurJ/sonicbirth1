/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"


@interface SBSelectionList : NSObject
{
	NSMutableArray *mList;
	
	NSArray *mWireArray; // owned by parent
}

- (void) addElement:(SBElement*)e;
- (void) toggleElement:(SBElement*)e;
- (void) setElement:(SBElement*)e;
- (void) removeElement:(SBElement*)e;
- (void) removeAllElements;

- (SBElement*) element;
- (NSArray*) elements;

- (int) count;

- (void) translateElementsDeltaX:(int)x deltaY:(int)y content:(BOOL)content;
- (BOOL) hitTestX:(int)x Y:(int)y;

- (BOOL) isSelected:(SBElement*)e;

- (void) setWireArray:(NSArray*)wa;
- (NSArray*) selectedWires;

@end
