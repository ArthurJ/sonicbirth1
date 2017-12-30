/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCircuit.h"
#import "SBElementServer.h"
#import "SBRootCircuit.h"
#import "SBRootCircuitMidi.h"
#import "SBRootCircuitPrecision.h"
#import "SBRootCircuitInterpolation.h"
#import "SBConstant.h"

#define kCircuitMinSize (400)

#import "SBFeedback.h"

#import "SBPreferenceServer.h"

#import "SBSelectionList.h"

NSString *kSBCircuitDidChangeMinSizeNotification = @"kSBCircuitDidChangeMinSizeNotification";
NSString *kSBCircuitDidChangeNameNotification = @"kSBCircuitDidChangeNameNotification";
NSString *kSBCircuitDidChangeArgumentCountNotification = @"kSBCircuitDidChangeArgumentCountNotification";

static inline BOOL pointInsideRect(float x, float y, NSRect r)
{
	return	(	(x >= r.origin.x)
			&&	(x <= (r.origin.x + r.size.width))
			&&	(y >= r.origin.y)
			&&	(y <= (r.origin.y + r.size.height)));
}

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBCircuit *obj = inObj;
	SBCircuit *objc = inObj;

	if (!obj->mIsCompiled) [objc compile];
	
	int i, j, cw, ce;
	
	// update buffer feeding on circuit input
	cw = obj->mCachedWireBufferUpdateCount;
	WireBufferUpdate *cachedWireBufferUpdate = obj->mCachedWireBufferUpdate;
	

	// execute elements
	ce = obj->mCachedCompiledArrayCount;
	SBElement **cachedCompiledArray = obj->mCachedCompiledArray;
	for (i = 0; i < ce; i++)
	{
		SBElement *ele = cachedCompiledArray[i];
		
		for (j = 0; j < cw; j++)
		{
			SBElement *ie = cachedWireBufferUpdate[j].inputElement;
			SBCircuit *oe = (SBCircuit *)cachedWireBufferUpdate[j].outputElement;
			if (ie == ele)
			{
				// input element connected to a variable output element
				if (oe == objc)
					// connected to ourself, pass on our input
					ie->pInputBuffers[(cachedWireBufferUpdate[j].inputIndex)] = 
					oe->pInputBuffers[(cachedWireBufferUpdate[j].outputIndex)];
				else
					// connected to a variable element output, pass its output
					ie->pInputBuffers[(cachedWireBufferUpdate[j].inputIndex)] = 
					oe->pOutputBuffers[(cachedWireBufferUpdate[j].outputIndex)];
			}
		}

		(ele->pCalcFunc)(ele, count, offset);
	}
	if (obj->mLastCircuit)
	{
		for (i = 0; i < ce; i++)
		{
			SBElement *ele = cachedCompiledArray[i];
			if (ele->pFinishFunc)
				(ele->pFinishFunc)(ele, count, offset);
		}
	}
	
	// update circuit outputs
	for (i = 0; i < cw; i++)
	{
		SBElement *ie = cachedWireBufferUpdate[i].inputElement;
		SBCircuit *oe = (SBCircuit *)cachedWireBufferUpdate[i].outputElement;
		if (ie == objc)
		{
			if (oe == objc)
				obj->pOutputBuffers[(cachedWireBufferUpdate[i].inputIndex)] = 
				oe->pInputBuffers[(cachedWireBufferUpdate[i].outputIndex)];
			else
				obj->pOutputBuffers[(cachedWireBufferUpdate[i].inputIndex)] = 
				oe->pOutputBuffers[(cachedWireBufferUpdate[i].outputIndex)];
		}
	}
	
}

@implementation SBCircuit

+ (SBElementCategory) category
{
	return kMisc;
}

+ (NSString*) name
{
	return @"Circuit";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		mCanChangeNumberOfInputsOutputs = YES;
		mCanChangeInputsOutputsTypes = YES;
		
		mSharingArguments = NO;
		mIsCompiled = NO;
		mHasFeedback = NO;
		mConstantRefresh = NO;
		mSilence.ptr = nil;
		mWiresBehind = NO;
		
		mCachedCompiledArray = nil;
		mCachedWireBufferUpdate = nil;
	
		mCompiledArray = [[NSMutableArray alloc] init];
		if (!mCompiledArray)
		{
			[self release];
			return nil;
		}
	
		mWireArray = [[NSMutableArray alloc] init];
		if (!mWireArray)
		{
			[self release];
			return nil;
		}
		
		mArgumentArray = [[NSMutableArray alloc] init];
		if (!mArgumentArray)
		{
			[self release];
			return nil;
		}
		
		mMidiArgumentArray = [[NSMutableArray alloc] init];
		if (!mMidiArgumentArray)
		{
			[self release];
			return nil;
		}
		
		mElementArray = [[NSMutableArray alloc] init];
		if (!mElementArray)
		{
			[self release];
			return nil;
		}

		mInformations = [[NSMutableString alloc] initWithString:@"A circuit inside another."];
		if (!mInformations)
		{
			[self release];
			return nil;
		}
				
		mName = [[NSMutableString alloc] initWithString:@"circuit"];
		if (!mName)
		{
			[self release];
			return nil;
		}
		
		mSelectedList = [[SBSelectionList alloc] init];
		if (!mSelectedList)
		{
			[self release];
			return nil;
		}
		[mSelectedList setWireArray:mWireArray];
		
		mActsAsCircuit = NO;
		mCircuitSize.width = kCircuitMinSize;
		mCircuitSize.height = kCircuitMinSize;
		mCircuitMinSize.width = kCircuitMinSize;
		mCircuitMinSize.height = kCircuitMinSize;
		
		mSettingsView = nil;
		
		int i;
		for (i = 0; i < kMaxChannels; i++)
		{
			mInputTypes[i] = kNormal;
			mOutputTypes[i] = kNormal;
		}
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];

	if (mSilence.ptr) free(mSilence.ptr);

	if (mCompiledArray) [mCompiledArray release];

	if (mSelectedList) [mSelectedList release]; // release before wire array
	if (mWireArray) [mWireArray release];
	if (mMidiArgumentArray) [mMidiArgumentArray release];
	if (mArgumentArray) [mArgumentArray release];
	if (mElementArray) [mElementArray release];
	
	if (mInformations) [mInformations release];
	if (mName) [mName release];
	
	if (mCachedCompiledArray) free(mCachedCompiledArray);
	if (mCachedWireBufferUpdate) free(mCachedWireBufferUpdate);
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}


- (void) reset
{
	mCurPos = mSampleRate * 2;

	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		[[mElementArray objectAtIndex:i] reset];
}

- (BOOL) interpolates
{
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		if ([[mElementArray objectAtIndex:i] interpolates])
			return YES;

	return NO;
}

- (void) changeInterpolation:(SBInterpolation)interpolation
{
	mInterpolation = interpolation;
	
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		[[mElementArray objectAtIndex:i] changeInterpolation:interpolation];
}


- (void) changePrecision:(SBPrecision)precision
{
	mPrecision = precision;

	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		[[mElementArray objectAtIndex:i] changePrecision:precision];
}


- (void) prepareForSamplingRate:(int)samplingRate
			sampleCount:(int)sampleCount
			precision:(SBPrecision)precision
			interpolation:(SBInterpolation)interpolation
{
	int oSampleCount = mSampleCount;

	mCurPos = mSampleRate * 2;

	if (oSampleCount != sampleCount)
	{
		if (mSilence.ptr) free(mSilence.ptr);

		int size = sampleCount * sizeof(double);
		if (size < sizeof(SBPointsBuffer)) size = sizeof(SBPointsBuffer);
		
		mSilence.ptr = malloc(size);
		assert(mSilence.ptr);
		memset(mSilence.ptr, 0, size);
	}
	
	mSampleCount = sampleCount;
	mPrecision = precision;
	mSampleRate = samplingRate;
	mInterpolation = interpolation;
	
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		[[mElementArray objectAtIndex:i]	prepareForSamplingRate:samplingRate
											sampleCount:sampleCount
											precision:precision
											interpolation:interpolation];
	
	// always compile - buffers may have changed!
	[self compile];
	
	// force view redraw
	[self didChangeGlobalView];
}

- (void) compileForElement:(SBElement*)e
{
	if (e == self) return;
	
	NSUInteger idx;
	
	idx = [mCompiledArray indexOfObjectIdenticalTo:e];
	if (idx != NSNotFound) return;
	
	if ([e isKindOfClass:[SBFeedback class]])
		mHasFeedback = YES;

	int inputs = [e numberOfInputs];
	int i;
	
	[mCompiledArray addObject:e];
	
	for (i = 0; i < inputs; i++)
	{
		SBWire *w = [self wireForInputElement:e inputIndex:i];
		if (w)
			[self compileForElement:[w outputElement]];
	}
	
	[mCompiledArray removeObject:e];
	
	for (i = 0; i < inputs; i++)
	{
		SBWire *w = [self wireForInputElement:e inputIndex:i];
		if (w)
		{
			SBElement *src = [w outputElement];
			if (src == self)
				e->pInputBuffers[i] = mSilence; // will be replaced
			else
				e->pInputBuffers[i] = [src outputAtIndex:[w outputIndex]];
		}
		else
			e->pInputBuffers[i] = mSilence;
	}
	
	[mCompiledArray addObject:e];
}


