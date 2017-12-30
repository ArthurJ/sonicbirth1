/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBDisplayMeter.h"
#import "SBMeterCell.h"

// we could export a read only parameter here...

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBDisplayMeter *obj = inObj;
	
	if (!count) return;
	double cur = 0;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		cur = *i;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		cur = *i;
	}
	
	SBMeterCell *cell = (SBMeterCell*)obj->mCell;
	if (cell) [cell setValue:cur];
}

@implementation SBDisplayMeter

+ (NSString*) name
{
	return @"Display Meter";
}

- (NSString*) name
{
	return mName;
}

- (void) setName:(NSString*)name
{
	[mName setString:name];
	if (mNameTF) [mNameTF setStringValue:name];
	[self didChangeGlobalView];
	[self didChangeParameterInfo];
}

- (NSString*) informations
{
	return	@"A value meter that can be used in the plugin interface.";
}

+ (SBElementCategory) category
{
	return kDisplay;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;

		[mInputNames addObject:@"in"];

		mInversed = NO;
		mType = 0;
		mWidth = 10;
		mHeight = 100;
		mMin = 0;
		mMax = 1;
		
		[self updateCell];
		
		
		mName = [[NSMutableString alloc] initWithString:@"dis met"];
		if (!mName)
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (void) dealloc
{
	if (mName) [mName release];
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBDisplayMeter" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	if (mNameTF) [mNameTF setStringValue:mName];
	
	[mMinTF setDoubleValue:mMin];
	[mMaxTF setDoubleValue:mMax];
	[mWidthTF setIntValue:mWidth];
	[mHeightTF setIntValue:mHeight];
	
	[mTypePU selectItemAtIndex:mType];
	[mInversedBt setState:(mInversed) ? NSOnState : NSOffState];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	//[super controlTextDidEndEditing:aNotification];

	id tf = [aNotification object];
	if (tf == mMinTF)
	{
		mMin = [mMinTF doubleValue];
		[mMinTF setDoubleValue:mMin];
	}
	else if (tf == mMaxTF)
	{
		mMax = [mMaxTF doubleValue];
		[mMaxTF setDoubleValue:mMax];
	}
	else if (tf == mWidthTF)
	{
		mWidth = [mWidthTF intValue];
		if (mWidth < 3) mWidth = 3;
		[mWidthTF setIntValue:mWidth];
	}
	else if (tf == mHeightTF)
	{
		mHeight = [mHeightTF intValue];
		if (mHeight < 3) mHeight = 3;
		[mHeightTF setIntValue:mHeight];
	}
	else if (tf == mNameTF)
	{
		[self setName:[mNameTF stringValue]];
	}
	
	[self updateCell];
	
	mCalculatedFrame = NO;
	[self didChangeGlobalView];
}


- (void) updateCell
{
	SBMeterCell *cell = (SBMeterCell*)mCell;
	if (cell)
	{
		[cell setWidth:mWidth];
		[cell setHeight:mHeight];
		[cell setMin:mMin];
		[cell setMax:mMax];
		[cell setInversed:mInversed];
		[cell setType:mType];
	}
}

- (void) changedInversed:(id)sender
{
	mInversed = [mInversedBt state] == NSOnState;
	[self updateCell];
}

- (void) changedType:(id)sender
{
	int newType = [mTypePU indexOfSelectedItem];
	
	if (newType != mType)
	{
		int w = mWidth;
		int h = mHeight;
		
		mWidth = h;
		mHeight = w;
		mType = newType;

		[mWidthTF setIntValue:mWidth];
		[mHeightTF setIntValue:mHeight];
		[self updateCell];
	
		mCalculatedFrame = NO;
		[self didChangeGlobalView];
	}
}

- (BOOL) alwaysExecute
{
	return YES;
}

- (BOOL) constantRefresh
{
	return YES;
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mMin] forKey:@"min"];
	[md setObject:[NSNumber numberWithDouble:mMax] forKey:@"max"];

	
	[md setObject:[NSNumber numberWithInt:mWidth] forKey:@"width"];
	[md setObject:[NSNumber numberWithInt:mHeight] forKey:@"height"];
	
	[md setObject:[NSNumber numberWithInt:mType] forKey:@"type"];
	[md setObject:[NSNumber numberWithInt:(mInversed) ? 2 : 1] forKey:@"inversed"];
	
	[md setObject:mName forKey:@"argName"];

	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n;
	
	n = [data objectForKey:@"min"];
	if (n) mMin = [n doubleValue];
	
	n = [data objectForKey:@"max"];
	if (n) mMax = [n doubleValue];
	
	n = [data objectForKey:@"width"];
	if (n) mWidth = [n intValue];
	if (mWidth < 3) mWidth = 3;
	
	n = [data objectForKey:@"height"];
	if (n) mHeight = [n intValue];
	if (mHeight < 3) mHeight = 3;
	
	n = [data objectForKey:@"type"];
	if (n) mType = [n intValue];
	if (mType < 0) mType = 0; else if (mType > 1) mType = 1;
	
	n = [data objectForKey:@"inversed"];
	if (n) mInversed = ([n intValue] == 2);
	
	[self updateCell];
	
	NSString *s = [data objectForKey:@"argName"];
	if (s) [mName setString:s];
	
	return YES;
}

- (SBCell*) createCell
{
	return [[SBMeterCell alloc] init];
}

@end
