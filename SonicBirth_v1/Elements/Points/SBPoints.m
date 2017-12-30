/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPoints.h"
#import "SBPointsCell.h"
#import "SBPointCalculation.h"

//-----------------------------------------------------------------
static void privateCalcFunc(void *inObj, int count, int offset)
{
}

//-----------------------------------------------------------------
static inline void SWAP32(void *p) __attribute__ ((always_inline));
static inline void SWAP32(void *p)
{
	unsigned int *i = (unsigned int*)p;
	*i =	((*i & 0xFF) << 24)
		|	((*i & 0xFF00) << 8)
		|	((*i & 0xFF0000) >> 8)
		|	((*i & 0xFF000000) >> 24);
}

//-----------------------------------------------------------------
static inline void SWAP64(void *p) __attribute__ ((always_inline));
static inline void SWAP64(void *p)
{
	unsigned long long *i = (unsigned long long*)p;
	*i =	((*i & 0xFFULL) << 56)
		|	((*i & 0xFF00ULL) << 40)
		|	((*i & 0xFF0000ULL) << 24)
		|	((*i & 0xFF000000ULL) << 8)
		|	((*i & 0xFF00000000ULL) >> 8)
		|	((*i & 0xFF0000000000ULL) >> 24)
		|	((*i & 0xFF000000000000ULL) >> 40)
		|	((*i & 0xFF00000000000000ULL) >> 56);
}

@implementation SBPoints

+ (NSString*) name
{
	return @"Points";
}

- (NSString*) name
{
	return mName;
}

- (NSString*) informations
{
	return @"Set of points making a line. Double-click to insert a point. Use left and right arrow to change interpolation type. Delete key to remove a point.";
}

+ (SBElementCategory) category
{
	return kArgument;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		mPointsBuffer.type = 2; // spline
		mPointsBuffer.count = 3;
		mPointsBuffer.x[0] = 0;   mPointsBuffer.y[0] = 0;
		mPointsBuffer.x[1] = 0.5; mPointsBuffer.y[1] = 1;
		mPointsBuffer.x[2] = 1;   mPointsBuffer.y[2] = 0;
		pointSpline(&mPointsBuffer);
		
		mBuffer.pointsData = &mPointsBuffer;
		
		mViewSize.width = 300;
		mViewSize.height = 100;
		
		mName = [[NSMutableString alloc] initWithString:@"points"];
		if (!mName)
		{
			[self release];
			return nil;
		}
		
		SBPointsCell *cell = (SBPointsCell *)mCell;
		if (cell) [cell setContentSize:mViewSize];
	}
	return self;
}

- (void) dealloc
{
	if (mName) [mName release];
	[super dealloc];
}

- (int) numberOfOutputs
{
	return 1;
}

- (SBBuffer) outputAtIndex:(int)idx
{
	return mBuffer;
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	return @"pts";
}

- (id) savePreset
{
	return [NSData dataWithBytes:&mPointsBuffer length:sizeof(mPointsBuffer)];
}