- (void) compile
{
	[mCompiledArray removeAllObjects];
	
	int outputs = [self numberOfOutputs];
	int i, c;
	
	mNumberOfOutputs = outputs;
	
	// ----------------------------------------------------------
	// Calculate input for self
	// ----------------------------------------------------------
	for (i = 0; i < outputs; i++)
	{
		SBWire *w = [self wireForInputElement:self inputIndex:i];
		if (w)
			[self compileForElement:[w outputElement]];

	}
	
	// ----------------------------------------------------------
	// Compile alwaysExecute elements
	// ----------------------------------------------------------
	c = [mElementArray count];
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mElementArray objectAtIndex:i];
		if ([e alwaysExecute])
			[self compileForElement:e];
	}
	
	// ----------------------------------------------------------
	// Remove shared arguments
	// ----------------------------------------------------------
	if (mSharingArguments)
	{
		c = [mCompiledArray count];
		for (i = 0; i < c; i++)
		{
			SBElement *e = [mCompiledArray objectAtIndex:i];
			
			if ([e isKindOfClass:[SBArgument class]])
			{
				SBArgument *a = (SBArgument*)e;
				if (![a executeEvenIfShared])
				{
					[mCompiledArray removeObjectAtIndex:i];
					i--; c--;
				}
			}
		}
	}
	
	// ----------------------------------------------------------
	// Check for constant refresh
	// ----------------------------------------------------------
	mConstantRefresh = NO;
	c = [mCompiledArray count];
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mCompiledArray objectAtIndex:i];
		if ([e constantRefresh])
		{
			mConstantRefresh = YES;
			break;
		}
	}
//	NSLog(@"circuit %p constant refresh = %s", self, mConstantRefresh ? "yes" : "no");
	
	// ----------------------------------------------------------
	// Cache outputs
	// ----------------------------------------------------------
	for (i = 0; i < outputs; i++)
		pOutputBuffers[i] = [self intOutputAtIndex:i];
		
	// ----------------------------------------------------------
	// Cache arrays
	// ----------------------------------------------------------
	if (mCachedCompiledArray) free(mCachedCompiledArray);
	if (mCachedWireBufferUpdate) free(mCachedWireBufferUpdate);
	
	// cache mCompiledArray first
	c = [mCompiledArray count];
	mCachedCompiledArray = malloc(c * sizeof(SBElement*)); assert(mCachedCompiledArray);
	mCachedCompiledArrayCount = c;
	
	for (i = 0; i < c; i++) mCachedCompiledArray[i] = [mCompiledArray objectAtIndex:i];
	
	// cache mWireArray needed update
	// count them first
	int cw = 0;
	c = [mWireArray count];
	for (i = 0; i < c; i++)
	{
		SBWire *w = [mWireArray objectAtIndex:i];
		SBElement *oe = [w outputElement];
		if ([oe isKindOfClass:[SBCircuit class]]) cw++;
	}
	
	// then cache them
	mCachedWireBufferUpdate = malloc(cw * sizeof(WireBufferUpdate)); assert(mCachedWireBufferUpdate);
	mCachedWireBufferUpdateCount = cw;
	
	cw = 0;
	for (i = 0; i < c; i++)
	{
		SBWire *w = [mWireArray objectAtIndex:i];
		SBElement *oe = [w outputElement], *ie = [w inputElement];
		if ([oe isKindOfClass:[SBCircuit class]])
		{
			mCachedWireBufferUpdate[cw].inputElement = ie;
			mCachedWireBufferUpdate[cw].outputElement = oe;
			mCachedWireBufferUpdate[cw].inputIndex = [w inputIndex];
			mCachedWireBufferUpdate[cw].outputIndex = [w outputIndex];
			cw++;
		}
	}

	mIsCompiled = YES;
}

- (SBBuffer) intOutputAtIndex:(int)idx
{
	SBWire *w = [self wireForInputElement:self inputIndex:idx];
	if (w)
	{
		SBElement *src = [w outputElement];
		if (src == self)
			return pInputBuffers[[w outputIndex]];
		else
			return [src outputAtIndex:[w outputIndex]];
	}
	else
		return mSilence;
}

- (SBBuffer) outputAtIndex:(int)idx
{
	return pOutputBuffers[idx];
}

- (SBCircuit*)subCircuit
{
	return self;
}


- (NSString*) name
{
	return mName;
}

- (void) setName:(NSString*)name
{
	[mName setString:name];
}

- (NSString*) informations
{
	return mInformations;
}

- (void) setInformations:(NSString*)informations
{
	[mInformations setString:informations];
}

- (void) setNumberOfInputs:(int)count
{
	if (count < 0) count = 0;
	if (count > kMaxChannels) count = kMaxChannels;

	[self willChangeAudio];
	
	int oldCount = [mInputNames count], i;
	
	if (count > oldCount)
	{
		for (i = oldCount; i < count; i++)
		{
			NSString *str = [NSString stringWithFormat:@"Channel %i", i];
			[mInputNames addObject:str];
		}
	}
	else
	{
		while(oldCount > count)
		{
			[mInputNames removeLastObject];
			oldCount--;
		}
		
		int max = [self numberOfInputs];
		int c = [mWireArray count];
		for (i = 0; i < c; i++)
		{
			SBWire *wire = [mWireArray objectAtIndex:i];
			if (([wire outputElement] == self) && ([wire outputIndex] >= max))
			{
				[mWireArray removeObject:wire]; mIsCompiled = NO;
				i--; c--;
			}
		}
	}
	
	[self didChangeConnections];
	[self didChangeAudio];
	[self didChangeGlobalView];
	
	if (mInoutTable) [mInoutTable reloadData];
}

- (void) setNumberOfOutputs:(int)count
{
	if (count < 0) count = 0;
	if (count > kMaxChannels) count = kMaxChannels;

	[self willChangeAudio];
	
	int oldCount = [mOutputNames count], i;
	
	if (count > oldCount)
	{
		for (i = oldCount; i < count; i++)
		{
			NSString *str = [NSString stringWithFormat:@"Channel %i", i];
			[mOutputNames addObject:str];
		}
	}
	else
	{
		while(oldCount > count)
		{
			int cindex = oldCount - 1;
			int c = [mWireArray count];
			for (i = 0; i < c; i++)
			{
				SBWire *wire = [mWireArray objectAtIndex:i];
				if (([wire inputElement] == self) && ([wire inputIndex] == cindex))
				{
					[mWireArray removeObject:wire];
					i--; c--;
				}
			}
			[mOutputNames removeObjectAtIndex:cindex];
			oldCount--;
		}
	}
	
	mIsCompiled = NO;
	
	[self didChangeConnections];
	[self didChangeAudio];
	[self didChangeGlobalView];
	
	if (mInoutTable) [mInoutTable reloadData];
}

- (int) numberOfArguments
{
	return [mArgumentArray count];
}

- (SBArgument*) argumentAtIndex:(int)idx
{
	if (idx < 0) return nil;
	if (idx >= [mArgumentArray count]) return nil;
	return [mArgumentArray objectAtIndex:idx];
}

- (int) numberOfMidiArguments
{
	return [mMidiArgumentArray count];
}
- (SBMidiArgument*) midiArgumentAtIndex:(int)idx
{
	if (idx < 0) return nil;
	if (idx >= [mMidiArgumentArray count]) return nil;
	return [mMidiArgumentArray objectAtIndex:idx];
}

- (int) numberOfWires
{
	return [mWireArray count];
}

- (SBWire*) wireAtIndex:(int)idx
{
	if (idx < 0) return nil;
	if (idx >= [mWireArray count]) return nil;
	return [mWireArray objectAtIndex:idx];
}

- (SBWire*) wireForInputElement:(SBElement*)e inputIndex:(int)idx
{
	int c = [mWireArray count], i;
	for (i = 0; i < c; i++)
	{
		SBWire *w = [mWireArray objectAtIndex:i];
		if (([w inputElement] == e) && ([w inputIndex] == idx))
			return w;
	}
	return nil;
}

- (int) numberOfElements
{
	return [mElementArray count];
}

- (SBElement*) elementAtIndex:(int)idx
{
	if (idx < 0) return nil;
	if (idx >= [mElementArray count]) return nil;
	return [mElementArray objectAtIndex:idx];
}

- (BOOL) checkCircularForElement:(SBElement*)e pastElements:(NSMutableArray*)past
{
	if (e == self) return NO;
	
	NSUInteger idx = [past indexOfObjectIdenticalTo:e];
	if (idx != NSNotFound)
	{
		// found a loop
		// if there's a feedback box in it, it's ok
		// otherwise, we're circular
		
		int c = [past count], i;
		for (i = idx; i < c; i++)
		{
			SBElement *ele = [past objectAtIndex:i];
			if ([ele isKindOfClass:[SBFeedback class]])
				return NO;
		}

		return YES;
	}
		
	[past addObject:e];
	
	int inputs = [e numberOfInputs], i;
	for (i = 0; i < inputs; i++)
	{
		SBWire *w = [self wireForInputElement:e inputIndex:i];
		if (w)
		{
			if ([self checkCircularForElement:[w outputElement] pastElements:past])
				return YES;
		}
	}
	
	[past removeObject:e];

	return NO;
}

- (BOOL) isCircular
{
	/*
	#warning "not working!"
	
	int outputs = [self numberOfOutputs], i;
	
	for (i = 0; i < outputs; i++)
	{
		[ma removeAllObjects];
		
		SBWire *w = [self wireForInputElement:self inputIndex:i];
		if (w)
		{
			if ([self checkCircularForElement:[w outputElement] pastElements:ma])
			{
				[ma release];
				return YES;
			}
		}
	}
	*/
	
	NSMutableArray *ma = [[NSMutableArray alloc] init];
	
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
	{
		if (i) [ma removeAllObjects];
		
		if ([self checkCircularForElement:[mElementArray objectAtIndex:i] pastElements:ma])
		{
			[ma release];
			return YES;
		}
	}
	
	[ma release];
	return NO;
}

