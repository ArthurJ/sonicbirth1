/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElementServer.h"

#import "SBCircuit.h"

#import "SBBoolean.h"
#import "SBSlider.h"
#import "SBIndexed.h"
#import "SBPoints.h"
#import "SBPointsEnvelope.h"
#import "SBPointsFrequency.h"
#import "SBXYPad.h"
#import "SBAudioFileArgument.h"
#import "SBKeyboardTap.h"

#import "SBAdd.h"
#import "SBAddMany.h"
#import "SBSub.h"
#import "SBMul.h"
#import "SBDiv.h"
#import "SBCstAdd.h"
#import "SBCstSub.h"
#import "SBCstMul.h"
#import "SBCstDiv.h"
#import "SBCstSubAlt.h"
#import "SBCstDivAlt.h"
#import "SBNegate.h"
#import "SBInvert.h"
#import "SBAbs.h"
#import "SBAbsSign.h"
#import "SBDirection.h"
#import "SBMulAdd.h"
#import "SBMulSub.h"
#import "SBNegMulAdd.h"
#import "SBNegMulSub.h"

#import "SBSin.h"
#import "SBCos.h"
#import "SBTan.h"
#import "SBSinCos.h"
#import "SBSinh.h"
#import "SBCosh.h"
#import "SBTanh.h"
#import "SBAsin.h"
#import "SBAcos.h"
#import "SBAtan.h"
#import "SBAtan2.h"
#import "SBAsinh.h"
#import "SBAcosh.h"
#import "SBAtanh.h"

#import "SBSineWave.h"
#import "SBSawWave.h"
#import "SBTriangleWave.h"
#import "SBSquareWave.h"
#import "SBLinearNoise.h"
#import "SBWhiteNoise.h"
#import "SBPinkNoise.h"
#import "SBRandom.h"
#import "SBRandomRamp.h"
#import "SBFFTGenerator.h"
#import "SBFastSineWave.h"

#import "SBFeedback.h"

#import "SBSampleRateDoubler.h"
#import "SBPiecewiseCircuit.h"
#import "SBTimer.h"
#import "SBTimerLoop.h"
#import "SBConstant.h"
#import "SBEquation.h"
#import "SBFreeverb.h"
#import "SBCleaner.h"
#import "SBPointsApply.h"
#import "SBBufferizer.h"
#import "SBTrigger.h"
#import "SBSlow.h"
#import "SBConvolvingReverb.h"
#import "SBAudioUnit.h"
#import "SBAudioUnitMidi.h"
#import "SBGranulate.h"
#import "SBXOver.h"
#import "SBFlipFlop.h"

#import "SBValve.h"
#import "SBScraper.h"
#import "SBScraperQuick.h"

#import "SBMin.h"
#import "SBMax.h"
#import "SBSort.h"
#import "SBLess.h"
#import "SBEqual.h"
#import "SBGreater.h"

#import "SBMsecToSamples.h"
#import "SBSamplesToMsec.h"
#import "SBLinearToDb.h"
#import "SBDbToLinear.h"

#import "SBDelay.h"
#import "SBDelaySinc.h"
#import "SBDelaySample.h"

#import "SBDCBlocker.h"
#import "SBParametricEq.h"
#import "SBFastFilter.h"
#import "SBPeakNotch.h"
#import "SBLowpass.h"
#import "SBHighpass.h"
#import "SBBandstop.h"
#import "SBBandpass.h"
#import "SBCrossover.h"
#import "SBAllpass.h"
#import "SBFeedbackComb.h"
#import "SBFeedforwardComb.h"
#import "SBResonantLowpass.h"
#import "SBResonantHighpass.h"
#import "SBFormant.h"

#import "SBEnvelopeFollower.h"
#import "SBLookAhead.h"
#import "SBBPMCounter.h"
#import "SBDebug.h"
#import "SBDebugOsc.h"

#import "SBMidiMultiNote.h"
#import "SBMidiMultiNoteEnvelope.h"
#import "SBMidiMonoNote.h"
#import "SBMidiSlider.h"
#import "SBMidiNoteState.h"
#import "SBMidiXYPad.h"

#import "SBMod.h"
#import "SBCeil.h"
#import "SBFloor.h"
#import "SBNearInt.h"
#import "SBExp.h"
#import "SBLog.h"
#import "SBLog10.h"
#import "SBPow.h"
#import "SBSqrt.h"
#import "SBRevSqrt.h"
#import "SBBezierQuadratic.h"

#import "SBRootCircuitInterpolation.h"
#import "SBRootCircuitPrecision.h"
#import "SBRootCircuitMidi.h"

