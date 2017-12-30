/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAddMany.h"
#import <Accelerate/Accelerate.h>

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBAddMany *obj = inObj;

	int i, c = obj->mInputs;
	if (c < 2) return;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *o = obj->mAudioBuffers[0].floatData + offset;
		vDSP_vadd(	obj->pInputBuffers[0].floatData + offset, 1,
					obj->pInputBuffers[1].floatData + offset, 1,
					o, 1, count);
		
		for (i = 2; i < c; i++)
			vDSP_vadd(	obj->pInputBuffers[i].floatData + offset, 1,
						o, 1, o, 1, count);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		vDSP_vaddD(	obj->pInputBuffers[0].doubleData + offset, 1,
					obj->pInputBuffers[1].doubleData + offset, 1,
					o, 1, count);
		
		for (i = 2; i < c; i++)
			vDSP_vaddD(	obj->pInputBuffers[i].doubleData + offset, 1,
						o, 1, o, 1, count);
	}
}

@implementation SBAddMany

+ (NSString*) name
{
	return @"Add Many";
}

- (NSString*) name
{
	return @"add many";
}

+ (SBElementCategory) category
{
	return kAlgebraic;
}

- (NSString*) informations
{
	return @"Outputs the summation of 3 to 16 inputs.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		mInputs = 4;

		[self updateInputs];
		
		[mOutputNames addObject:@"out"];
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}


- (void) updateInputs
{
	[mInputNames removeAllObjects];
	
	int i, c = mInputs;
	for (i = 0; i < c; i++)
		[mInputNames addObject:[NSString stringWithFormat:@"in%i",i]];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBAddMany" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mTF setIntValue:mInputs];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[self willChangeAudio];
	
		mInputs = [mTF intValue];
		if (mInputs < 3) mInputs = 3;
		if (mInputs > 16) mInputs = 16;
		[mTF setIntValue:mInputs];
		[self updateInputs];
		
	[self didChangeConnections];
	[self didChangeAudio];
	
	[self didChangeGlobalView];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mInputs] forKey:@"cnt"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	NSNumber *n;
	
	n = [data objectForKey:@"cnt"];
	if (n) mInputs = [n doubleValue];
	
	if (mInputs < 3) mInputs = 3;
	if (mInputs > 16) mInputs = 16;
	
	[self updateInputs];
	
	return YES;
}

@end
