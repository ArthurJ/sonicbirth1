/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPiecewiseCircuit.h"
#import "SBCircuit.h"


static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBPiecewiseCircuit *obj = inObj;

	int i, c;
	SBCircuit *cir = nil;
	
	double curVal;
	if (obj->mPrecision == kFloatPrecision)
	{
		float *input = obj->pInputBuffers[0].floatData + offset;
		curVal = *input;
	}
	else // double precision
	{
		double *input = obj->pInputBuffers[0].doubleData + offset;
		curVal = *input;
	}

	// find which circuit will be used
	c = obj->mCachedSubCircuitsCount;
	if (c == 1)
	{
		cir = obj->mCachedSubCircuits[0];
	}
	else
	{
		c = obj->mCachedRangesCount;
		for (i = 0; i < c; i++)
		{
			if (curVal < obj->mCachedRanges[i])
			{
				cir = obj->mCachedSubCircuits[i];
				break;
			}
		}
		if (!cir)
			cir = obj->mCachedSubCircuits[c];
	}
	
	//
	if (!cir) return;
	//

	// connect the inputs
	c = obj->mInputCount;
	for (i = 0; i < c; i++)
		cir->pInputBuffers[i] = obj->pInputBuffers[i+1];

	// execute it
	(cir->pCalcFunc)(cir, count, offset);
	
	// copy back the input
	if (obj->mPrecision == kFloatPrecision)
	{
		c = obj->mOutputCount;
		for (i = 0; i < c; i++)
			memcpy(obj->mAudioBuffers[i].floatData + offset,
					cir->pOutputBuffers[i].floatData + offset,
					count * sizeof(float));
	}
	else // double precision
	{
		c = obj->mOutputCount;
		for (i = 0; i < c; i++)
			memcpy(obj->mAudioBuffers[i].doubleData + offset,
					cir->pOutputBuffers[i].doubleData + offset,
					count * sizeof(double));
	}
}

@implementation SBPiecewiseCircuit

+ (NSString*) name
{
	return @"Piecewise circuit";
}

- (NSString*) name
{
	return @"p cir";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return	@"Depending on the value of the range input, a specific subcircuit is executed. "
			@"This value is checked once per block of samples. "
			@"The subcircuit which is entered when clicking next depends on the selected row "
			@"in the settings window.";
}


- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		mSubCircuits = [[NSMutableArray alloc] init];
		if (!mSubCircuits)
		{
			[self release];
			return nil;
		}
		
		mRanges = [[NSMutableArray alloc] init];
		if (!mRanges)
		{
			[self release];
			return nil;
		}
		
		// basic circuit for -inf to +inf
		SBCircuit *c = [[SBCircuit alloc] init];
		if (!c)
		{
			[self release];
			return nil;
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementWillChangeAudio:)
						name:kSBElementWillChangeAudioNotification
						object:c];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeAudio:)
						name:kSBElementDidChangeAudioNotification
						object:c];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeConnections:)
						name:kSBElementDidChangeConnectionsNotification
						object:c];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeName:)
						name:kSBCircuitDidChangeNameNotification
						object:c];
		
		[c setCanChangeNumberOfInputsOutputs:NO];
		[mSubCircuits addObject:c];
		[c release];
		
		// [mInputNames addObject:@"range"];
	}
	return self;
}


- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (mSettingsView) [mSettingsView release];
	if (mSubCircuits) [mSubCircuits release];
	if (mRanges) [mRanges release];
	[super dealloc];
}


- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBPiecewiseCircuit" owner:self];
		return mSettingsView;
	}
}

- (NSString*) nameOfInputAtIndex:(int)idx
{
	if (idx <= 0) return @"range";
	else return [[mSubCircuits objectAtIndex:0] nameOfInputAtIndex:idx - 1];
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	return [[mSubCircuits objectAtIndex:0] nameOfOutputAtIndex:idx];
}

- (int) numberOfInputs
{
	return 1 + [[mSubCircuits objectAtIndex:0] numberOfInputs];
}
- (int) numberOfOutputs
{
	return [[mSubCircuits objectAtIndex:0] numberOfOutputs];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mInputTF setIntValue:mInputCount];
	[mOutputTF setIntValue:mOutputCount];
}