#import "SBAudioFileElement.h"
#import "SBAudioPlayer.h"

#import "SBFFTSync.h"
#import "SBForwardFFT.h"
#import "SBInverseFFT.h"
#import "SBComplexToPolar.h"
#import "SBPolarToComplex.h"
#import "SBConvolve.h"
#import "SBPointsToFFT.h"
#import "SBAudioFileToFFT.h"

#import "SBDisplayValue.h"
#import "SBDisplayOsc.h"
#import "SBDisplayMeter.h"
#import "SBGraphicObject.h"
#import "SBVisibleComment.h"

#define ELEMENT_LIST \
	ADD_ELEMENT(SBBoolean) \
	ADD_ELEMENT(SBSlider) \
	ADD_ELEMENT(SBIndexed) \
	ADD_ELEMENT(SBPoints) \
	ADD_ELEMENT(SBPointsEnvelope) \
	ADD_ELEMENT(SBPointsFrequency) \
	ADD_ELEMENT(SBXYPad) \
	ADD_ELEMENT(SBAudioFileArgument) \
	ADD_ELEMENT(SBKeyboardTap) \
	 \
	ADD_ELEMENT(SBCircuit) \
	 \
	ADD_ELEMENT(SBAdd) \
	ADD_ELEMENT(SBAddMany) \
	ADD_ELEMENT(SBSub) \
	ADD_ELEMENT(SBMul) \
	ADD_ELEMENT(SBDiv) \
	ADD_ELEMENT(SBCstAdd) \
	ADD_ELEMENT(SBCstSub) \
	ADD_ELEMENT(SBCstMul) \
	ADD_ELEMENT(SBCstDiv) \
	ADD_ELEMENT(SBCstSubAlt) \
	ADD_ELEMENT(SBCstDivAlt) \
	ADD_ELEMENT(SBNegate) \
	ADD_ELEMENT(SBInvert) \
	ADD_ELEMENT(SBAbs) \
	ADD_ELEMENT(SBAbsSign) \
	ADD_ELEMENT(SBDirection) \
	ADD_ELEMENT(SBMulAdd) \
	ADD_ELEMENT(SBMulSub) \
	ADD_ELEMENT(SBNegMulAdd) \
	ADD_ELEMENT(SBNegMulSub) \
	 \
	ADD_ELEMENT(SBSin) \
	ADD_ELEMENT(SBCos) \
	ADD_ELEMENT(SBTan) \
	ADD_ELEMENT(SBSinCos) \
	ADD_ELEMENT(SBSinh) \
	ADD_ELEMENT(SBCosh) \
	ADD_ELEMENT(SBTanh) \
	ADD_ELEMENT(SBAsin) \
	ADD_ELEMENT(SBAcos) \
	ADD_ELEMENT(SBAtan) \
	ADD_ELEMENT(SBAtan2) \
	ADD_ELEMENT(SBAsinh) \
	ADD_ELEMENT(SBAcosh) \
	ADD_ELEMENT(SBAtanh) \
	 \
	ADD_ELEMENT(SBSineWave) \
	ADD_ELEMENT(SBFastSineWave) \
	ADD_ELEMENT(SBSawWave) \
	ADD_ELEMENT(SBTriangleWave) \
	ADD_ELEMENT(SBSquareWave) \
	ADD_ELEMENT(SBLinearNoise) \
	ADD_ELEMENT(SBWhiteNoise) \
	ADD_ELEMENT(SBPinkNoise) \
	ADD_ELEMENT(SBRandom) \
	ADD_ELEMENT(SBRandomRamp) \
	ADD_ELEMENT(SBFFTGenerator) \
	 \
	ADD_ELEMENT(SBFeedback) \
	 \
	ADD_ELEMENT(SBConstant) \
	ADD_ELEMENT(SBEquation) \
	ADD_ELEMENT(SBPiecewiseCircuit) \
	ADD_ELEMENT(SBSampleRateDoubler) \
	ADD_ELEMENT(SBTimer) \
	ADD_ELEMENT(SBTimerLoop) \
	ADD_ELEMENT(SBFreeverb) \
	ADD_ELEMENT(SBCleaner) \
	ADD_ELEMENT(SBPointsApply) \
	ADD_ELEMENT(SBBufferizer) \
	ADD_ELEMENT(SBTrigger) \
	ADD_ELEMENT(SBSlow) \
	ADD_ELEMENT(SBConvolvingReverb) \
	ADD_ELEMENT(SBAudioUnit) \
	ADD_ELEMENT(SBAudioUnitMidi) \
	ADD_ELEMENT(SBGranulate) \
	ADD_ELEMENT(SBGranulatePicth) \
	ADD_ELEMENT(SBXOver) \
	ADD_ELEMENT(SBFlipFlop) \
	 \
	ADD_ELEMENT(SBValve) \
	ADD_ELEMENT(SBScraper) \
	ADD_ELEMENT(SBScraperQuick) \
	 \
	ADD_ELEMENT(SBMin) \
	ADD_ELEMENT(SBMax) \
	ADD_ELEMENT(SBSort) \
	ADD_ELEMENT(SBLess) \
	ADD_ELEMENT(SBEqual) \
	ADD_ELEMENT(SBGreater) \
	 \
	ADD_ELEMENT(SBMsecToSamples) \
	ADD_ELEMENT(SBSamplesToMsec) \
	ADD_ELEMENT(SBLinearToDb) \
	ADD_ELEMENT(SBDbToLinear) \
	 \
	ADD_ELEMENT(SBDelay) \
	ADD_ELEMENT(SBDelaySample) \
	ADD_ELEMENT(SBDelaySinc) \
	 \
	ADD_ELEMENT(SBDCBlocker) \
	ADD_ELEMENT(SBParametricEq) \
	ADD_ELEMENT(SBPeak) \
	ADD_ELEMENT(SBNotch) \
	ADD_ELEMENT(SBLowpass) \
	ADD_ELEMENT(SBHighpass) \
	ADD_ELEMENT(SBResonantLowpass) \
	ADD_ELEMENT(SBResonantHighpass) \
	ADD_ELEMENT(SBCrossover) \
	ADD_ELEMENT(SBBandstop) \
	ADD_ELEMENT(SBBandpass) \
	ADD_ELEMENT(SBFastLowpass) \
	ADD_ELEMENT(SBFastHighpass) \
	ADD_ELEMENT(SBFastResonantLowpass) \
	ADD_ELEMENT(SBFastResonantHighpass) \
	ADD_ELEMENT(SBFastCrossover) \
	ADD_ELEMENT(SBFastBandstop) \
	ADD_ELEMENT(SBFastBandpass) \
	ADD_ELEMENT(SBAllpass) \
	ADD_ELEMENT(SBFeedbackComb) \
	ADD_ELEMENT(SBFeedforwardComb) \
	ADD_ELEMENT(SBFormant) \
	 \
	ADD_ELEMENT(SBEnvelopeFollower) \
	ADD_ELEMENT(SBLookAhead) \
	ADD_ELEMENT(SBBPMCounter) \
	ADD_ELEMENT(SBDebug) \
	ADD_ELEMENT(SBDebugOsc) \
	 \
	ADD_ELEMENT(SBMidiSlider) \
	ADD_ELEMENT(SBMidiNoteState) \
	ADD_ELEMENT(SBMidiMonoNote) \
	ADD_ELEMENT(SBMidiMultiNote) \
	ADD_ELEMENT(SBMidiMultiNoteEnvelope) \
	ADD_ELEMENT(SBMidiXYPad) \
	 \
	ADD_ELEMENT(SBMod) \
	ADD_ELEMENT(SBCeil) \
	ADD_ELEMENT(SBFloor) \
	ADD_ELEMENT(SBNearInt) \
	ADD_ELEMENT(SBExp) \
	ADD_ELEMENT(SBLog) \
	ADD_ELEMENT(SBLog10) \
	ADD_ELEMENT(SBPow) \
	ADD_ELEMENT(SBSqrt) \
	ADD_ELEMENT(SBRevSqrt) \
	ADD_ELEMENT(SBBezierQuadratic) \
	 \
	ADD_ELEMENT(SBRootCircuitInterpolation) \
	ADD_ELEMENT(SBRootCircuitPrecision) \
	ADD_ELEMENT(SBRootCircuitMidi) \
	 \
	ADD_ELEMENT(SBAudioFileElement) \
	ADD_ELEMENT(SBAudioPlayer) \
	 \
	ADD_ELEMENT(SBFFTSync) \
	ADD_ELEMENT(SBForwardFFT) \
	ADD_ELEMENT(SBInverseFFT) \
	ADD_ELEMENT(SBComplexToPolar) \
	ADD_ELEMENT(SBPolarToComplex) \
	ADD_ELEMENT(SBConvolve) \
	ADD_ELEMENT(SBPointsToFFT) \
	ADD_ELEMENT(SBAudioFileToFFT) \
	 \
	ADD_ELEMENT(SBDisplayValue) \
	ADD_ELEMENT(SBDisplayOsc) \
	ADD_ELEMENT(SBDisplayOscVarRes) \
	ADD_ELEMENT(SBDisplayMeter) \
	ADD_ELEMENT(SBGraphicObject) \
	ADD_ELEMENT(SBVisibleComment)

