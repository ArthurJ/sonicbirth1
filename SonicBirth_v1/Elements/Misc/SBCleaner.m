/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBCleaner.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBCleaner *obj = inObj;
	
	if (!count) return;
	
	if (obj->mClamp)
	{
		if (obj->mPrecision == kFloatPrecision)
		{
			unsigned int *i = (unsigned int*)(obj->pInputBuffers[0].floatData + offset);
			unsigned int *o = (unsigned int*)(obj->mAudioBuffers[0].floatData + offset);

			while(count--)
			{
				unsigned int sample = *i++;
				unsigned int exponent = sample & 0x7F800000;
				int NoNaN = exponent < 0x7F800000; // <- no braces (...) here, otherwise branch!
				int NoDen = exponent > 0;
				int tooBig = exponent >= 0x3F800000;
				int signN = sample & 0x80000000;
				*o++ = ((signN | 0x3F7FFFFF) * tooBig + sample * !tooBig) * ( NoNaN & NoDen );
			}
		}
		else if (obj->mPrecision == kDoublePrecision)
		{
			unsigned int *i = (unsigned int*)(obj->pInputBuffers[0].doubleData + offset);
			unsigned int *o = (unsigned int*)(obj->mAudioBuffers[0].doubleData + offset);

			while(count--)
			{
				unsigned int high = *i++;
				unsigned int exponent = high & 0x7FF00000;
				int NoNaN = exponent < 0x7FF00000;
				int NoDen = exponent > 0;
				int tooBig = exponent >= 0x3FF00000;
				int signN = high & 0x80000000;
				
				int normalN = NoNaN & NoDen;
				*o++ = ((signN | 0x3FEFFFFF) * tooBig + high * !tooBig) * normalN; // apply to high word
				*o++ = (0xFFFFFFFF * tooBig + *i++ * !tooBig) * normalN; // apply to low word
			}
		}
	}
	else
	{
		if (obj->mPrecision == kFloatPrecision)
		{
			unsigned int *i = (unsigned int*)(obj->pInputBuffers[0].floatData + offset);
			unsigned int *o = (unsigned int*)(obj->mAudioBuffers[0].floatData + offset);

			while(count--)
			{
				unsigned int sample = *i++;
				unsigned int exponent = sample & 0x7F800000;
				int NoNaN = exponent < 0x7F800000; // <- no braces (...) here, otherwise branch!
				int NoDen = exponent > 0;
				*o++ = sample * ( NoNaN & NoDen );
			}
		}
		else if (obj->mPrecision == kDoublePrecision)
		{
			unsigned int *i = (unsigned int*)(obj->pInputBuffers[0].doubleData + offset);
			unsigned int *o = (unsigned int*)(obj->mAudioBuffers[0].doubleData + offset);

			while(count--)
			{
				unsigned int high = *i++;
				unsigned int exponent = high & 0x7FF00000;
				int NoNaN = exponent < 0x7FF00000;
				int NoDen = exponent > 0;
				int normalN = NoNaN & NoDen;
				*o++ = high * normalN; // apply to high word
				*o++ = *i++ * normalN; // apply to low word
			}
		}
	}
}

@implementation SBCleaner

+ (NSString*) name
{
	return @"Cleaner";
}

- (NSString*) name
{
	return @"clean";
}

- (NSString*) informations
{
	return	@"Removes denormals, infinities and nan (not a number). Use this if your circuit "
			@"can potentially create those numbers (division by 0, tan(pi/2), etc). "
			@"The signal can optinnaly be clamped to [-1 .. 1].";
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
		[NSBundle loadNibNamed:@"SBCleaner" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mClampButton setState:(mClamp) ? NSOnState : NSOffState];
}

- (void) changedClamp:(id)sender
{
	mClamp = ([mClampButton state] == NSOnState);
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;

		[mInputNames addObject:@"in"];
		[mOutputNames addObject:@"out"];
		
		mClamp = YES;
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}


- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithInt:(mClamp) ? 2 : 1] forKey:@"clamp"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	NSNumber *n;
	
	n = [data objectForKey:@"clamp"];
	if (n) mClamp = ([n intValue] == 2);
	
	return YES;
}

@end