- (IBAction) createRange:(id)sender
{
	int count = [mSubCircuits count];
	if (count >= kMaxSubCircuits) return;

	NSNumber *n = [NSNumber numberWithDouble:0.5 + (count - 1)];
	SBCircuit *c = [[SBCircuit alloc] init];
	if (c && n)
	{
		[c setNumberOfInputs:mInputCount];
		[c setNumberOfOutputs:mOutputCount];
		[c setCanChangeNumberOfInputsOutputs:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementWillChangeAudio:)
						name:kSBElementWillChangeAudioNotification
						object:c];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeAudio:)
						name:kSBElementDidChangeAudioNotification
						object:c];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeConnections:)
						name:kSBElementDidChangeConnectionsNotification
						object:c];
						
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeName:)
						name:kSBCircuitDidChangeNameNotification
						object:c];
		
		[mSubCircuits addObject:c];
		[mRanges addObject:n];
		[self sortRanges];
		[mRangesTableView reloadData];
		
		[c release];
	}
}

- (IBAction) deleteRange:(id)sender
{
	int i = [mRangesTableView selectedRow];
	if (i != 0)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
												name:nil
												object:[mSubCircuits objectAtIndex:i]];
	
		[mSubCircuits removeObjectAtIndex:i];
		[mRanges removeObjectAtIndex:i - 1];
		[mRangesTableView reloadData];
	}
}

- (SBCircuit*)subCircuit
{
	int i = [mRangesTableView selectedRow];
	if (i >= 0)
		return [mSubCircuits objectAtIndex:i];
	else
		return [mSubCircuits objectAtIndex:0];
}

- (void) sortRanges
{
	//#warning "sort circuits too!"
	//[mRanges sortUsingSelector:@selector(compare:)];
	
	// do a manual sort
	int c = [mRanges count], i;
	if (c > 0)
	{
		BOOL changed = YES;
		while(changed)
		{
			changed = NO;
			double pval = [[mRanges objectAtIndex:0] doubleValue];
			for(i = 1; i < c; i++)
			{
				double cval = [[mRanges objectAtIndex:i] doubleValue];
				if (cval < pval)
				{
					[mRanges exchangeObjectAtIndex:i withObjectAtIndex:i - 1];
					[mSubCircuits exchangeObjectAtIndex:i+1 withObjectAtIndex:i];
					changed = YES;
				}
			}
		}
	}
	
	// recache everything
	mCachedRangesCount = c;
	for (i = 0; i < c; i++)
	{
		mCachedRanges[i] = [[mRanges objectAtIndex:i] doubleValue];
	}
	
	c = [mSubCircuits count];
	mCachedSubCircuitsCount = c;
	for (i = 0; i < c; i++)
	{
		mCachedSubCircuits[i] = [mSubCircuits objectAtIndex:i];
	}
}

- (void) controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if (tf == mInputTF)
	{
		mInputCount = [mInputTF intValue];
		[self updateSubCircuitsForInputs];
		[mInputTF setIntValue:mInputCount];
	}
	else if (tf == mOutputTF)
	{
		mOutputCount = [mOutputTF intValue];
		[self updateSubCircuitsForOutputs];
		[mOutputTF setIntValue:mOutputCount];
	}
}

- (void) updateSubCircuitsForInputs
{
	if (mInputCount < 0) mInputCount = 0;
	else if (mInputCount > kMaxChannels - 1) mInputCount = kMaxChannels - 1; // reserve 1 for range
	
	[self willChangeAudio];
	mLockIsHeld = YES;
	
	/*
	[mInputNames removeAllObjects];
	[mInputNames addObject:@"range"];
	int c = mInputCount, i;
	for (i = 0; i < c; i++)
		[mInputNames addObject:[NSString stringWithFormat:@"in%i", i]];
	*/
	
	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
	{
		SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
		[circuit setNumberOfInputs:mInputCount];
	}
	
	[self didChangeConnections];
	
	mLockIsHeld = NO;
	[self didChangeAudio];
	
	[self didChangeGlobalView];
}

- (void) updateSubCircuitsForOutputs
{
	if (mOutputCount < 0) mOutputCount = 0;
	else if (mOutputCount > kMaxChannels) mOutputCount = kMaxChannels;
	
	[self willChangeAudio];
	mLockIsHeld = YES;
	
	/*
	[mOutputNames removeAllObjects];
	int c = mOutputCount, i;
	for (i = 0; i < c; i++)
		[mOutputNames addObject:[NSString stringWithFormat:@"out%i", i]];
	*/
	
	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
	{
		SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
		[circuit setNumberOfOutputs:mOutputCount];
	}
	
	// as we may have more output than before, we need to allocate them...
	[self prepareForSamplingRate:mSampleRate
			sampleCount:mSampleCount
			precision:mPrecision
			interpolation:mInterpolation];
			
	[self didChangeConnections];
	
	mLockIsHeld = NO;
	[self didChangeAudio];
	
	[self didChangeGlobalView];
}

