/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPointsEnvelope.h"


@implementation SBPointsEnvelope

+ (NSString*) name
{
	return @"Points Envelope";
}

- (NSString*) informations
{
	return @"Set of points defining attack, loop and release.  Double-click to insert a point. Use left and right arrow to change interpolation type. Delete key to remove a point.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mPointsBuffer.type = 1; // linear
		mPointsBuffer.count = 4;
		mPointsBuffer.x[0] = 0;			mPointsBuffer.y[0] = 0;
		mPointsBuffer.x[1] = 1./3.;		mPointsBuffer.y[1] = 1;
		mPointsBuffer.x[2] = 2./3.;		mPointsBuffer.y[2] = 1;
		mPointsBuffer.x[3] = 1;			mPointsBuffer.y[3] = 0;
		
		mPointsBuffer.move[0] = 2;
		mPointsBuffer.move[1] = 1;
		mPointsBuffer.move[2] = 1;
		mPointsBuffer.move[3] = 2;
		
		mBuffer.pointsData = &mPointsBuffer;
		
		[mName setString:@"points env"];
	}
	return self;
}

@end
