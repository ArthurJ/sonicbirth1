/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBRootCircuitPrecision.h"
#import "SBIndexedCell.h"

NSString *kSBRootCircuitPrecisionChangeNotification = @"kSBRootCircuitPrecisionChangeNotification";

@implementation SBRootCircuitPrecision

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

- (int) numberOfParameters
{
	return 1;
}

- (double) minValueForParameter:(int)i
{
	return 0;
}

- (double) maxValueForParameter:(int)i
{
	return 1;
}

- (double) currentValueForParameter:(int)i
{
	return mCurMode;
}

- (NSArray*) indexedNamesForParameter:(int)i
{
	return [NSArray arrayWithObjects:@"32 Bits", @"64 Bits", nil];
}

- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i
{
	mCurMode = preset;
	if (mCurMode < 0) mCurMode = 0;
	else if (mCurMode > 1) mCurMode = 1;
	
	[self willChangeAudio];
	
		[[NSNotificationCenter defaultCenter]
				postNotificationName:kSBRootCircuitPrecisionChangeNotification object:self];
			
	[self didChangeAudio];
	
	if (mPrecisionMatrix) [mPrecisionMatrix selectCellAtRow:0 column:mCurMode];
}

+ (SBElementCategory) category
{
	return kInternal;
}

+ (NSString*) name
{
	return @"Bit Precision";
}

- (NSString*) name
{
	return @"Bit Precision";
}

- (NSString*) informations
{
	return	@"Sets the bit precision of the audio engine.";
}

- (NSString*) nameForParameter:(int)i
{
	return @"Bit Precision";
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mPrecisionMatrix selectCellAtRow:0 column:mCurMode];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBRootCircuitPrecision" owner:self];
		return mSettingsView;
	}
}

- (void) changedPrecision:(id)sender
{
	[self takeValue:[mPrecisionMatrix selectedColumn] offsetToChange:0 forParameter:0];
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