- (BOOL) hasFeedback
{
	if (!mIsCompiled)
	{
		// when this is called, the lock is either held
		// or not needed...
		
		//[self willChangeAudio];
		[self compile];
		//[self didChangeAudio];
	
	}
	
	return mHasFeedback;
}

- (void) addElement:(SBElement*)element
{
	if (!element) return;
	BOOL addedArgument = NO;
	
	// don't add rootCircuit specifics into a normal circuit
	// insert dummy elements in place of
	// so that wire index works
	// they'll be removed at the end of loadData
	if (![self isKindOfClass:[SBRootCircuit class]])
	{
		if (	[element isKindOfClass:[SBRootCircuitMidi class]]
			||	[element isKindOfClass:[SBRootCircuitPrecision class]]
			||	[element isKindOfClass:[SBRootCircuitInterpolation class]] )
			
			element = [[[SBElement alloc] init] autorelease];
	}

	[element setMiniMode:mMiniMode];

	[element	prepareForSamplingRate:mSampleRate
				sampleCount:mSampleCount
				precision:mPrecision
				interpolation:mInterpolation];
				
	[element	setColorsBack:mColorBack
				contour:mColorContour
				front:mColorFront];
				
	[mElementArray addObject:element];
	[self unsuperposeElements];
	
	if ([element isKindOfClass:[SBArgument class]])
	{
		if (!mLoadingData) addedArgument = YES;
		[mArgumentArray addObject:element];
	}
	
	if ([element isKindOfClass:[SBMidiArgument class]])
		[mMidiArgumentArray addObject:element];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(subElementWillChangeAudio:)
					name:kSBElementWillChangeAudioNotification
					object:element];
					
	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(subElementDidChangeAudio:)
					name:kSBElementDidChangeAudioNotification
					object:element];
					
	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(subElementDidChangeView:)
					name:kSBElementDidChangeViewNotification
					object:element];
					
	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(subElementDidChangeGlobalView:)
					name:kSBElementDidChangeGlobalViewNotification
					object:element];
					
	[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(subElementDidChangeConnections:)
					name:kSBElementDidChangeConnectionsNotification
					object:element];
					
	if ([element isKindOfClass:[SBRootCircuitPrecision class]])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangePrecision:)
						name:kSBRootCircuitPrecisionChangeNotification
						object:element];
	}
	else if ([element isKindOfClass:[SBRootCircuitInterpolation class]])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(subElementDidChangeInterpolation:)
						name:kSBRootCircuitInterpolationChangeNotification
						object:element];
	}


	[mSelectedList setElement:element];
	
	if (addedArgument)
		[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBCircuitDidChangeArgumentCountNotification object:self];
			
	[self willChangeAudio];
	[self compile];
	[self didChangeAudio];
}

- (void) removeElement:(SBElement*)element
{
	if (!element) return;
	BOOL erasedArgument = NO;

	[mSelectedList removeElement:element];

	int c = [mWireArray count], i;
	for (i = 0; i < c; i++)
	{
		SBWire *wire = [mWireArray objectAtIndex:i];
		if ([wire isConnectedToElement:element])
		{
			[self removeWire:wire];
			i--; c--;
		}
	}
	
	if ([element isKindOfClass:[SBArgument class]])
	{
		erasedArgument = YES;
		[mArgumentArray removeObject:element];
	}
	
	if ([element isKindOfClass:[SBMidiArgument class]])
		[mMidiArgumentArray removeObject:element];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
											name:nil
											object:element];

	[mElementArray removeObject:element];
	
	if (erasedArgument)
		[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBCircuitDidChangeArgumentCountNotification object:self];
			
	[self willChangeAudio];
	[self compile];
	[self didChangeAudio];
}

- (void) addWire:(SBWire*)wire
{

	SBElement *inelement = [wire inputElement], *outelement = [wire outputElement];
	int inputs = (inelement == self) ? [self numberOfOutputs] : [inelement numberOfInputs];
	int outputs = (outelement == self) ? [self numberOfInputs] : [outelement numberOfOutputs];
	int inputIndex = [wire inputIndex];
	int outputIndex = [wire outputIndex];
	SBConnectionType inputType = (inelement == self) ? [inelement typeOfOutputAtIndex:inputIndex] : [inelement typeOfInputAtIndex:inputIndex];
	SBConnectionType outputType = (outelement == self) ? [outelement typeOfInputAtIndex:outputIndex] : [outelement typeOfOutputAtIndex:outputIndex];

	
	if (	(inputIndex < 0)
		||	(outputIndex < 0)
		||	(inputs	<= inputIndex)
		||	(outputs <= outputIndex)
		||	(inputType != outputType)
		||	([self  wireForInputElement:inelement inputIndex:inputIndex] != nil)	)
		
		return;

	[self willChangeAudio];
		mIsCompiled = NO;
		[mWireArray addObject:wire];
		if ([self isCircular])
			[mWireArray removeObject:wire];
	[self didChangeAudio];
}

- (void) removeWire:(SBWire*)wire
{
	[self willChangeAudio];
		mIsCompiled = NO;
		[mWireArray removeObject:wire];
	[self didChangeAudio];
}

- (void) drawRect:(NSRect)rect
{
	if (!mActsAsCircuit) { [super drawRect:rect]; return; }
	
	NSRect r = {{0.f, 0.f}, mCircuitSize};
	
	//[[NSColor blackColor] set];
	ogSetColorIndex(ogBlack);
	
	//[NSBezierPath strokeRect:r];
	ogStrokeRectangle(r.origin.x, r.origin.y, r.size.width, r.size.height);
	
	if (mGuiMode != kCircuitDesign)
	{
		if (mGuiMode == kGuiDesign && gShowGuiDesignGrid)
		{
			//NSGraphicsContext *gc = [NSGraphicsContext currentContext];
			//BOOL aliased = [gc shouldAntialias];
			//[gc setShouldAntialias:NO];
		
			//[[NSColor grayColor] set];
			ogSetColorIndex(ogGray);
			
			NSRect bd = r;
			
			NSPoint up = { bd.origin.x, bd.origin.y };
			NSPoint dn = { bd.origin.x, bd.origin.y + bd.size.height };
			float max = bd.origin.x + bd.size.width;
			
			while(up.x < max)
			{
				//[NSBezierPath strokeLineFromPoint:up toPoint:dn];
				ogStrokeLine(up.x, up.y, dn.x, dn.y);
				
				up.x += 8;
				dn.x += 8;
			}
			
			NSPoint lPoint = { bd.origin.x, bd.origin.y };
			NSPoint rPoint = { bd.origin.x + bd.size.width, bd.origin.y };
			max = bd.origin.y + bd.size.height;
			
			while(lPoint.y < max)
			{
				//[NSBezierPath strokeLineFromPoint:l toPoint:r];
				ogStrokeLine(lPoint.x, lPoint.y, rPoint.x, rPoint.y);
				
				lPoint.y += 8;
				rPoint.y += 8;
			}
			
			//[[NSColor blackColor] set];
			//[gc setShouldAntialias:aliased];
			
			ogSetColorIndex(ogBlack);
		}
	
	
		// draw only arguments
		int c = [mArgumentArray count], i;
		for (i = 0; i < c; i++)
		{
			SBElement *e = [mArgumentArray objectAtIndex:i];
			[e drawRect:rect];
		}
		return;
	}
	
	int c, i;
	
	if (mWiresBehind)
	{
		c = [mWireArray count];
		for (i = 0; i < c; i++)
		{
			SBWire *w = [mWireArray objectAtIndex:i];
			[w drawRect:rect];
		}
	}
	
	c = [mElementArray count];
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mElementArray objectAtIndex:i];
		[e drawRect:rect];
	}
	
	[self drawInputsOutputs:rect];
	
	if (!mWiresBehind)
	{
		c = [mWireArray count];
		for (i = 0; i < c; i++)
		{
			SBWire *w = [mWireArray objectAtIndex:i];
			[w drawRect:rect];
		}
	}

	if (mCreatingWire)
		[mCreatingWire drawRect:rect];
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	return [self mouseDownX:x Y:y clickCount:clickCount flags:0];
}