- (void) loadPreset:(id)preset
{
	memcpy(&mPointsBuffer, [(NSData*)preset bytes], sizeof(mPointsBuffer));
	
	if (mPointsBuffer.type > 1000)
	{
		// just loaded stuff from the other side of endianness...
		SWAP32(&(mPointsBuffer.type));
		SWAP32(&(mPointsBuffer.count));

		for (int i = 0; i < kMaxNumberOfPoints; i++)
		{
			SWAP64(mPointsBuffer.x + i);
			SWAP64(mPointsBuffer.y + i);
			SWAP64(mPointsBuffer.y2 + i);
			SWAP64(mPointsBuffer.hi + i);
			SWAP64(mPointsBuffer.h2 + i);
		}
	}
	
	// force refresh
	if (mCell) [(SBPointsCell *)mCell setPointsBuffer:&mPointsBuffer];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithInt:mPointsBuffer.type] forKey:@"type"];
	
	int c = mPointsBuffer.count, i;
	NSMutableArray *ma = [[NSMutableArray alloc] init];
	for (i = 0; i < c; i++)
	{
		[ma addObject:[NSNumber numberWithDouble:mPointsBuffer.x[i]]];
		[ma addObject:[NSNumber numberWithDouble:mPointsBuffer.y[i]]];
		[ma addObject:[NSNumber numberWithInt:mPointsBuffer.move[i]]];
	}
	[md setObject:ma forKey:@"points"];
	[ma release];
	
	[md setObject:[NSNumber numberWithFloat:mViewSize.width] forKey:@"width"];
	[md setObject:[NSNumber numberWithFloat:mViewSize.height] forKey:@"height"];
	
	[md setObject:mName forKey:@"name"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n, *nx, *ny, *nm;
	NSArray *a;
	
	mPointsBuffer.count = 0;
	
	n = [data objectForKey:@"type"];
	if (n) mPointsBuffer.type = [n intValue];
	
	a = [data objectForKey:@"points"];
	if (a)
	{
		int c = [a count], i;
		for (i = 0; i < c - 2; i += 3)
		{
			nx = [a objectAtIndex:i];
			ny = [a objectAtIndex:i+1];
			nm = [a objectAtIndex:i+2];
			mPointsBuffer.x[i/3] = [nx doubleValue];
			mPointsBuffer.y[i/3] = [ny doubleValue];
			mPointsBuffer.move[i/3] = [nm intValue];
			mPointsBuffer.count++;
		}
	}
	
	pointSort(&mPointsBuffer);
	if (mPointsBuffer.type == 2) pointSpline(&mPointsBuffer);
	
	n = [data objectForKey:@"width"];
	if (n) mViewSize.width = [n floatValue];
	
	n = [data objectForKey:@"height"];
	if (n) mViewSize.height = [n floatValue];
	
	if (mViewSize.width < 50) mViewSize.width = 50;
	if (mViewSize.height < 50) mViewSize.height = 50;
	
	if (mCell) [(SBPointsCell *)mCell setContentSize:mViewSize];
	
	NSString *s = [data objectForKey:@"name"];
	if (s) [mName setString:s];
	
	return YES;
}

- (SBCell*) createCell
{
	SBPointsCell *cell = [[SBPointsCell alloc] init];
	if (cell)
	{
		[cell setPointsBuffer:&mPointsBuffer];
		[cell setContentSize:mViewSize];
	}
	return cell;
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	return kPoints;
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBPoints" owner:self];
		return mSettingsView;
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if (tf == mWidthTF)
	{
		float w = [mWidthTF floatValue];
		if (w < 50) w = 50;
		mViewSize.width = w;
		[mWidthTF setFloatValue:w];
	}
	else if (tf == mHeightTF)
	{
		float h = [mHeightTF floatValue];
		if (h < 50) h = 50;
		mViewSize.height = h;
		[mHeightTF setFloatValue:h];
	}
	else if (tf == mNameTF)
	{
		[mName setString:[mNameTF stringValue]];
	}
	
	if (mCell) [(SBPointsCell *)mCell setContentSize:mViewSize];
	mCalculatedFrame = NO;
	[self didChangeGlobalView];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mWidthTF setFloatValue:mViewSize.width];
	[mHeightTF setFloatValue:mViewSize.height];
	[mNameTF setStringValue:mName];
}

- (void) setName:(NSString*)name
{
	[mName setString:name];
	if (mNameTF) [mNameTF setStringValue:name];
	[self didChangeGlobalView];
	[self didChangeParameterInfo];
}

// we don't need any of that
- (void) prepareForSamplingRate:(int)samplingRate
			sampleCount:(int)sampleCount
			precision:(SBPrecision)precision
			interpolation:(SBInterpolation)interpolation
{}

- (void) changePrecision:(SBPrecision)precision
{}

- (void) changeInterpolation:(SBInterpolation)interpolation
{}

- (void) reset
{}

@end