- (void) reset
{
	[super reset];

	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
	{
		SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
		[circuit reset];
	}
}

- (void) prepareForSamplingRate:(int)samplingRate
			sampleCount:(int)sampleCount
			precision:(SBPrecision)precision
			interpolation:(SBInterpolation)interpolation
{
	[super prepareForSamplingRate:samplingRate
			sampleCount:sampleCount
			precision:precision
			interpolation:interpolation];

	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
	{
		SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
		[circuit prepareForSamplingRate:samplingRate
				sampleCount:sampleCount
				precision:precision
				interpolation:interpolation];
	}
}

- (void) changePrecision:(SBPrecision)precision
{
	[super changePrecision:precision];

	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
	{
		SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
		[circuit changePrecision:precision];
	}
}

- (void) changeInterpolation:(SBInterpolation)interpolation
{
	[super changeInterpolation:interpolation];
	
	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
	{
		SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
		[circuit changeInterpolation:interpolation];
	}
}

- (BOOL) interpolates
{
	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
		if ([[mSubCircuits objectAtIndex:i] interpolates])
			return YES;

	return NO;
}

- (BOOL) hasFeedback
{
	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
		if ([[mSubCircuits objectAtIndex:i] hasFeedback])
			return YES;

	return NO;
}

- (void) trimDebug
{
	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
		[[mSubCircuits objectAtIndex:i] trimDebug];
}

- (void) setMiniMode:(BOOL)mini
{
	[super setMiniMode:mini];
	
	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
	{
		SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
		[circuit setMiniMode:mini];
	}
}

- (void) setColorsBack:(NSColor*)back contour:(NSColor*)contour front:(NSColor*)front
{
	[super	setColorsBack:back
			contour:contour
			front:front];
					
	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
	{
		SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
		[circuit	setColorsBack:back
					contour:contour
					front:front];
	}
}


- (void) setLastCircuit:(BOOL)isLastCircuit
{
	[super setLastCircuit:isLastCircuit];
	
	int c = [mSubCircuits count], i;
	for (i = 0; i < c; i++)
	{
		SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
		[circuit setLastCircuit:isLastCircuit];
	}
}


/*
		min		max
row 0:	-inf	0
row 1:	0		1
row 2:	1		+inf

mRanges: c = 2, values = 0, 1
*/

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [mRanges count] + 1;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	if ([identifier isEqual:@"max"])
	{
		int c = [mRanges count];
		if (rowIndex >= c) return @"+inf";
		else return [mRanges objectAtIndex:rowIndex];
	}
	else if ([identifier isEqual:@"min"])
	{
		if (rowIndex == 0) return @"-inf";
		else return [mRanges objectAtIndex:rowIndex - 1];
	}
	else // row
	{
		return [NSNumber numberWithInt:rowIndex];
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	if ([identifier isEqual:@"min"])
	{
		if (rowIndex == 0) return; // -inf is not user definable
		else
		{
			NSNumber *n = nil;
			if ([anObject isKindOfClass:[NSNumber class]]) n = anObject;
			else if ([anObject isKindOfClass:[NSString class]]) n = [NSNumber numberWithDouble:[anObject doubleValue]];
			if (!n) return;
			
			double val = [n doubleValue];
			if (isinf(val) || isnan(val))
				n = [NSNumber numberWithDouble:0.];
			
			[mRanges replaceObjectAtIndex:rowIndex - 1 withObject:n];
			[self sortRanges];
			[mRangesTableView reloadData];
		}
	}
	return;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int i = [mRangesTableView selectedRow];
	[mRangeDelete setEnabled:(i != 0)];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	
	if (![identifier isEqual:@"min"] || rowIndex == 0)
		return NO;
	
	return YES;
}

