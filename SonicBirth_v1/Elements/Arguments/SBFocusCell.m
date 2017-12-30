/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFocusCell.h"
#import "SBArgument.h"

@implementation SBFocusCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mArgument = nil;
		mParameter = 0;
		mRadius = 10;
		mTapped = NO;
		mSelected = NO;
		mClickCount = 0;
	}
	return self;
}

- (void) setArgument:(SBArgument*)argument parameter:(int)idx
{
	mArgument = argument;
	mParameter = idx;
}

- (void) setSelected:(BOOL)selected
{
	[super setSelected:selected];
	mClickCount = 0;
}

- (void) tap
{
	mTapped = YES;
}

- (void) setRadius:(float)radius
{
	mRadius = radius;
}

- (NSSize) contentSize
{
	NSSize s = { mRadius * 2, mRadius * 2 }; 
	return s;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	// draw back
	ogSetColor(mColorBack);
	ogFillCircle(origin.x + mRadius, origin.y + mRadius, mRadius);
	
	// draw contour
	ogSetColor(mColorContour);
	ogStrokeCircle(origin.x + mRadius, origin.y + mRadius, mRadius);
	
	// draw front
	ogSetColor(mColorFront);
	float rad = mRadius - 1;
	
	if (mSelected && !mTapped)
		ogStrokeCircle(origin.x + mRadius, origin.y + mRadius, rad);
	else if (mTapped)
	{
		ogFillCircle(origin.x + mRadius, origin.y + mRadius, rad);
		ogStrokeCircle(origin.x + mRadius, origin.y + mRadius, rad); // stroke it too for antialiasing
	}
	
	mTapped = NO;
}

- (BOOL) keyDown:(unichar)ukey
{
	if (ukey == NSDeleteFunctionKey || ukey == 0x7F) return NO;

	mTapped = YES;
	if (mArgument)
		[mArgument takeValue:1 offsetToChange:0 forParameter:mParameter];
	return YES;
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	int rad = mRadius * 2;
	if (x < 0 || x >= rad || y < 0 || y > rad) return NO;
	
	if (mClickCount == 0)
	{
		mClickCount++;
		return NO;
	}
	
	mTapped = YES;
	if (mArgument)
		[mArgument takeValue:1 offsetToChange:0 forParameter:mParameter];
		
	return YES;
}

@end