- (SBWire*) selectedWire
{
	return mSelectedWire;
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount flags:(unsigned int)flags
{
	if (!mActsAsCircuit) return [super mouseDownX:x Y:y clickCount:clickCount];
	

	BOOL command = ((flags & NSCommandKeyMask) != 0);
	BOOL shift = ((flags & NSShiftKeyMask) != 0);
	
//	NSLog(@"command : %i shift : %i flags: %i \n", command, shift, flags);
	
	BOOL multipleSelect = command || shift;
	
	int c, i;
	mMovedElement = NO;
	
	if (mGuiMode != kCircuitDesign)
	{
		if (!multipleSelect)
			[mSelectedList removeAllElements];
		
		c = [mArgumentArray count];
		for (i = c - 1; i >= 0; i--)
		{
			SBElement *e = [mArgumentArray objectAtIndex:i];
			if ([e hitTestX:x Y:y])
			{
				if (!multipleSelect) [mSelectedList setElement:e];
				else [mSelectedList toggleElement:e];
				
				if (mGuiMode == kRuntime)
				{
					BOOL locked = [e mouseDownX:x Y:y clickCount:clickCount];
					if (locked) return YES;
					continue;
				}
				
				return YES;
			}
		}
		
		return YES;
	}
	
	mSelectedWire = nil;

	// select a wire
	{
		c = [mWireArray count];
		for (i = 0; i < c; i++)
		{
			SBWire *w = [mWireArray objectAtIndex:i];
			if ([w hitTestX:x Y:y])
			{
				mSelectedWire = w;
				[w mouseDownX:x Y:y clickCount:clickCount];
				return YES;
			}
		}
	}

	// create a wire/select an element
	{ // check self
		int input = [self inputForX:x Y:y];
		if (input >= 0)
		{
			SBWire *w = [self wireForInputElement:self inputIndex:input];
			if (!w)
			{
				mCreatingWire = [[SBWire alloc] init];
				[mCreatingWire setInputElement:self];
				[mCreatingWire setInputIndex:input];
				[mCreatingWire setOutputX:x Y:y];
			}
			else
			{
				[w retain];
				[self removeWire:w];
				
				mCreatingWire = w;
				[mCreatingWire setInputElement:nil];
				[mCreatingWire setInputX:x Y:y];
			}
			
			return YES;
		}
		
		int output = [self outputForX:x Y:y];
		if (output >= 0)
		{
			mCreatingWire = [[SBWire alloc] init];
			[mCreatingWire setOutputElement:self];
			[mCreatingWire setOutputIndex:output];
			[mCreatingWire setInputX:x Y:y];

			return YES;
		}
	}

	c = [mElementArray count];
	for (i = c - 1; i >= 0; i--)
	{
		SBElement *e = [mElementArray objectAtIndex:i];
		if ([e hitTestX:x Y:y])
		{
			if (!multipleSelect)
			{
				if (![mSelectedList isSelected:e])
					[mSelectedList setElement:e];
			}
			else [mSelectedList toggleElement:e];
			
			int input = [e inputForX:x Y:y];
			if (input >= 0)
			{
				SBWire *w = [self wireForInputElement:e inputIndex:input];
				if (!w)
				{
					mCreatingWire = [[SBWire alloc] init];
					[mCreatingWire setInputElement:e];
					[mCreatingWire setInputIndex:input];
					[mCreatingWire setOutputX:x Y:y];
				}
				else
				{
					[w retain];
					[self removeWire:w];
					
					mCreatingWire = w;
					[mCreatingWire setInputElement:nil];
					[mCreatingWire setInputX:x Y:y];
				}
				
				return YES;
			}
			
			int output = [e outputForX:x Y:y];
			if (output >= 0)
			{
				mCreatingWire = [[SBWire alloc] init];
				[mCreatingWire setOutputElement:e];
				[mCreatingWire setOutputIndex:output];
				[mCreatingWire setInputX:x Y:y];
				
				return YES;
			}
			
			
			[e mouseDownX:x Y:y clickCount:clickCount];
			return YES;
		}
	}

	if ([mSelectedList count] > 0)
	{
		[mSelectedList removeAllElements];
		return YES;
	}
	
	return NO;
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	if (!mActsAsCircuit) return [super mouseDraggedX:x Y:y lastX:lx lastY:ly];
	
	if (mGuiMode != kCircuitDesign)
	{
		if ([mSelectedList count] > 0)
		{
			if (mGuiMode == kRuntime)
				return [[mSelectedList element] mouseDraggedX:x Y:y lastX:lx lastY:ly];

			if ([mSelectedList hitTestX:lx Y:ly])
			{
				[mSelectedList translateElementsDeltaX: x - lx deltaY: y - ly content:YES];
				mMovedElement = YES;
				return YES;
			}
		}
		return NO;
	}

	if (mSelectedWire)
	{
		return [mSelectedWire mouseDraggedX:x Y:y lastX:lx lastY:ly];
	}

	if (mCreatingWire)
	{
		if (![mCreatingWire outputElement])
			[mCreatingWire setOutputX:x Y:y];
		else
			[mCreatingWire setInputX:x Y:y];
		
		return YES;
	}

	if ([mSelectedList count] > 0)
	{
		if ([[mSelectedList element] mouseDraggedX:x Y:y lastX:lx lastY:ly])
			return YES;
	
		if ([mSelectedList hitTestX:lx Y:ly])
		{
			[mSelectedList translateElementsDeltaX: x - lx deltaY: y - ly content:NO];
			mMovedElement = YES;
			return YES;
		}
	}
	return NO;
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	if (!mActsAsCircuit) return [super mouseUpX:x Y:y];
	
	if (mGuiMode != kCircuitDesign)
	{
		if ([mSelectedList count] > 0)
		{
			if (mGuiMode == kRuntime)
				return [[mSelectedList element] mouseUpX:x Y:y];
		}
		return mMovedElement;
	}
	
	if (mMovedElement) [self unsuperposeElements];
	
	if (mCreatingWire)
	{
		if (![mCreatingWire outputElement])
		{
			{ // check self
				int output = [self outputForX:x Y:y];

				if (output >= 0)
				{
					[mCreatingWire setOutputElement:self];
					[mCreatingWire setOutputIndex:output];
					[self addWire:mCreatingWire];
					
					[mCreatingWire release];
					mCreatingWire = nil;
					return YES;
				}
			}

			int c = [mElementArray count], i;
			for (i = c - 1; i >= 0; i--)
			{
				SBElement *e = [mElementArray objectAtIndex:i];
				if ([e hitTestX:x Y:y])
				{
					int output = [e outputForX:x Y:y];

					if (output >= 0)
					{
						[mCreatingWire setOutputElement:e];
						[mCreatingWire setOutputIndex:output];
						[self addWire:mCreatingWire];
					}

					[mCreatingWire release];
					mCreatingWire = nil;

					return YES;
				}
			}
		}
		else
		{
			{ // check self
				int input = [self inputForX:x Y:y];

				if (input >= 0)
				{
					SBWire *w = [self wireForInputElement:self inputIndex:input];
					if (w) [self removeWire:w];
				
					[mCreatingWire setInputElement:self];
					[mCreatingWire setInputIndex:input];
					[self addWire:mCreatingWire];
					
					[mCreatingWire release];
					mCreatingWire = nil;
					return YES;
				}
			}
		
			int c = [mElementArray count], i;
			for (i = c - 1; i >= 0; i--)
			{
				SBElement *e = [mElementArray objectAtIndex:i];
				if ([e hitTestX:x Y:y])
				{
					int input = [e inputForX:x Y:y];

					if (input >= 0)
					{
						SBWire *w = [self wireForInputElement:e inputIndex:input];
						if (w) [self removeWire:w];
					
						[mCreatingWire setInputElement:e];
						[mCreatingWire setInputIndex:input];
						[self addWire:mCreatingWire];
					}

					[mCreatingWire release];
					mCreatingWire = nil;

					return YES;
				}
			}
		}
		
		[mCreatingWire release];
		mCreatingWire = nil;
		return YES;
	}
	
	if (([mSelectedList count] > 0) && [[mSelectedList element] mouseUpX:x Y:y])
		return YES;
	
	return mMovedElement;
}

- (SBElement*) selectedElement
{
	return [mSelectedList element];
}

- (NSArray*) selectedElements
{
	return [mSelectedList elements];
}

- (NSArray*) selectedWires
{
	return [mSelectedList selectedWires];
}

- (void) deselect
{
	[mSelectedList removeAllElements];
}

- (NSSize) circuitSize
{
	return mCircuitSize;
}

- (NSSize) circuitMinSize
{
	return mCircuitMinSize;
}


- (void) setCircuitSize:(NSSize)s
{
	mCircuitSize = s;
	if (mCircuitSize.width < mCircuitMinSize.width) mCircuitSize.width = mCircuitMinSize.width;
	if (mCircuitSize.height < mCircuitMinSize.height) mCircuitSize.height = mCircuitMinSize.height;
}

- (void) setCircuitMinSize:(NSSize)s
{
	mCircuitMinSize = s;
	if (mCircuitMinSize.width < kCircuitMinSize) mCircuitMinSize.width = kCircuitMinSize;
	if (mCircuitMinSize.height < kCircuitMinSize) mCircuitMinSize.height = kCircuitMinSize;
	
	if (mWidthTF) [mWidthTF setFloatValue:mCircuitMinSize.width];
	if (mHeightTF) [mHeightTF setFloatValue:mCircuitMinSize.height];
	
	[self didChangeMinSize];
}

- (void) drawInputsOutputs:(NSRect)rect
{
	int i;
	int inputCount = [self numberOfInputs];
	int outputCount = [self numberOfOutputs];
	
	// beg -- should be updated only when changing number of inputs
	float inputNameWitdh = kNameSpace;
	for (i = 0; i < inputCount; i++)
	{
		NSString *name = [self nameOfInputAtIndex:i];
		float nw = [name sizeWithAttributes:gTextAttributes].width + kNameSpace;
		if (nw > inputNameWitdh) inputNameWitdh = nw;
	}
	
	float outputNameWitdh = kNameSpace;
	for (i = 0; i < outputCount; i++)
	{
		NSString *name = [self nameOfOutputAtIndex:i];
		float nw = [name sizeWithAttributes:gTextAttributes].width + kNameSpace;
		if (nw > outputNameWitdh) outputNameWitdh = nw;
	}
	
	mInputChannelNameWidth = inputNameWitdh;
	mOutputChannelNameWidth = outputNameWitdh;
	// end -- should be updated only when changing number of inputs
	
	int inputHeight = kTextHeight * inputCount;
	int inputWitdh = mInputChannelNameWidth + kSocketWidth;
	int outputHeight = kTextHeight * outputCount;
	int outputWitdh = mOutputChannelNameWidth + kSocketWidth;

	if (inputCount > 0)
	{
		NSRect r;
	
		r.origin.x = 0;
		r.origin.y = 0;
		r.size.width = inputWitdh;
		r.size.height = inputHeight;
		
		//[[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
		ogSetColorComp(0.95f, 0.95f, 0.95f, 1.f);
		
		//[NSBezierPath fillRect:r];
		ogFillRectangle(r.origin.x, r.origin.y, r.size.width, r.size.height);
		
		//[[NSColor blackColor] set];
		ogSetColorIndex(ogBlack);
		
		//[NSBezierPath strokeRect:r];
		ogStrokeRectangle(r.origin.x, r.origin.y, r.size.width, r.size.height);
		
		NSPoint top, bot;
		
		bot.x = top.x = mInputChannelNameWidth;
		top.y = 0;
		bot.y = inputHeight;
		
		//[[NSColor grayColor] set];
		ogSetColorIndex(ogGray);
		
		//[NSBezierPath strokeLineFromPoint:top toPoint:bot];
		ogStrokeLine(top.x, top.y, bot.x, bot.y);
		
		//[[NSColor blackColor] set];
		ogSetColorIndex(ogBlack);
		
		NSPoint lef, rig;
		lef.y = rig.y = 0;
		lef.x = 0;
		rig.x = lef.x + mInputChannelNameWidth + kSocketWidth;
		
		NSRect txtRect;
		txtRect.origin.x = 0;
		txtRect.origin.y = 0;
		txtRect.size.width = mInputChannelNameWidth;
		txtRect.size.height = kTextHeight;
		
		for (i = 0; i < inputCount; i++)
		{
			SBConnectionType type = [self typeOfInputAtIndex:i];
			if (type != kNormal)
			{
				SET_TYPE_COLOR(type)
				
				NSRect oRect = {{rig.x - kSocketWidth + 1, txtRect.origin.y + 1}, {kSocketWidth - 2, kTextHeight - 2}};
				
				//[NSBezierPath fillRect:rect];
				ogFillRectangle(oRect.origin.x, oRect.origin.y, oRect.size.width, oRect.size.height);
			
				//[[NSColor blackColor] set];
				ogSetColorIndex(ogBlack);
			} 
		
			NSString *name = [self nameOfInputAtIndex:i];
			//[name drawInRect:txtRect withAttributes:gTextAttributes];
			ogDrawStringInRect([name UTF8String], txtRect.origin.x, txtRect.origin.y, txtRect.size.width, txtRect.size.height);
			
			lef.y += kTextHeight;
			rig.y += kTextHeight;
			txtRect.origin.y += kTextHeight;
			
			if (i < inputCount - 1)
				//[NSBezierPath strokeLineFromPoint:lef toPoint:rig];
				ogStrokeLine(lef.x, lef.y, rig.x, rig.y);
		}
	}
	
	if (outputCount > 0)
	{
		NSRect r;
	
		r.origin.x = mCircuitSize.width - kSocketWidth - mOutputChannelNameWidth;
		r.origin.y = 0;
		r.size.width = outputWitdh;
		r.size.height = outputHeight;
		
		//[[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
		ogSetColorComp(0.95f, 0.95f, 0.95f, 1.f);
		
		//[NSBezierPath fillRect:r];
		ogFillRectangle(r.origin.x, r.origin.y, r.size.width, r.size.height);
		
		//[[NSColor blackColor] set];
		ogSetColorIndex(ogBlack);
		
		//[NSBezierPath strokeRect:r];
		ogStrokeRectangle(r.origin.x, r.origin.y, r.size.width, r.size.height);
		
		NSPoint top, bot;
		
		bot.x = top.x = mCircuitSize.width - mOutputChannelNameWidth;
		top.y = 0;
		bot.y = outputHeight;
		
		//[[NSColor grayColor] set];
		ogSetColorIndex(ogGray);
		
		//[NSBezierPath strokeLineFromPoint:top toPoint:bot];
		ogStrokeLine(top.x, top.y, bot.x, bot.y);
		
		//[[NSColor blackColor] set];
		ogSetColorIndex(ogBlack);
		
		NSPoint lef, rig;
		lef.y = rig.y = 0;
		lef.x = mCircuitSize.width - kSocketWidth - mOutputChannelNameWidth;
		rig.x = lef.x + mOutputChannelNameWidth + kSocketWidth;
		
		NSRect txtRect;
		txtRect.origin.x = mCircuitSize.width - mOutputChannelNameWidth;
		txtRect.origin.y = 0;
		txtRect.size.width = mOutputChannelNameWidth;
		txtRect.size.height = kTextHeight;
		
		for (i = 0; i < outputCount; i++)
		{
			SBConnectionType type = [self typeOfOutputAtIndex:i];
			if (type != kNormal)
			{
				SET_TYPE_COLOR(type)
				
				NSRect oRect = {{lef.x + 1, txtRect.origin.y + 1}, {kSocketWidth - 2, kTextHeight - 2}};
				//[NSBezierPath fillRect:rect];
				ogFillRectangle(oRect.origin.x, oRect.origin.y, oRect.size.width, oRect.size.height);
			
				//[[NSColor blackColor] set];
				ogSetColorIndex(ogBlack);
			} 
		
			NSString *name = [self nameOfOutputAtIndex:i];
			//[name drawInRect:txtRect withAttributes:gTextAttributes];
			ogDrawStringInRect([name UTF8String], txtRect.origin.x, txtRect.origin.y, txtRect.size.width, txtRect.size.height);
			
			lef.y += kTextHeight;
			rig.y += kTextHeight;
			txtRect.origin.y += kTextHeight;
			
			if (i < outputCount - 1)
				//[NSBezierPath strokeLineFromPoint:lef toPoint:rig];
				ogStrokeLine(lef.x, lef.y, rig.x, rig.y);
		}
	}
}

- (NSRect) rectForInput:(int)idx
{
	if (!mActsAsCircuit) return [super rectForInput:idx];
	
	NSRect r;
	r.origin.x = mCircuitSize.width - kSocketWidth - mOutputChannelNameWidth;
	r.origin.y = idx * kTextHeight;
	r.size.width = kSocketWidth;
	r.size.height = kTextHeight;
	
	return r;
}

- (NSRect) rectForOutput:(int)idx
{
	if (!mActsAsCircuit) return [super rectForOutput:idx];
	
	NSRect r;
	r.origin.x = mInputChannelNameWidth;
	r.origin.y = idx * kTextHeight;
	r.size.width = kSocketWidth;
	r.size.height = kTextHeight;
	
	return r;
}

- (int) inputForX:(int)x Y:(int)y
{
	if (!mActsAsCircuit) return [super inputForX:x Y:y];
	
	int outputs = [self numberOfOutputs];
	if (outputs <= 0) return -1;
	
	if (x < (mCircuitSize.width - kSocketWidth - mOutputChannelNameWidth)) return -1;
	if (x > (mCircuitSize.width - mOutputChannelNameWidth)) return -1;
	if (y < 0) return -1;
	if (y >= ([self numberOfOutputs] * kTextHeight)) return -1;
	
	int p = floor(y / kTextHeight);
	
	if (p < 0 || p >= outputs) return -1; 
	return p;
}

- (int) outputForX:(int)x Y:(int)y
{
	if (!mActsAsCircuit) return [super outputForX:x Y:y];

	int inputs = [self numberOfInputs];
	if (inputs <= 0) return -1;
	
	if (x < mInputChannelNameWidth) return -1;
	if (x > (mInputChannelNameWidth + kSocketWidth)) return -1;
	if (y < 0) return -1;
	if (y >= ([self numberOfInputs] * kTextHeight)) return -1;
	
	int p = floor(y / kTextHeight);
	
	if (p < 0 || p >= inputs) return -1; 
	return p;
}

- (int) inputNameForX:(int)x Y:(int)y
{
	if (!mActsAsCircuit) return -1;
	
	if ([self numberOfInputs] <= 0) return -1;
	
	if (x < 0) return -1;
	if (x > mInputChannelNameWidth) return -1;
	if (y < 0) return -1;
	if (y >= ([self numberOfInputs] * kTextHeight)) return -1;
	
	return floor(y / kTextHeight);
}

- (int) outputNameForX:(int)x Y:(int)y
{
	if (!mActsAsCircuit) return -1;
	
	if ([self numberOfOutputs] <= 0) return -1;
	
	if (x < (mCircuitSize.width - mOutputChannelNameWidth)) return -1;
	if (x > mCircuitSize.width) return -1;
	if (y < 0) return -1;
	if (y >= ([self numberOfOutputs] * kTextHeight)) return -1;
	
	return floor(y / kTextHeight);
}

- (void) changeInputName:(int)idx newName:(NSString*)newName
{
	if (idx < 0) return;
	if (idx >= [self numberOfInputs]) return;
	
	NSString *copy = [newName copy];
	[mInputNames replaceObjectAtIndex:idx withObject:copy];
	[copy release];
	
	[[NSNotificationCenter defaultCenter]
		postNotificationName:kSBCircuitDidChangeNameNotification object:self];
		
	[self didChangeGlobalView];
	
	if (mInoutTable) [mInoutTable reloadData];
}

- (void) changeOutputName:(int)idx newName:(NSString*)newName
{
	if (idx < 0) return;
	if (idx >= [self numberOfOutputs]) return;
	
	NSString *copy = [newName copy];
	[mOutputNames replaceObjectAtIndex:idx withObject:copy];
	[copy release];
	
	[[NSNotificationCenter defaultCenter]
		postNotificationName:kSBCircuitDidChangeNameNotification object:self];
		
	[self didChangeGlobalView];
	
	if (mInoutTable) [mInoutTable reloadData];
}

- (BOOL) keyDown:(unichar)ukey
{
	if (!mActsAsCircuit) return [super keyDown:ukey];
	if ([mSelectedList count] <= 0) return NO;
	
	if ([[mSelectedList element] keyDown:ukey]) return YES;
	
	if ((mGuiMode == kCircuitDesign) && (ukey == NSDeleteFunctionKey || ukey == 0x7F))
	{
		while([mSelectedList count] > 0)
			[self removeElement:[mSelectedList element]];
			
		return YES;
	}
	
	if (mGuiMode == kGuiDesign)
	{
		switch(ukey)
		{
			case NSUpArrowFunctionKey:
			{
				[mSelectedList translateElementsDeltaX:0 deltaY:-1 content:YES];
				return YES;
			}
				
			case NSDownArrowFunctionKey:
			{
				[mSelectedList translateElementsDeltaX:0 deltaY:1 content:YES];
				return YES;
			}
				
			case NSLeftArrowFunctionKey:
			{
				[mSelectedList translateElementsDeltaX:-1 deltaY:0 content:YES];
				return YES;
			}
				
			case NSRightArrowFunctionKey:
			{
				[mSelectedList translateElementsDeltaX:1 deltaY:0 content:YES];
				return YES;
			}
		
			default:
				break;
		}
	}
	return NO;
}

- (void) setActsAsCircuit:(BOOL)a
{
	mActsAsCircuit = a;
	if (!a) mCalculatedFrame = NO;
}

- (void) subElementWillChangeAudio:(NSNotification *)notification
{
	[self willChangeAudio];
}

- (void) subElementDidChangeAudio:(NSNotification *)notification
{
	[self didChangeAudio];
}

- (void) subElementDidChangeView:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBElementDidChangeViewNotification
			object:self
			userInfo:[NSDictionary dictionaryWithObject:[notification object] forKey:@"object"]];
}

