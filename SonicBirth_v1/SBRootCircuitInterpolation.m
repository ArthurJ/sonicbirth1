/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBRootCircuitInterpolation.h"
#import "SBIndexedCell.h"

NSString *kSBRootCircuitInterpolationChangeNotification = @"kSBRootCircuitInterpolationChangeNotification";

@implementation SBRootCircuitInterpolation

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (BOOL) realtimeForParameter:(int)i
{
	return YES;
}

- (SBParameterType) typeForParameter:(int)i
{
	return kParameterUnit_Indexed;
}

- (double) minValueForParameter:(int)i
{
	return 0;
}

- (double) maxValueForParameter:(int)i
{
	return 1;
}

- (int) numberOfParameters
{
	return 1;
}

- (double) currentValueForParameter:(int)i
{
	return mCurMode;
}

- (NSArray*) indexedNamesForParameter:(int)i
{
	return [NSArray arrayWithObjects:@"No interpolation", @"Linear interpolation", nil];
}

- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i
{
	mCurMode = preset;
	if (mCurMode < 0) mCurMode = 0;
	else if (mCurMode > 1) mCurMode = 1;

	[[NSNotificationCenter defaultCenter]
		postNotificationName:kSBRootCircuitInterpolationChangeNotification object:self];

	if (mInterpolationMatrix) [mInterpolationMatrix selectCellAtRow:mCurMode column:0];
}

+ (SBElementCategory) category
{
	return kInternal;
}

+ (NSString*) name
{
	return @"Interpolation Precision";
}

- (NSString*) name
{
	return @"Interpolation Precision";
}

- (NSString*) informations
{
	return	@"Sets the interpolation type of the audio engine.";
}

- (NSString*) nameForParameter:(int)i
{
	return @"Interpolation Precision";
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mInterpolationMatrix selectCellAtRow:mCurMode column:0];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBRootCircuitInterpolation" owner:self];
		return mSettingsView;
	}
}

- (void) changedInterpolation:(id)sender
{
	[self takeValue:[mInterpolationMatrix selectedRow] offsetToChange:0 forParameter:0];
	[self didChangeView];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithInt:mCurMode] forKey:@"curMode"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n;
	
	n = [data objectForKey:@"curMode"];
	if (n) mCurMode = [n intValue];

	[self takeValue:mCurMode offsetToChange:0 forParameter:0];
	
	return YES;
}

- (SBCell*) createCell
{
	SBIndexedCell *cell = [[SBIndexedCell alloc] init];
	if (cell) [cell setArgument:self parameter:0];
	return cell;
}

@end