static NSString *gElementListString[] = 
{
	#define ADD_ELEMENT(x) @ #x,
	ELEMENT_LIST
	#undef ADD_ELEMENT
	nil
};

static int gElementCount = sizeof(gElementListString)/sizeof(NSString *) - 1;

SBElementServer *gElementServer = nil;

@implementation SBElementServer

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		srandomdev();
		mElementsArray = nil;
		mCategoryArray = nil;
	}
	gElementServer = self;
	return self;
}

- (void) awakeFromNib
{
	//[super awakeFromNib];

	// force list setup in application
	[self createElementsArray];
	[self createCategoryArray];
	[mOutlineView reloadData];
	
	NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:@"elementPanelShouldOpen"];
	if (!n || ([n intValue] == 2)) [mElementPanel makeKeyAndOrderFront:self];
}

- (void) createElementsArray
{
	if (!mElementsArray)
	{
	
		mElementsArray = [[NSMutableArray alloc] init];
		assert(mElementsArray);
		
		#define ADD_ELEMENT(x) [mElementsArray addObject:[[[x alloc] init] autorelease]];
		ELEMENT_LIST
		#undef ADD_ELEMENT
		
		
		
		mCommonElementsArray = [[NSMutableArray alloc] init];
		assert(mCommonElementsArray);

		SBElement *e;
		if ((e = [self rawElementForClassName:@"SBAdd"]))		[mCommonElementsArray addObject:e];
		if ((e = [self rawElementForClassName:@"SBSub"]))		[mCommonElementsArray addObject:e];
		if ((e = [self rawElementForClassName:@"SBMul"]))		[mCommonElementsArray addObject:e];
		if ((e = [self rawElementForClassName:@"SBDiv"]))		[mCommonElementsArray addObject:e];
		if ((e = [self rawElementForClassName:@"SBSlider"]))	[mCommonElementsArray addObject:e];
		if ((e = [self rawElementForClassName:@"SBBoolean"]))	[mCommonElementsArray addObject:e];
		if ((e = [self rawElementForClassName:@"SBIndexed"]))	[mCommonElementsArray addObject:e];
		if ((e = [self rawElementForClassName:@"SBSineWave"]))	[mCommonElementsArray addObject:e];
		if ((e = [self rawElementForClassName:@"SBFeedback"]))	[mCommonElementsArray addObject:e];
		if ((e = [self rawElementForClassName:@"SBDelay"]))		[mCommonElementsArray addObject:e];
	}
}

