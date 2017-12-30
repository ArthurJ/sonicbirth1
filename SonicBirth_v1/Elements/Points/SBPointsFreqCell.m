/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPointsFreqCell.h"
#import "SBElement.h" // for gTextAttributes

#define kFooterHeight (20)
#define kTextHeight (12)
#define kFreqStep (20)

@implementation SBPointsFreqCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mRealSize = mSize;
		mRealSize.height += kFooterHeight;
	}
	return self;
}

- (void) setContentSize:(NSSize)size
{
	size.height -= kFooterHeight;
	[super setContentSize:size];
	
	mRealSize = mSize;
	mRealSize.height += kFooterHeight;
}

- (NSSize) contentSize
{
	return mRealSize;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	//if (!mUptodate) [self update];

	NSRect bound = { origin, mRealSize };
	//NSBezierPath *back = [NSBezierPath bezierPathWithRect:bound];
	
	// draw back
	ogSetColor(mColorBack);
	//[back fill];
	ogFillRectangle(bound.origin.x, bound.origin.y, bound.size.width, bound.size.height);
	
	// draw contour
	ogSetColor(mColorContour);
	//[back stroke];
	ogStrokeRectangle(bound.origin.x, bound.origin.y, bound.size.width, bound.size.height);
	
	// draw contour
	NSRect boundOri = { origin, mSize };
	//[NSBezierPath strokeRect:boundOri];
	ogStrokeRectangle(boundOri.origin.x, boundOri.origin.y, boundOri.size.width, boundOri.size.height);
	
	//draw horizontal grey line
	NSPoint lx = { origin.x, origin.y + mSize.height/2.f};
	NSPoint rx = { origin.x+mSize.width, lx.y};
	//[NSBezierPath strokeLineFromPoint:lx toPoint:rx];
	ogStrokeLine(lx.x, lx.y, rx.x, rx.y);
	
	// draw data
	[self drawFunctionAtPoint:origin];

	// draw frequencies
	float logmin = lin2log(20, 20, 20000);
	float logmax = lin2log(20000, 20, 20000);
	float logrange = logmax - logmin;
	float fw =  mSize.width;
	int w = fw - (kFreqStep/2), x, i;
	for (x = 0, i = 0; x < w; x += kFreqStep, i ++)
	{
		int freq = log2lin((x / fw) * logrange + logmin, 20, 20000);
		NSString *text;
		if (freq < 10000) text = [NSString stringWithFormat:@"%i", freq];
		else text = [NSString stringWithFormat:@"%ik", freq/1000];
		NSRect txtRect = { { origin.x + x, origin.y + mSize.height + ((i&1)?(kTextHeight/2):0) }, {kFooterHeight, kTextHeight} };
		//[text drawInRect:txtRect withAttributes:gTextAttributes];
		ogDrawStringInRect([text UTF8String], txtRect.origin.x, txtRect.origin.y, txtRect.size.width, txtRect.size.height);
	}
}


@end
