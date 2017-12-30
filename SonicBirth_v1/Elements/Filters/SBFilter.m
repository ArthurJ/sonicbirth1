/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFilter.h"

@implementation SBFilter

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"f"];
		
		[mOutputNames addObject:@"out"];
	}
	return self;
}

+ (SBElementCategory) category
{
	return kFilter;
}

@end
