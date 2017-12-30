/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCell.h"

@interface SBPointsCell : SBCell
{
	NSSize			mSize;
	SBPointsBuffer	*mPointsBuffer;
	//NSBezierPath	*mBezierPath;
	BOOL			mUptodate;
	int				mSelectedPoint; // -1 means none
	
	BOOL			mMouseLock;
}

- (void) setPointsBuffer:(SBPointsBuffer*)pointsBuffer;

- (void) setContentSize:(NSSize)size;

- (void) update;

- (void) drawFunctionAtPoint:(NSPoint)origin;

@end
