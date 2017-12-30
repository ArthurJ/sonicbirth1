/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBDisplayOsc.h"
#import "SBOscCell.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBDisplayOsc *obj= inObj;
	
	if (!count) return;
	
	SBOscCell *cell = (SBOscCell*)obj->mCell;
	if (!cell) return;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		[cell processFloats:i count:count];
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		[cell processDoubles:i count:count];
	}
}

@implementation SBDisplayOsc

+ (NSString*) name
{
	return @"Display Osc.";
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
	return	@"An oscilloscope that can be used in the plugin interface.";
}

+ (SBElementCategory) category
{
	return kDisplay;
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBDisplayOsc" owner:self];
		return mSettingsView;
	}
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;

		[mInputNames addObject:@"in"];

		mWidth = 200;
		mHeight = 100;
		mBottom = -1;
		mTop = 1;
		mMs = mWidth / 44.100;
		
		mFreezeWhenFull = NO;
		
		[self updateCell];
		
		mName = [[NSMutableString alloc] initWithString:@"dis osc"];
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

- (void) updateCell
{
	SBOscCell *cell = (SBOscCell *)mCell;
	if (cell)
	{
		[cell setTop:mTop];
		[cell setBottom:mBottom];
		[cell setWidth:mWidth];
		[cell setHeight:mHeight];
		
		float sr = mSampleRate;
		if (sr < 100.f) sr = 44100.f;
		
		int sp = sr * mMs * 0.001;
		if (sp < 1) sp = 1;
		
		[cell setSamplesPerPixel:sp];
		[cell setFreezeWhenFull:mFreezeWhenFull];
	}
}

- (void) reset
{
	[super reset];
	SBOscCell *cell = (SBOscCell *)mCell;
	if (cell) [cell reset];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	if (mNameTF) [mNameTF setStringValue:mName];
	
	[mBottomTF setDoubleValue:mBottom];
	[mTopTF setDoubleValue:mTop];
	[mWidthTF setIntValue:mWidth];
	[mHeightTF setIntValue:mHeight];
	
	[mResolutionSlider setMinValue:0];
	[mResolutionSlider setMaxValue:100];
	
	float sr = mSampleRate;
	if (sr < 100) sr = 44100.f;
	
	int sp = sr * mMs * 0.001;
	if (sp < 1) sp = 1;
	
	[mResolutionSlider setFloatValue:mMs];
	
	if (mMs < 1)
		[mResolutionTF setStringValue:[NSString stringWithFormat:@"%i samples", sp]];
	else
		[mResolutionTF setStringValue:[NSString stringWithFormat:@"%.2f ms", mMs]];
		
	[mFreezeWhenFullBt setState:(mFreezeWhenFull) ? NSOnState : NSOffState];
}

