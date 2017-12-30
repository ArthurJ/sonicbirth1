/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPointsFrequency.h"
#import "SBPointsFreqCell.h"

@implementation SBPointsFrequency

+ (NSString*) name
{
	return @"Points Frequency";
}

- (NSString*) informations
{
	return @"Set of points suitable for fft conversion or generation.  Double-click to insert a point. Use left and right arrow to change interpolation type. Delete key to remove a point.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mPointsBuffer.type = 1; // linear
		mPointsBuffer.count = 2;
		mPointsBuffer.x[0] = 0;			mPointsBuffer.y[0] = 0.5;
		mPointsBuffer.x[1] = 1;			mPointsBuffer.y[1] = 0.5;
		
		mPointsBuffer.move[0] = 2;
		mPointsBuffer.move[1] = 2;
		
		mBuffer.pointsData = &mPointsBuffer;
		
		[mName setString:@"points freq"];
	}
	return self;
}

- (SBCell*) createCell
{
	SBPointsFreqCell *cell = [[SBPointsFreqCell alloc] init];
	if (cell)
	{
		[cell setPointsBuffer:&mPointsBuffer];
		[cell setContentSize:mViewSize];
	}
	return cell;
}

@end