- (SBElement*) rawElementForClassName:(NSString*)className
{
	int i, c = [mElementsArray count];
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mElementsArray objectAtIndex:i];
		NSString *s = [e className];
		if ([s isEqual:className]) return e;
	}

	return nil;
}

- (void) dealloc
{
	gElementServer = nil;
	if (mElementsArray) [mElementsArray release];
	if (mCommonElementsArray) [mCommonElementsArray release];
	if (mCategoryArray) [mCategoryArray release];
	[super dealloc];
}

- (void) fillMenu:(NSMenu*)menu target:(id)target action:(SEL)action
{
	if (!mElementsArray) [self createElementsArray];

	while([menu numberOfItems] > 1)
		[menu removeItemAtIndex:1];
		
	NSMutableArray *ma = [[[NSMutableArray alloc] init] autorelease];
	//NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Lucida Grande" size:10]
	//										 forKey:NSFontAttributeName];
		
	// categories
	int i, c = kInternal;
	for (i = 0; i < c; i++)
	{
	
		NSMenu *m = [[[NSMenu alloc] init] autorelease];
		if (!m) return;
		
		[m setAutoenablesItems:NO];
		
		[ma addObject:m];
		
		NSString *title = [SBElement nameForCategory:i];
		NSMenuItem *mi = [menu	addItemWithTitle:title
									action:nil
									keyEquivalent:@""];
									
		//NSAttributedString *string =
		//	[[NSAttributedString alloc] initWithString:title
		//								 attributes:attributes];
		//[mi setAttributedTitle:string];
		//
		//[string release];
		
		[menu   setSubmenu:m
				   forItem:mi];
	}
	
	// elements
	c = [mElementsArray count];
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mElementsArray objectAtIndex:i];
		SBElementCategory cat = [e category];
		if (cat < kInternal)
		{
			NSString *title = [[e class] name];
			
			NSMenuItem *mi = [[ma objectAtIndex:cat]
								addItemWithTitle:title
								action:action
								keyEquivalent:@""];
			[mi setTarget:target];
			
			//NSAttributedString *string =
			//	[[NSAttributedString alloc] initWithString:title
			//								attributes:attributes];
			//[mi setAttributedTitle:string];
			//
			//[string release];
		}
	}
	
	
	// commons
	NSMenu *m = [ma objectAtIndex:kCommon];
	c = [mCommonElementsArray count];
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mCommonElementsArray objectAtIndex:i];
			
		NSString *title = [[e class] name];
		
		NSMenuItem *mi = [m addItemWithTitle:title
							action:action
							keyEquivalent:@""];
		[mi setTarget:target];
		
		//NSAttributedString *string =
		//	[[NSAttributedString alloc] initWithString:title
		//								attributes:attributes];
		//[mi setAttributedTitle:string];
		//
		//[string release];
	}
}