- (void) subElementDidChangeGlobalView:(NSNotification *)notification
{
	// sub element probably changed size
	[self unsuperposeElements];
	
	[self didChangeGlobalView];
}


- (void) subElementDidChangeConnections:(NSNotification *)notification
{
	// notification will be nil if called by self

	// element probably changed number of input/outputs
	mIsCompiled = NO;
	
	int c = [mWireArray count], i;
	for (i = 0; i < c; i++)
	{
		SBWire *wire = [mWireArray objectAtIndex:i];
		SBElement *inelement = [wire inputElement], *outelement = [wire outputElement];
		int inputs = (inelement == self) ? [self numberOfOutputs] : [inelement numberOfInputs];
		int outputs = (outelement == self) ? [self numberOfInputs] : [outelement numberOfOutputs];
		int inputIndex = [wire inputIndex];
		int outputIndex = [wire outputIndex];
		SBConnectionType inputType = (inelement == self) ? [inelement typeOfOutputAtIndex:inputIndex] : [inelement typeOfInputAtIndex:inputIndex];
		SBConnectionType outputType = (outelement == self) ? [outelement typeOfInputAtIndex:outputIndex] : [outelement typeOfOutputAtIndex:outputIndex];
		if (	(inputs	<= inputIndex)
			||	(outputs <= outputIndex)
			||	(inputType != outputType)	)
		{
			//[self removeWire:wire]; // lock should currently be held
			[mWireArray removeObject:wire];
			i--; c--;
		}
	}
}