- (void) changedResolution:(id)sender
{
	if (sender == mResolutionSlider)
	{
		float ms = [mResolutionSlider floatValue];
		if (ms < 0) ms = 0;
		
		mMs = ms;

		[self updateCell];
		[mResolutionSlider setFloatValue:mMs];
		
		float sr = mSampleRate;
		if (sr < 100) sr = 44100.f;
		
		int sp = sr * mMs * 0.001;
		if (sp < 1) sp = 1;
	
		if (ms < 1)
			[mResolutionTF setStringValue:[NSString stringWithFormat:@"%i samples", sp]];
		else
			[mResolutionTF setStringValue:[NSString stringWithFormat:@"%.2f ms", mMs]];
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	//[super controlTextDidEndEditing:aNotification];

	BOOL changedWidth = NO;

	id tf = [aNotification object];
	if (tf == mBottomTF)
	{
		mBottom = [mBottomTF doubleValue];
		[mBottomTF setDoubleValue:mBottom];
	}
	else if (tf == mTopTF)
	{
		mTop = [mTopTF doubleValue];
		[mTopTF setDoubleValue:mTop];
	}
	else if (tf == mWidthTF)
	{
		mWidth = [mWidthTF intValue];
		if (mWidth < 20) mWidth = 20;
		[mWidthTF setIntValue:mWidth];
		changedWidth = YES;
	}
	else if (tf == mHeightTF)
	{
		mHeight = [mHeightTF intValue];
		if (mHeight < 20) mHeight = 20;
		[mHeightTF setIntValue:mHeight];
	}
	else if (tf == mNameTF)
	{
		[self setName:[mNameTF stringValue]];
	}
	
	if (changedWidth) [self willChangeAudio];
		[self updateCell];
	if (changedWidth) [self didChangeAudio];
	
	mCalculatedFrame = NO;
	[self didChangeGlobalView];
}

- (SBCell*) createCell
{
	return [[SBOscCell alloc] init];
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
	
	[md setObject:[NSNumber numberWithDouble:mBottom] forKey:@"bottom"];
	[md setObject:[NSNumber numberWithDouble:mTop] forKey:@"top"];
	[md setObject:[NSNumber numberWithDouble:mMs] forKey:@"millisec"];
	
	[md setObject:[NSNumber numberWithInt:mWidth] forKey:@"width"];
	[md setObject:[NSNumber numberWithInt:mHeight] forKey:@"height"];
	
	[md setObject:[NSNumber numberWithInt:(mFreezeWhenFull) ? 2 : 1] forKey:@"freezeWhenFull"];
	
	[md setObject:mName forKey:@"argName"];

	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n;
	
	n = [data objectForKey:@"bottom"];
	if (n) mBottom = [n doubleValue];
	
	n = [data objectForKey:@"top"];
	if (n) mTop = [n doubleValue];
	
	n = [data objectForKey:@"millisec"];
	if (n) mMs = [n doubleValue];
	if (mMs < 0) mMs = 0;
	
	n = [data objectForKey:@"width"];
	if (n) mWidth = [n intValue];
	if (mWidth < 20) mWidth = 20;
	
	n = [data objectForKey:@"height"];
	if (n) mHeight = [n intValue];
	if (mHeight < 20) mHeight = 20;
	
	n = [data objectForKey:@"freezeWhenFull"];
	if (n) mFreezeWhenFull = ([n intValue] == 2);
	
	[self updateCell];
	
	NSString *s = [data objectForKey:@"argName"];
	if (s) [mName setString:s];
	
	return YES;
}

- (void) specificPrepare
{
	SBOscCell *cell = (SBOscCell *)mCell;
	if (cell)
	{
		float sr = mSampleRate;
		if (sr < 100) sr = 44100;
		
		int sp = sr * mMs * 0.001;
		if (sp < 1) sp = 1;
		
		[cell setSamplesPerPixel:sp];
	}
}

- (void) changedFreezeWhenFull:(id)sender
{
	mFreezeWhenFull = ([mFreezeWhenFullBt state] == NSOnState);
	SBOscCell *cell = (SBOscCell *)mCell;
	if (cell) [cell setFreezeWhenFull:mFreezeWhenFull];
}

@end

static void privateCalcFuncVarRes(void *inObj, int count, int offset)
{
	SBDisplayOscVarRes *obj = inObj;
	
	if (!count) return;
	
	SBOscCell *cell = (SBOscCell*)obj->mCell;
	if (!cell) return;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float ms = obj->pInputBuffers[1].floatData[offset];
		
		double sr = obj->mSampleRate;
		if (sr < 100) sr = 44100.0;
		
		int sp = sr * ms * 0.001;
		if (sp < 1) sp = 1;
		
		[cell setSamplesPerPixel:sp];
		
		[cell processFloats:i count:count];
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double ms = obj->pInputBuffers[1].doubleData[offset];
		
		double sr = obj->mSampleRate;
		if (sr < 100) sr = 44100.0;
		
		int sp = sr * ms * 0.001;
		if (sp < 1) sp = 1;
		
		[cell setSamplesPerPixel:sp];
		
		[cell processDoubles:i count:count];
	}
}

@implementation SBDisplayOscVarRes

+ (NSString*) name
{
	return @"Display Osc. (Var. res.)";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFuncVarRes;
		
		[mInputNames addObject:@"res"];
	}
	return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[mResolutionTF setHidden:YES];
	[mResolutionSlider setHidden:YES];
}

@end



