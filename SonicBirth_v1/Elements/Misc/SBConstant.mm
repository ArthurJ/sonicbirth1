/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBConstant.h"
#import "SBEditFloatCell.h"
#import "equation.h"

extern "C" void SBConstantPrivateCalcFunc(void *inObj, int count, int offset);
extern "C" void SBConstantPrivateCalcFuncImpl(int count, int offset,
									SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers,
									BOOL *mUpdateBuffer,
									int mSampleCount,
									double mValue)
{
	if (!*mUpdateBuffer) return;
	
	count = mSampleCount;
	
	if (mPrecision == kFloatPrecision)
	{
		float *o = mAudioBuffers[0].floatData;
		float val = mValue;
		while(count--) *o++ = val;
	}
	else if (mPrecision == kDoublePrecision)
	{
		double *o = mAudioBuffers[0].doubleData;
		double val = mValue;
		while(count--) *o++ = val;
	}
	
	*mUpdateBuffer = NO;
}

@implementation SBConstant

+ (NSString*) name
{
	return @"Constant";
}

- (NSString*) name
{
	return @"cst";
}

- (NSString*) informations
{
	return @"A constant number.";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBConstant" owner:self];
		return mSettingsView;
	}
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = SBConstantPrivateCalcFunc;

		[mOutputNames addObject:@"o"];
	
		[self setValue:[self defaultValue]];
		
		SBEditFloatCell *c = (SBEditFloatCell*)mCell;
		if (c) [c setValue:mValue];
	}
	return self;
}

- (void) reset
{
	mUpdateBuffer = YES;
	[super reset];
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mValueEdit setDoubleValue:mValue];
	[mValueShow setDoubleValue:mValue];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	//[self setValue:[mValueEdit doubleValue]];
	
	NSString *st = [[mValueEdit stringValue] stringByAppendingString:@";"];
	[self setValue:parseSimpleEquation([st UTF8String])];
	
	mUpdateBuffer = YES;

	[mValueEdit setDoubleValue:mValue];
	[mValueShow setDoubleValue:mValue];
	
	SBEditFloatCell *c = (SBEditFloatCell*)mCell;
	if (c)
	{
		[c setValue:mValue];
		[self didChangeView];
	}
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mValue] forKey:@"val"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	if (!data) return NO;

	NSNumber *n;
	
	n = [data objectForKey:@"val"];
	if (n) [self setValue:[n doubleValue]];
	

	SBEditFloatCell *c = (SBEditFloatCell*)mCell;
	if (c) [c setValue:mValue];
	
	return YES;
}

- (void) setValue:(double)value
{
	mValue = value;
}

- (void) changePrecision:(SBPrecision)precision
{
	mUpdateBuffer = YES;
	[super changePrecision:precision];
}

- (void) editCellUpdated:(SBEditFloatCell*)cell
{
	[self setValue:[cell value]];
	mUpdateBuffer = YES;

	[mValueEdit setDoubleValue:mValue];
	[mValueShow setDoubleValue:mValue];
}

- (SBCell*) createCell
{
	SBEditFloatCell *c = [[SBEditFloatCell alloc] init];
	if (c)
	{
		[c setTarget:self];
		[c setValue:mValue];
	}
	return c;
}

- (double) defaultValue
{
	return 1;
}

@end