- (void) subElementDidChangePrecision:(NSNotification *)notification
{
	SBRootCircuitPrecision *e = [notification object];
	int mode = [e currentValueForParameter:0];
	[self changePrecision:(mode == 0) ? kFloatPrecision : kDoublePrecision];
}

- (void) subElementDidChangeInterpolation:(NSNotification *)notification
{
	SBRootCircuitInterpolation *e = [notification object];
	int mode = [e currentValueForParameter:0];
	[self changeInterpolation:(mode == 0) ? kNoInterpolation : kInterpolationLinear];
}

- (NSMutableDictionary*) saveData
{
	int c, i;
	NSNumber *n;
	NSDictionary *d;
	NSMutableArray *ma;
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:mInformations forKey:@"informations"];
	[md setObject:mName forKey:@"name"];

	n = [NSNumber numberWithFloat:mCircuitMinSize.width];
	[md setObject:n forKey:@"circuitMinWidth"];
		
	n = [NSNumber numberWithFloat:mCircuitMinSize.height];
	[md setObject:n forKey:@"circuitMinHeight"];
	
	n = [NSNumber numberWithInt:(mWiresBehind) ? 2 : 1];
	[md setObject:n forKey:@"wiresBehind"];
	
	[md setObject:mInputNames forKey:@"inputsNames"];
	[md setObject:mOutputNames forKey:@"outputsNames"];
	
	ma = [[NSMutableArray alloc] init];
		c = [mInputNames count];
		for (i = 0; i < c; i++)
		{
			n = [NSNumber numberWithInt:(int)[self typeOfInputAtIndex:i]];
			[ma addObject:n];
		}
	[md setObject:ma forKey:@"inputsTypes"];
	[ma release];
	
	ma = [[NSMutableArray alloc] init];
		c = [mOutputNames count];
		for (i = 0; i < c; i++)
		{
			n = [NSNumber numberWithInt:(int)[self typeOfOutputAtIndex:i]];
			[ma addObject:n];
		}
	[md setObject:ma forKey:@"outputsTypes"];
	[ma release];
	
	ma = [[NSMutableArray alloc] init];
		c = [mElementArray count];
		for (i = 0; i < c; i++)
		{
			SBElement *e = [mElementArray objectAtIndex:i];
			NSMutableDictionary *mde = [[NSMutableDictionary alloc] init];
			
			NSString *name = [[e className] copy];
				[mde setObject:name forKey:@"class"];
			[name release];
			
			NSPoint dorigin = [e designOrigin];
			
			n = [NSNumber numberWithFloat:dorigin.x];
			[mde setObject:n forKey:@"originX"];
			
			n = [NSNumber numberWithFloat:dorigin.y];
			[mde setObject:n forKey:@"originY"];
			
			if ([e isKindOfClass:[SBArgument class]])
			{
				NSPoint co = [e guiOrigin];
				
				n = [NSNumber numberWithFloat:co.x];
				[mde setObject:n forKey:@"guiOriginX"];
			
				n = [NSNumber numberWithFloat:co.y];
				[mde setObject:n forKey:@"guiOriginY"];
			}
			
			d = [e saveData];
			if (d) [mde setObject:d forKey:@"settings"];
			
			[ma addObject:mde];
			[mde release];
		}
	[md setObject:ma forKey:@"ElementArray"];
	[ma release];
	
	ma = [[NSMutableArray alloc] init];
		c = [mWireArray count];
		for (i = 0; i < c; i++)
		{
			SBWire *w = [mWireArray objectAtIndex:i];
			NSMutableDictionary *mde = [[NSMutableDictionary alloc] init];
		
			n = [NSNumber numberWithInt:[w inputIndex]];
			[mde setObject:n forKey:@"inputIndex"];
			
			n = [NSNumber numberWithInt:[w outputIndex]];
			[mde setObject:n forKey:@"outputIndex"];
			
			NSUInteger idx;
			idx = [mElementArray indexOfObjectIdenticalTo:[w inputElement]];
			if (idx != NSNotFound)
			{
				n = [NSNumber numberWithInt:idx];
				[mde setObject:n forKey:@"inputElement"];
			}
			
			idx = [mElementArray indexOfObjectIdenticalTo:[w outputElement]];
			if (idx != NSNotFound)
			{
				n = [NSNumber numberWithInt:idx];
				[mde setObject:n forKey:@"outputElement"];
			}
			
			d = [w saveData];
			if (d) [mde setObject:d forKey:@"settings"];
			
			[ma addObject:mde];
			[mde release];
		}
	[md setObject:ma forKey:@"WireArray"];
	[ma release];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	if (!data) return NO;
	mIsCompiled = NO;
	
	int c, i;
	NSArray *a;
	NSString *s;
	NSNumber *n;
	NSDictionary *d, *ds;
	
	s = [data objectForKey:@"informations"];
	if (s) [mInformations setString:s];
	
	s = [data objectForKey:@"name"];
	if (s) [mName setString:s];

	n = [data objectForKey:@"circuitMinWidth"];
	if (n) mCircuitMinSize.width = [n floatValue];
	
	n = [data objectForKey:@"circuitMinHeight"];
	if (n) mCircuitMinSize.height = [n floatValue];
	
	n = [data objectForKey:@"wiresBehind"];
	if (n) mWiresBehind = ([n intValue] == 2);
	
	a = [data objectForKey:@"inputsNames"];
	if (a)
	{
		c = [a count];
		[self setNumberOfInputs:c];
		
		for (i = 0; i < c; i++)
			[self changeInputName:i newName:[a objectAtIndex:i]];
	}
	
	a = [data objectForKey:@"outputsNames"];
	if (a)
	{
		c = [a count];
		[self setNumberOfOutputs:c];
		
		for (i = 0; i < c; i++)
			[self changeOutputName:i newName:[a objectAtIndex:i]];
	}
	
	a = [data objectForKey:@"inputsTypes"];
	if (a)
	{
		c = [a count];
		if (c == [self numberOfInputs])
			for (i = 0; i < c; i++)
				[self changeInputType:i newType:(SBConnectionType)[[a objectAtIndex:i] intValue]];
	}
	
	a = [data objectForKey:@"outputsTypes"];
	if (a)
	{
		c = [a count];
		if (c == [self numberOfOutputs])
			for (i = 0; i < c; i++)
				[self changeOutputType:i newType:(SBConnectionType)[[a objectAtIndex:i] intValue]];
	}
	
	a = [data objectForKey:@"ElementArray"];
	if (a)
	{
		c = [a count];
		for (i = 0; i < c; i++)
		{
			d = [a objectAtIndex:i];
			
			s = [d objectForKey:@"class"];
			if (s)
			{
				SBElement *e = [gElementServer createElement:s];
				if (e)
				{
					float x = 100, y = 100;
					n = [d objectForKey:@"originX"];
					if (n)
						x = [n floatValue];
					
					n = [d objectForKey:@"originY"];
					if (n)
						y = [n floatValue];
					
					// since these callback are used during loadData, set them here
					if ([e isKindOfClass:[SBRootCircuitPrecision class]])
					{
						[[NSNotificationCenter defaultCenter] addObserver:self
										selector:@selector(subElementDidChangePrecision:)
										name:kSBRootCircuitPrecisionChangeNotification
										object:e];
					}
					else if ([e isKindOfClass:[SBRootCircuitInterpolation class]])
					{
						[[NSNotificationCenter defaultCenter] addObserver:self
										selector:@selector(subElementDidChangeInterpolation:)
										name:kSBRootCircuitInterpolationChangeNotification
										object:e];
					}
						
					ds = [d objectForKey:@"settings"];
					if (ds) [e loadData:ds];
					
					[e setOriginX:x Y:y];
					
					if ([e isKindOfClass:[SBArgument class]])
					{
 						x = 128; y = 128;
						
						n = [d objectForKey:@"guiOriginX"];
						if (n)
							x = [n floatValue];
							
						n = [d objectForKey:@"guiOriginY"];
						if (n)
							y = [n floatValue];
						
						[e setGuiOriginX:x Y:y]; 
					}
					
					// prevent sending notifications
					mLoadingData = YES;
						[self addElement:e];
					mLoadingData = NO;
				}
				else
					NSLog(@"Bad class name: %@", s);
			}
		}
	}

	NSMutableArray *debugWireArray = nil;
	
	a = [data objectForKey:@"WireArray"];
	if (a)
	{
		c = [a count];
		for (i = 0; i < c; i++)
		{
			d = [a objectAtIndex:i];
			
			NSNumber *n1, *n2, *n3, *n4;
			
			n1 = [d objectForKey:@"inputIndex"];
			n2 = [d objectForKey:@"outputIndex"];
			n3 = [d objectForKey:@"inputElement"];
			n4 = [d objectForKey:@"outputElement"];
			
			ds = [d objectForKey:@"settings"];
			
			if (n1 && n2)
			{
				SBWire *w = [[SBWire alloc] init];
				
				[w setInputIndex:[n1 intValue]];
				[w setOutputIndex:[n2 intValue]];
				
				if (n3)
					[w setInputElement:[self elementAtIndex:[n3 intValue]]];
				else
					[w setInputElement:self];
					
				if (n4)
					[w setOutputElement:[self elementAtIndex:[n4 intValue]]];
				else
					[w setOutputElement:self];
					
				if (ds) [w loadData:ds];
					
				SBElement *wie = [w inputElement];
				SBElement *woe = [w outputElement];
				if (wie && woe)
				{
					
					int inputs = (n3) ? [wie numberOfInputs] : [self numberOfOutputs];
					int outputs = (n4) ? [woe numberOfOutputs] : [self numberOfInputs];
					int ip = [w inputIndex];
					int op = [w outputIndex];
					
					if (ip >= 0 && op >= 0 && ip < inputs && op < outputs
						&& ([self  wireForInputElement:wie inputIndex:ip] == nil))
					{
						[self addWire:w];
					}
					else if (	ip >= 0 && ip < inputs && op == 0 
							&& ([self  wireForInputElement:wie inputIndex:ip] == nil)
							&& [[woe className] isEqual:@"SBDebug"]) // backward compatibility
					{
						if (!debugWireArray)
							debugWireArray = [[NSMutableArray alloc] init];
							
						if (debugWireArray)
							[debugWireArray addObject:w];
							
						[mWireArray addObject:w];
					}
				}
				
				[w release];
			}
		}
	}
	
	// fix debug wires
	if (debugWireArray)
	{
		c = [debugWireArray count];
		for (i = 0; i < c; i++)
		{
			SBWire *w = [debugWireArray objectAtIndex:i];
		
			// find the wire connected to its input
			SBWire *dw = [self wireForInputElement:[w outputElement] inputIndex:0];
			
			// do it recursive
			int maxCount = 100;
			while(dw && [[[dw outputElement] className] isEqual:@"SBDebug"] && maxCount-- > 0)
				dw = [self wireForInputElement:[dw outputElement] inputIndex:0];
			
			if (dw)
			{
				[w setOutputIndex:[dw outputIndex]];
				[w setOutputElement:[dw outputElement]];
			}
			else
				[mWireArray removeObject:w];
		}
		
		[debugWireArray release];
	}
	
	// remove dummy elements that might have been added
	c = [mElementArray count];
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mElementArray objectAtIndex:i];
		if ([e isMemberOfClass:[SBElement class]])
		{
			[self removeElement:e];
			i--; c--;
		}
	}
	
	return YES;
}