// load/save routines
- (NSMutableDictionary*) saveData
{
	int i, c;
	NSNumber *n;
	NSDictionary *d;
	NSMutableArray *ma;
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:mRanges forKey:@"ranges"];
	
	ma = [[NSMutableArray alloc] init];
		c = [mSubCircuits count];
		for (i = 0; i < c; i++)
		{
			SBCircuit *circuit = [mSubCircuits objectAtIndex:i];
			
			d = [circuit saveData];
			
			if (d) [ma addObject:d];
			else [ma addObject:[NSDictionary dictionary]];
		}
	[md setObject:ma forKey:@"subCircuits"];
	[ma release];
	
	n = [NSNumber numberWithInt:mInputCount];
	[md setObject:n forKey:@"inputCount"];
		
	n = [NSNumber numberWithInt:mOutputCount];
	[md setObject:n forKey:@"outputCount"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	if (!data) return NO;

	int c1, c2, i;
	NSArray *a1, *a2;
	NSNumber *n;
	
	[mSubCircuits removeAllObjects];
	
	n = [data objectForKey:@"inputCount"];
	if (n) mInputCount = [n intValue];
	
	n = [data objectForKey:@"outputCount"];
	if (n) mOutputCount = [n intValue];
	
	a1 = [data objectForKey:@"ranges"];
	a2 = [data objectForKey:@"subCircuits"];
	if (a1 && a2)
	{
		c1 = [a1 count];
		c2 = [a2 count];
		if (c1 + 1 == c2)
		{
			for (i = 0; i < c1; i++)
				[mRanges addObject:[NSNumber numberWithDouble:[[a1 objectAtIndex:i] doubleValue]]];

			for (i = 0; i < c2; i++)
			{
				SBCircuit *c = [[SBCircuit alloc] init];
				[c loadData:[a2 objectAtIndex:i]];
				[mSubCircuits addObject:c];
				[c release];
			}
		}
	}
	
	if ([mSubCircuits count] == 0)
	{
		SBCircuit *c = [[SBCircuit alloc] init];
		[mSubCircuits addObject:c];
		[c release];
	}
	
	[self sortRanges];
	[self updateSubCircuitsForInputs];
	[self updateSubCircuitsForOutputs];
	
	return YES;
}

- (void) subElementWillChangeAudio:(NSNotification *)notification
{
	if (!mLockIsHeld) [self willChangeAudio];
}

- (void) subElementDidChangeAudio:(NSNotification *)notification
{
	if (!mLockIsHeld) [self didChangeAudio];
}

- (void) subElementDidChangeConnections:(NSNotification *)notification
{
	if (mUpdatingTypes) return;
	mUpdatingTypes = YES;
	mLockIsHeld = YES;

	SBCircuit *cir = (SBCircuit *)[notification object];
	int i, c = [mSubCircuits count];
	for (i = 0; i < c; i++)
	{
		SBCircuit *cir2 = [mSubCircuits objectAtIndex:i];
		if (cir != cir2)
		{
			int j;
		
			int inputs = [cir numberOfInputs];
			for (j = 0; j < inputs; j++)
				[cir2 changeInputType:j newType:[cir typeOfInputAtIndex:j]];
			
			int outputs = [cir numberOfOutputs];
			for (j = 0; j < outputs; j++)
				[cir2 changeOutputType:j newType:[cir typeOfOutputAtIndex:j]];
		}
	}
	
	// lock is currently held
	[self didChangeConnections];

	mLockIsHeld = NO;
	mUpdatingTypes = NO;
}

- (void) subElementDidChangeName:(NSNotification *)notification
{
	if (mUpdatingNames) return;
	mUpdatingNames = YES;

	SBCircuit *cir = (SBCircuit *)[notification object];
	int i, c = [mSubCircuits count];
	for (i = 0; i < c; i++)
	{
		SBCircuit *cir2 = [mSubCircuits objectAtIndex:i];
		if (cir != cir2)
		{
			int j;
		
			int inputs = [cir numberOfInputs];
			for (j = 0; j < inputs; j++)
				[cir2 changeInputName:j newName:[cir nameOfInputAtIndex:j]];
			
			int outputs = [cir numberOfOutputs];
			for (j = 0; j < outputs; j++)
				[cir2 changeOutputName:j newName:[cir nameOfOutputAtIndex:j]];
		}
	}
	
	mUpdatingNames = NO;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx <= 0) return kNormal;
	else return [[mSubCircuits objectAtIndex:0] typeOfInputAtIndex:idx - 1];
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	return [[mSubCircuits objectAtIndex:0] typeOfOutputAtIndex:idx];
}

@end