- (SBElement*) createElement:(NSString*)name
{
	int c = gElementCount, i;
	for (i = 0; i < c; i++)
	{
		if ([name isEqual:gElementListString[i]])
			return [[[NSClassFromString(name) alloc] init] autorelease];
	}
	
	// old style file, keep compat.
	if (!mElementsArray) [self createElementsArray];
	
	c = [mElementsArray count];
	for (i = 0; i < c; i++)
	{
		Class class = [[mElementsArray objectAtIndex:i] class];
		if ([name isEqual:[class name]])
			return [[[class alloc] init] autorelease];
	}

	return nil;
}

- (NSArray*) rawElements
{
	if (!mElementsArray) [self createElementsArray];
	return mElementsArray;
}

// in application only
- (void) createCategoryArray
{
	if (!mCategoryArray)
	{
		mCategoryArray = [[NSMutableArray alloc] init];
		if (!mElementsArray) [self createElementsArray];
		
		int i, c = kInternal;
		for (i = 0; i < c; i++)
			[mCategoryArray addObject:[[[NSMutableArray alloc] init] autorelease]];

		c = [mElementsArray count];
		for (i = 0; i < c; i++)
		{
			SBElement *e = [mElementsArray objectAtIndex:i];
			SBElementCategory cat = [e category];
			if (cat < kInternal)
				[[mCategoryArray objectAtIndex:cat] addObject:e];
		}
		
		NSMutableArray *m = [mCategoryArray objectAtIndex:kCommon];
		c = [mCommonElementsArray count];
		for (i = 0; i < c; i++)
		{
			SBElement *e = [mCommonElementsArray objectAtIndex:i];
			[m  addObject:e];
		}
	}

}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return (item == nil) || ([mCategoryArray indexOfObjectIdenticalTo:item] != NSNotFound);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)idx ofItem:(id)item
{
	if (!item) return [mCategoryArray objectAtIndex:idx];
	
	if ([mCategoryArray indexOfObjectIdenticalTo:item] != NSNotFound)
		return [(NSMutableArray*)item objectAtIndex:idx];

	return nil;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item) return [mCategoryArray count];
	
	if ([mCategoryArray indexOfObjectIdenticalTo:item] != NSNotFound)
		return [(NSMutableArray*)item count];

	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (!item) return nil;
	
	NSString *ident = [tableColumn identifier];
	NSUInteger idx = [mCategoryArray indexOfObjectIdenticalTo:item];
	
	if (idx != NSNotFound)
	{
		if (![ident isEqual:@"name"]) return nil;
		
		return [SBElement nameForCategory:idx];
	}
	
	if ([ident isEqual:@"name"]) return [[item class] name];
	if ([ident isEqual:@"desc"]) return [(SBElement*)item informations];

	return nil;
}

- (IBAction) showPanel:(id)server
{
	if (!mElementPanel) return;
	if ([mElementPanel isVisible])
	{
		[mElementPanel orderOut:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"elementPanelShouldOpen"];
	}
	else
	{
		[mElementPanel makeKeyAndOrderFront:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:2] forKey:@"elementPanelShouldOpen"];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([aNotification object] == mElementPanel)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"elementPanelShouldOpen"];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	if (!items) return NO;
	if ([items count] != 1) return NO;

	id item = [items objectAtIndex:0];
	if ([mCategoryArray indexOfObjectIdenticalTo:item] != NSNotFound) return NO;

	[pboard declareTypes:[NSArray arrayWithObject:@"SBElementName"] owner:nil];
	[pboard setString:[[item class] name] forType:@"SBElementName"];
	
	return YES;
}

@end
