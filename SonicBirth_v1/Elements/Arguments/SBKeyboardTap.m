/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBKeyboardTap.h"
#import "SBFocusCell.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBKeyboardTap *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *o = obj->mAudioBuffers[0].floatData + offset;
		if (obj->mTapped)
		{
			*o++ = 1; count--;
			obj->mTapped = NO;
		}
		else
			*o = 0;
		
		memset(o, 0, count * sizeof(float));
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		if (obj->mTapped)
		{
			*o++ = 1; count--;
			obj->mTapped = NO;
		}
		else
			*o = 0;
		
		memset(o, 0, count * sizeof(double));
	}
}

@implementation SBKeyboardTap

+ (NSString*) name
{
	return @"Keyboard Tap";
}

- (NSString*) informations
{
	return @"Emits a single 1 when receiving a key stroke.";
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBKeyboardTap" owner:self];
		return mSettingsView;
	}
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		mTapped = NO;
		mCellRadius = 10;
		mNumberOfOutputs = 1;
		[mName setString:@"ktap"];
		
		SBFocusCell *cell = (SBFocusCell*)mCell;
		if (cell) [cell setRadius:mCellRadius];
		mCalculatedFrame = NO;
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[mCellRadiusTF setDoubleValue:mCellRadius];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[super controlTextDidEndEditing:aNotification];

	id tf = [aNotification object];
	if (tf == mCellRadiusTF)
	{
		mCellRadius = [mCellRadiusTF doubleValue];
		if (mCellRadius < 5) mCellRadius = 5;
		else if (mCellRadius > 100) mCellRadius = 100;
		
		[mCellRadiusTF setDoubleValue:mCellRadius];
		
		SBFocusCell *cell = (SBFocusCell*)mCell;
		if (cell) [cell setRadius:mCellRadius];
		mCalculatedFrame = NO;
		
		[self didChangeGlobalView];
	}
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mCellRadius] forKey:@"cellRadius"];

	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n;
	
	n = [data objectForKey:@"cellRadius"];
	if (n) mCellRadius = [n doubleValue];
	
	SBFocusCell *cell = (SBFocusCell*)mCell;
	if (cell) [cell setRadius:mCellRadius];
	mCalculatedFrame = NO;
	
	return YES;
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

- (SBParameterType) typeForParameter:(int)i
{
	return kParameterUnit_Boolean;
}

- (BOOL) readFlagForParameter:(int)i
{
	return NO;
}

- (double) currentValueForParameter:(int)i
{
	return 0;
}

- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i
{
	if (preset > 0.5)
	{
		mTapped = YES;
		SBFocusCell *cell = (SBFocusCell*)mCell;
		if (cell)
		{	
			[cell tap];
			[self didChangeView];
			[self performSelector:@selector(didChangeView) withObject:nil afterDelay:0.1];
		}
	}
}

- (SBCell*) createCell
{
	SBFocusCell *cell = [[SBFocusCell alloc] init];
	if (cell) [cell setArgument:self parameter:0];
	return cell;
}

- (void) reset
{
	mTapped = NO;
}

- (BOOL) realtime
{
	return YES;
}

- (void) specificPrepare
{
	
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	return @"tap";
}

@end