- (void) shareArgumentsFrom:(SBCircuit*)circuit shareCount:(int)shareCount
{
	if (circuit == self) return;
	
	NSMutableArray *src = mArgumentArray;
	NSMutableArray *dst = circuit->mArgumentArray;
	
	int c = [src count], i;
	if (c != [dst count]) return;
	
	for (i = 0; i < c; i++)
	{
		SBArgument *sa = [src objectAtIndex:i];
		SBArgument *da = [dst objectAtIndex:i];
		
		if (![[sa className] isEqual:[da className]]) return;
		if (![[sa name] isEqual:[da name]]) return;
	}
	
	int ce = [mElementArray count], cw = [mWireArray count], cm = [mMidiArgumentArray count];
	for (i = 0; i < c; i++)
	{
		SBArgument *sa = [src objectAtIndex:i];
		SBArgument *da = [dst objectAtIndex:i];
		
		if ([sa selfManagesSharingArgumentFrom:da shareCount:shareCount]) // argument will do its own housekeeping?
			continue;
		
		int j;
		for (j = 0; j < cw; j++)
		{
			SBWire *w = [mWireArray objectAtIndex:j];
			
			if ([w inputElement] == sa) [w setInputElement:da];
			if ([w outputElement] == sa) [w setOutputElement:da];
		}
		
		for (j = 0; j < ce; j++)
		{
			SBElement *e = [mElementArray objectAtIndex:j];
			
			if (e == sa)
				[mElementArray replaceObjectAtIndex:j withObject:da];
		}
		
		for (j = 0; j < cm; j++)
		{
			SBElement *e = [mMidiArgumentArray objectAtIndex:j];
			
			if (e == sa)
				[mMidiArgumentArray replaceObjectAtIndex:j withObject:da];
		}
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
												name:nil
												object:sa];
		
		if ([da isKindOfClass:[SBRootCircuitPrecision class]])
		{
			[[NSNotificationCenter defaultCenter] addObserver:self
							selector:@selector(subElementDidChangePrecision:)
							name:kSBRootCircuitPrecisionChangeNotification
							object:da];
		}
		else if ([da isKindOfClass:[SBRootCircuitInterpolation class]])
		{
			[[NSNotificationCenter defaultCenter] addObserver:self
							selector:@selector(subElementDidChangeInterpolation:)
							name:kSBRootCircuitInterpolationChangeNotification
							object:da];
		}
		
		[src replaceObjectAtIndex:i withObject:da];
	}
	
	mSharingArguments = YES;
	mIsCompiled = NO;
}



- (void) unsuperposeElements
{
	//return;

	int c = [mElementArray count], i, j;
	
	BOOL changed;
	int loopCount = 0;
	do
	{
		changed = NO;
		loopCount++;
		for (i = 0; i < c; i++)
		{
			SBElement *a = [mElementArray objectAtIndex:i];
			NSRect af;
			
			af.origin = [a designOrigin];
			af.origin.x -= 4;
			af.origin.y -= 4;
			af.size.width = 8;
			af.size.height = 8;
			
			BOOL outside = NO;
			
			if (af.origin.x < 0.)
			{
				af.origin.x = 0.f;
				outside = YES;
			}
			
			if (af.origin.y < 0.)
			{
				af.origin.y = 0.f;
				outside = YES;
			}
			
			if (outside)
			{
				[a setOriginX:af.origin.x + af.size.width/2 Y:af.origin.y + af.size.height/2];
				changed = YES; i = c; j = c;
			}
			
			for (j = i + 1; j < c; j++)
			{
				SBElement *b = [mElementArray objectAtIndex:j];
			
				NSRect bf;
				bf.origin = [b designOrigin];
				bf.origin.x -= 4;
				bf.origin.y -= 4;
				bf.size.width = 8;
				bf.size.height = 8;
			
				if	(	pointInsideRect(af.origin.x, af.origin.y, bf)
					||	pointInsideRect(af.origin.x + af.size.width, af.origin.y, bf)
					||	pointInsideRect(af.origin.x, af.origin.y + af.size.height, bf)
					||	pointInsideRect(af.origin.x + af.size.width, af.origin.y + af.size.height, bf)
					||	pointInsideRect(bf.origin.x, bf.origin.y, af)
					||	pointInsideRect(bf.origin.x + bf.size.width, bf.origin.y, af)
					||	pointInsideRect(bf.origin.x, bf.origin.y + bf.size.height, af)
					||	pointInsideRect(bf.origin.x + bf.size.width, bf.origin.y + bf.size.height, af))
				{
					SBElement *m = b;
					NSRect mf = bf;

					mf.origin.x += 8.5f;
					mf.origin.y += 8.5f;
						
					[m setOriginX:mf.origin.x + mf.size.width/2 Y:mf.origin.y + mf.size.height/2];
					changed = YES; i = c; j = c;
				}
			}
		}
	} while(changed && loopCount < 100);
}



