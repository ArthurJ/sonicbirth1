/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

@interface SBWire : NSObject
{
	// for wire creation, used when drawing
	// if mInputElement == nil
	float mInputX, mInputY;
	
	// if mOutputElement == nil
	float mOutputX, mOutputY;
	
	// gui anchors
	NSMutableArray  *mAnchors;

	// wire ends
	SBElement   *mOutputElement;
	int			mOutputIndex;
	
	SBElement   *mInputElement;
	int			mInputIndex;
}

- (BOOL) isConnectedToElement:(SBElement*)element;

- (SBElement*) inputElement;
- (SBElement*) outputElement;

- (void) setInputElement:(SBElement*)e;
- (void) setOutputElement:(SBElement*)e;

- (int) inputIndex;
- (int) outputIndex;

- (void) setInputIndex:(int)idx;
- (void) setOutputIndex:(int)idx;

- (void) setOutputX:(float)x Y:(float)y;
- (void) setInputX:(float)x Y:(float)y;

- (void) drawRect:(NSRect)rect;

- (NSMutableDictionary*) saveData;
- (BOOL) loadData:(NSDictionary*)data;

// gui stuff
- (BOOL) hitTestX:(int)x Y:(int)y pt:(NSPoint)a;
- (BOOL) hitTestX:(int)x Y:(int)y pt:(NSPoint)a pt:(NSPoint)b;
- (BOOL) hitTestX:(int)x Y:(int)y;
- (SBPoint*) anchorForX:(int)x Y:(int)y;
- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount;
- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly;

- (void) translateDeltaX:(int)x deltaY:(int)y;

@end
