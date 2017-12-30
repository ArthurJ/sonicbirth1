/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBCell.h"


@implementation SBCell

- (void) drawContentAtPoint:(NSPoint)origin
{

}

- (NSSize) contentSize
{
	NSSize s = { 0 }; 
	return s;
}


// x and y are given relative to the cell's origin
- (BOOL) contentHitTestX:(int)x Y:(int)y
{
	NSSize s = [self contentSize];
	if (x >= 0 && x < s.width && y >= 0 && y < s.height) return YES;
	else return NO;
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	return NO;
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	return NO;
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	return NO;
}

- (BOOL) keyDown:(unichar)ukey
{
	return NO;
}

- (void) setColorsBack:(ogColor)back contour:(ogColor)contour front:(ogColor)front
{
	mColorBack = back;
	mColorContour = contour;
	mColorFront = front;
}

- (ogColor) backColor
{
	return mColorBack;
}

- (ogColor) contourColor
{
	return mColorContour;
}

- (ogColor) frontColor
{
	return mColorFront;
}

- (void) setSelected:(BOOL)selected
{
	mSelected = selected;
}

@end
