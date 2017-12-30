/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
@class SBElement;

@interface SBCell : NSObject
{
	BOOL	mSelected;

	ogColor mColorBack;
	ogColor mColorContour;
	ogColor mColorFront;
}

- (void) drawContentAtPoint:(NSPoint)origin;
- (NSSize) contentSize;

// x and y are given relative to the cell's origin
- (BOOL) contentHitTestX:(int)x Y:(int)y;
- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount;
- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly;
- (BOOL) mouseUpX:(int)x Y:(int)y;
- (BOOL) keyDown:(unichar)ukey;

- (void) setColorsBack:(ogColor)back contour:(ogColor)contour front:(ogColor)front;

- (ogColor) backColor;
- (ogColor) contourColor;
- (ogColor) frontColor;

- (void) setSelected:(BOOL)selected;

@end