- (void) dispatchMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offsetToChange
{
	int c = [mMidiArgumentArray count], i;
	for (i = 0; i < c; i++)
	{
		SBMidiArgument *ma = [mMidiArgumentArray objectAtIndex:i];
		[ma handleMidiEvent:status channel:channel data1:data1 data2:data2 offsetToChange:offsetToChange];
	}
}

- (BOOL) hasMidiArguments
{
	return ([mMidiArgumentArray count] > 0);
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBCircuit" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mNameTF setStringValue:mName];
	[mCommentsTF setStringValue:mInformations];
	
	NSSize size = [self circuitMinSize];
	[mWidthTF setFloatValue:size.width];
	[mHeightTF setFloatValue:size.height];
	
	[mNumberOfInputTF setIntValue:[mInputNames count]];
	[mNumberOfOutputTF setIntValue:[self numberOfOutputs]];
	
	[mNumberOfInputTF setEnabled:mCanChangeNumberOfInputsOutputs];
	[mNumberOfOutputTF setEnabled:mCanChangeNumberOfInputsOutputs];
	
	NSPopUpButtonCell *pcell = [[mInoutTable tableColumnWithIdentifier:@"type"] dataCell];
	[pcell removeAllItems];
	
	SET_TYPE_NAMES(pcell)
	
	[mWiresBehindButton setState:(mWiresBehind) ? NSOnState : NSOffState];
}

- (void) controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if (tf == mNumberOfInputTF)
	{
		[self setNumberOfInputs:[mNumberOfInputTF intValue]];
		[mNumberOfInputTF setIntValue:[mInputNames count]];
		[self didChangeGlobalView];
	}
	else if (tf == mNumberOfOutputTF)
	{
		[self setNumberOfOutputs:[mNumberOfOutputTF intValue]];
		[mNumberOfOutputTF setIntValue:[self numberOfOutputs]];
		[self didChangeGlobalView];
	}
	else if (tf == mNameTF)
	{
		[self setName:[mNameTF stringValue]];
		[mNameTF setStringValue:[self name]];
		[self didChangeGlobalView];
	}
	else if (tf == mCommentsTF)
	{
		[self setInformations:[mCommentsTF stringValue]];
		[mCommentsTF setStringValue:[self informations]];
	}
	else if (tf == mWidthTF)
	{
		NSSize s = [self circuitMinSize];
		s.width = [mWidthTF floatValue];
		[self setCircuitMinSize:s];
		
		s = [self circuitMinSize];
		[mWidthTF setFloatValue:s.width];
		
		[self didChangeGlobalView];
	}
	else if (tf == mHeightTF)
	{	
		NSSize s = [self circuitMinSize];
		s.height = [mHeightTF floatValue];
		[self setCircuitMinSize:s];
		
		s = [self circuitMinSize];
		[mHeightTF setFloatValue:s.height];
		
		[self didChangeGlobalView];
	}
}

- (void) didChangeMinSize
{
	[[NSNotificationCenter defaultCenter]
		postNotificationName:kSBCircuitDidChangeMinSizeNotification object:self];
}

- (void) setCanChangeNumberOfInputsOutputs:(BOOL)can
{
	mCanChangeNumberOfInputsOutputs = can;
	if (mNumberOfInputTF) [mNumberOfInputTF setEnabled:can];
	if (mNumberOfOutputTF) [mNumberOfOutputTF setEnabled:can];
}

- (void) setCanChangeInputsOutputsTypes:(BOOL)can
{
	mCanChangeInputsOutputsTypes = can;
}

- (void) setColorsBack:(NSColor*)back contour:(NSColor*)contour front:(NSColor*)front
{
	mColorBack = back;
	mColorContour = contour;
	mColorFront = front;

	[super	setColorsBack:back
			contour:contour
			front:front];
	
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		[[mElementArray objectAtIndex:i]	setColorsBack:back
											contour:contour
											front:front];
}

- (void) setGuiMode:(SBGuiMode)mode
{
	[super setGuiMode:mode];
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		[[mElementArray objectAtIndex:i] setGuiMode:mode];

	[mSelectedList removeAllElements];
}

- (void) setMiniMode:(BOOL)mini
{
	[super setMiniMode:mini];
	
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		[[mElementArray objectAtIndex:i] setMiniMode:mini];
}

- (void) setLastCircuit:(BOOL)isLastCircuit
{
	[super setLastCircuit:isLastCircuit];
	
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		[[mElementArray objectAtIndex:i] setLastCircuit:isLastCircuit];
}

// tableview stuff
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self numberOfInputs] + [self numberOfOutputs];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	int inputs = [self numberOfInputs];
	NSString *identifier = [aTableColumn identifier];
	if ([identifier isEqual:@"inout"])
	{
		if (rowIndex < inputs) return @"In";
		else return @"out";
	}
	else if ([identifier isEqual:@"type"])
	{
		SBConnectionType type;
		if (rowIndex < inputs) type = [self typeOfInputAtIndex:rowIndex];
		else type = [self typeOfOutputAtIndex:rowIndex - inputs];
		return [NSNumber numberWithInt:(int)type];
	}
	else // name
	{
		if (rowIndex < inputs) return [self nameOfInputAtIndex:rowIndex];
		else return [self nameOfOutputAtIndex:rowIndex - inputs];
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	int inputs = [self numberOfInputs];
	NSString *identifier = [aTableColumn identifier];
	if ([identifier isEqual:@"type"])
	{
		SBConnectionType type = (SBConnectionType)[anObject intValue];
		if (rowIndex < inputs) [self changeInputType:rowIndex newType:type];
		else [self changeOutputType:rowIndex - inputs newType:type];
	}
	else // name
	{
		if (rowIndex < inputs) [self changeInputName:rowIndex newName:anObject];
		else [self changeOutputName:rowIndex - inputs newName:anObject];
	}
	[mInoutTable reloadData];
	return;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
}

- (void) changeInputType:(int)idx newType:(SBConnectionType)type
{
	if (!mCanChangeInputsOutputsTypes) return;

	if (idx < 0) return;
	if (idx >= kMaxChannels) return;

	[self willChangeAudio];
	
	mInputTypes[idx] = type;
	
	[self subElementDidChangeConnections:nil];
	[self didChangeConnections];
	[self didChangeAudio];
	
	[self didChangeGlobalView];
	
	if (mInoutTable) [mInoutTable reloadData];
}

- (void) changeOutputType:(int)idx newType:(SBConnectionType)type
{
	if (!mCanChangeInputsOutputsTypes) return;

	if (idx < 0) return;
	if (idx >= kMaxChannels) return;

	[self willChangeAudio];
	
	mOutputTypes[idx] = type;
	
	[self subElementDidChangeConnections:nil];
	[self didChangeConnections];
	[self didChangeAudio];
	
	[self didChangeGlobalView];
	
	if (mInoutTable) [mInoutTable reloadData];
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx < 0) idx = 0;
	else if (idx >= kMaxChannels) idx = kMaxChannels - 1;
	
	return mInputTypes[idx];
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	if (idx < 0) idx = 0;
	else if (idx >= kMaxChannels) idx = kMaxChannels - 1;
	
	return mOutputTypes[idx];
}

- (IBAction) changedWiresBehind:(id)sender
{
	mWiresBehind = ([mWiresBehindButton state] == NSOnState);
	[self didChangeGlobalView];
}

- (BOOL) constantRefresh
{
	/*if (!mIsCompiled)
	{
		
		[self willChangeAudio];
		[self compile];
		[self didChangeAudio];
	
	}*/
	
	// we already recompile when adding and removing elements
	// which is enough

	return mConstantRefresh;
}

- (void) clearState
{
	mIsCompiled = NO;
	[mSelectedList removeAllElements];
	[mWireArray removeAllObjects];
	[mMidiArgumentArray removeAllObjects];
	[mArgumentArray removeAllObjects];
	[mCompiledArray removeAllObjects];
	[mElementArray removeAllObjects];
	
	[mInputNames removeAllObjects];
	[mOutputNames removeAllObjects];
	
	/*if (pIsInDemoMode) [self	prepareForSamplingRate:mSampleRate
								sampleCount:mSampleCount
								precision:mPrecision
								interpolation:mInterpolation];*/
	
	if (mSettingsView) { [mSettingsView release]; mSettingsView = nil; } // force refresh
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) creatingWire
{
	return mCreatingWire != nil;
}

- (void) selectAll
{
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
		[mSelectedList addElement:[mElementArray objectAtIndex:i]];
}

- (void) selectRect:(NSRect)rect
{
	[mSelectedList removeAllElements];
	
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mElementArray objectAtIndex:i];
		NSPoint pt = [e designOrigin];
		
		if (pointInsideRect(pt.x, pt.y, rect))
			[mSelectedList addElement:e];
	}
}

- (void) trimDebug
{
	int c = [mElementArray count], i;
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mElementArray objectAtIndex:i];
		NSString *s = [e className];
		
		if ([s isEqual:@"SBDebug"] || [s isEqual:@"SBDebugOsc"])
		{
			[self removeElement:e];
			i--; c--;
		}
		else
			[e trimDebug];
	}
}

- (SBSelectionList *)selectionList
{
	return mSelectedList;	
}

@end
