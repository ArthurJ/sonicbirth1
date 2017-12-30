/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBRootCircuit.h"
#import "SBRootCircuitPrecision.h"
#import "SBRootCircuitInterpolation.h"
#import "SBRootCircuitMidi.h"
#import "SBMidiArgument.h"
#import "FrameworkSettings.h" // for version ns string

#define kGuiMinSize (50)

static NSString * stringFix(NSString *string)
{
	int l = [string length];

	if (l < 1) return string;
	
	char newName[200];
	strncpy(newName, [string cString], 150);
	newName[128] = 0;
	
	int i, length = strlen(newName);
	for (i = 0; i < length; i++)
	{
		char c = newName[i];
		
		if (c >= 'A' && c <= 'Z') continue;
		if (c >= 'a' && c <= 'z') continue;
		if (c >= '0' && c <= '9') continue;

		if (c == '_' || c == ' ' || c == '(' || c == ')') continue;
		
		// illegal charater
		// replace with '_'

		newName[i] = '_';
	}
	
	return [NSString stringWithCString:newName];
}

@implementation SBRootCircuit


- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pPrecision = mPrecision;
		pthread_mutex_init(&pMutex, NULL);
	
		mLatency = 0.;
		mTailTime = 0.;
		
		// memset(mSubType, 'a', 4);
		
		int i;
		const char *choices =	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
								"abcdefghijklmnopqrstuvwxyz"
								"0123456789"
								"!@#$%?&*()"
								"-+_=/\\;:.,\'\"[]{}";
		int numChoices = strlen(choices);
		for (i = 0; i < 4; i++)
		{
			int r = random();
			r %= numChoices;
			mSubType[i] = choices[r];
			
		}
		if (mSubType[0] == 'S') mSubType[0] = 's';
		
		mGuiSize.width = 600;
		mGuiSize.height = 400;

		mAuthor = [[NSMutableString alloc] init];
		if (!mAuthor)
		{
			[self release];
			return nil;
		}
		
		mCompany = [[NSMutableString alloc] initWithString:@"SonicBirth"];
		if (!mCompany)
		{
			[self release];
			return nil;
		}
		
		mPluginDescription = [[NSMutableString alloc] initWithString:@"An audio effect exported from SonicBirth"];
		if (!mPluginDescription)
		{
			[self release];
			return nil;
		}
		
		mPresetArray = [[NSMutableArray alloc] init];
		if (!mPresetArray)
		{
			[self release];
			return nil;
		}
		
		//mColorBack = [[NSColor darkGrayColor] retain];
		//mColorContour = [[NSColor lightGrayColor] retain];
		//mColorFront = [[NSColor yellowColor] retain];
		
		mColorBack =	[[NSColor colorWithCalibratedRed:255.f/255.f green:255.f/255.f blue:255.f/255.f alpha:1.f] retain];
		mColorContour = [[NSColor colorWithCalibratedRed:  0.f/255.f green:  0.f/255.f blue:255.f/255.f alpha:1.f] retain];
		mColorFront =	[[NSColor colorWithCalibratedRed: 51.f/255.f green: 51.f/255.f blue: 51.f/255.f alpha:1.f] retain];
		
		if (!mColorBack || !mColorContour || !mColorFront)
		{
			[self release];
			return nil;
		}
		
		// do this when everything else is inited
		SBRootCircuitPrecision *rcp = [[SBRootCircuitPrecision alloc] init];
		if (!rcp)
		{
			[self release];
			return nil;
		}
		[rcp setOriginX:100 Y:100];
		[self addElement:rcp];
		[rcp release];

		[mInformations setString:@""];
		
		mNeedsTempo = NO;
		mHasSideChain = NO;
		mLatencySamples = 0;
		
		mCanChangeHasSideChain = YES;
		
		[self setNumberOfInputs:1];
		[self setNumberOfOutputs:1];

	}
	return self;
}

- (void) dealloc
{
	pthread_mutex_destroy(&pMutex);

	if (mPresetArray) [mPresetArray release];
	if (mAuthor) [mAuthor release];
	if (mCompany) [mCompany release];
	if (mPluginDescription) [mPluginDescription release];
	
	if (mColorBack) [mColorBack release];
	if (mColorContour) [mColorContour release];
	if (mColorFront) [mColorFront release];
	
	if (mBgImage) ogReleaseImage(mBgImage);
	if (mBgImageData) [mBgImageData release];

	[super dealloc];
}

- (void) lock
{
	pthread_mutex_lock(&pMutex);
}

- (void) unlock
{
	pthread_mutex_unlock(&pMutex);
}

- (void) willChangeAudio
{
	pthread_mutex_lock(&pMutex);
}

- (void) didChangeAudio
{
	pthread_mutex_unlock(&pMutex);
}

//#warning "remove logs after tests"

- (void) changePrecision:(SBPrecision)precision
{
	[super changePrecision:precision];
	pPrecision = mPrecision;
	//NSLog(@"root circuit changePrecision: %i", precision);
}

/*- (void) changeInterpolation:(SBInterpolation)interpolation
{
	[super changeInterpolation:interpolation];
	NSLog(@"root circuit changeInterpolation: %i", interpolation);
}*/

- (NSString*) author
{
	return mAuthor;
}

- (void) setAuthor:(NSString*)author
{
	[mAuthor setString:author];
}

- (double) latency
{
	double latency = mLatency;
	if (mSampleRate > 0) latency += mLatencySamples / (double)mSampleRate;
	return latency;
}

- (double) latencyMs
{
	return mLatency;
}

- (double) latencySamples
{
	return mLatencySamples;
}

- (double) tailTime
{
	return mTailTime;
}

- (char*) subType
{
	return mSubType;
}

- (void) setLatency:(double)latency
{
	mLatency = latency;
	if (mLatency < 0.) mLatency = 0.;
}

- (void) setLatencySamples:(double)latencySamples
{
	mLatencySamples = latencySamples;
	if (mLatencySamples < 0.) mLatencySamples = 0.;
}

- (void) setTailTime:(double)tailTime
{
	mTailTime = tailTime;
	if (mTailTime < 0.) mTailTime = 0.;
}

- (void) setSubType:(const char *)subType
{
	if (strlen(subType) < 4) return;
	
	memcpy(mSubType, subType, 4);

	int i;
	for (i = 0; i < 4; i++)
	{
		char c = mSubType[i];
		
		if (c >= 'A' && c <= 'Z') continue;
		if (c >= 'a' && c <= 'z') continue;
		if (c >= '0' && c <= '9') continue;
		if (c == '!' || c == '@' || c == '#' || c == '$' || c == '%') continue;
		if (c == '?' || c == '&' || c == '*' || c == '(' || c == ')') continue;
		if (c == '-' || c == '+' || c == '_' || c == '=' || c == '/') continue;
		if (c == '\\' || c == ';' || c == ':' || c == '.' || c == ',') continue;
		if (c == '\'' || c == '"' || c == '[' || c == ']' || c == '{' || c == '}') continue;

		// illegal charater
		// replace with '_'

		mSubType[i] = '_';
	}
}

- (void) setName:(NSString*)name
{
	[mName setString:stringFix(name)];
}

- (void) addElement:(SBElement*)element
{
	// if adding an internal, remove any we may have created automatically
	if ([element isKindOfClass:[SBRootCircuitInterpolation class]])
	{
		SBRootCircuitInterpolation *rci = [self rciElement];
		if (rci)
			[super removeElement:rci];
	}
	else if ([element isKindOfClass:[SBRootCircuitPrecision class]])
	{
		SBRootCircuitPrecision *rcp = [self rcpElement];
		if (rcp)
			[super removeElement:rcp];
	}
	else if ([element isKindOfClass:[SBRootCircuitMidi class]])
	{
		SBRootCircuitMidi *rcm = [self rcmElement];
		if (rcm)
			[super removeElement:rcm];
			
		[(SBRootCircuitMidi *)element setParent:self];
	}

	// let super do its job
	[super addElement:element];
	
	// add automatic internal if needed
	if ([self interpolates])
	{
		if (![self rciElement])
		{
			SBRootCircuitInterpolation *rci = [[SBRootCircuitInterpolation alloc] init];
			if (rci)
			{
				[rci setOriginX:100 Y:100];
				[super addElement:rci];
				[rci release];
			}
		}
	}
	
	if ([self hasMidiArguments])
	{
		SBRootCircuitMidi *rcm = [self rcmElement];
		if (!rcm)
		{
			rcm = [[SBRootCircuitMidi alloc] init];
			if (rcm)
			{
				[rcm setOriginX:100 Y:100];
				[rcm setParent:self];
				[super addElement:rcm];
				[rcm release];
			}
		}
		if (rcm)
			[rcm updateItems];
	}
	
	if ([element isKindOfClass:[SBArgument class]])
	{
		[mPresetArray removeAllObjects];
	}
	
	if (mArgumentTableView) [mArgumentTableView reloadData];
	if (mPresetTableView) [mPresetTableView reloadData];
}

- (void) removeElement:(SBElement*)element
{
	if (!element) return;
	
	[mSelectedList removeElement:element];

	if ([element isKindOfClass:[SBRootCircuitPrecision class]]) return;
	if ([element isKindOfClass:[SBRootCircuitInterpolation class]]) return;
	if ([element isKindOfClass:[SBRootCircuitMidi class]]) return;
	
	[element retain];
	[super removeElement:element];
	
	if (![self interpolates])
	{
		SBRootCircuitInterpolation *rci = [self rciElement];
		if (rci)
			[super removeElement:rci];
	}

	if (![self hasMidiArguments])
	{
		SBRootCircuitMidi *rcm = [self rcmElement];
		if (rcm)
			[super removeElement:rcm];
	}
	else
	{
		[[self rcmElement] updateItems];
	}
	
	if ([element isKindOfClass:[SBArgument class]])
	{
		NSUInteger idx = [mArgumentArray indexOfObjectIdenticalTo:element];
		if (idx != NSNotFound)
		{
			int c = [mPresetArray count], i;
			for (i = 0; i < c; i++)
			{
				SBPreset *preset = [mPresetArray objectAtIndex:i];
				[preset deleteValueAtIndex:idx];
			}
		}
	}
	
	[element release];
	
	if (mArgumentTableView) [mArgumentTableView reloadData];
	if (mPresetTableView) [mPresetTableView reloadData];
}

- (void) subElementDidChangeGlobalView:(NSNotification *)notification
{
	[super subElementDidChangeGlobalView:notification];
	
	if (mArgumentTableView && [mArgumentTableView window])
		[mArgumentTableView reloadData];  // arg may have changed name
}


- (NSData*) currentState
{
	int c = [mArgumentArray count], i;
	if (!c) return nil;

	SBPreset *preset = [[[SBPreset alloc] init] autorelease];
	if (!preset) return nil;
	
	for (i = 0; i < c; i++)
	{
		SBArgument *a = [mArgumentArray objectAtIndex:i];
		[preset appendObject:[a savePreset]];
	}
	
	return [preset saveData];
}

- (void) loadState:(NSData*)state
{
	SBPreset *preset = [[[SBPreset alloc] init] autorelease];
	if (!preset) return;
	
	BOOL isOK = [preset loadData:state];
	if (!isOK) return;
	
	int c = [mArgumentArray count], i;
	for (i = 0; i < c; i++)
	{
		SBArgument *a = [mArgumentArray objectAtIndex:i];
		[a loadPreset:[preset objectAtIndex:i]];
	}
}

- (void) createPreset
{
	int c = [mArgumentArray count], i;
	if (!c) return;

	SBPreset *preset = [[SBPreset alloc] init];
	if (!preset) return;
	
	for (i = 0; i < c; i++)
	{
		SBArgument *a = [mArgumentArray objectAtIndex:i];
		[preset appendObject:[a savePreset]];
	}
	
	[mPresetArray addObject:preset];
	[preset release];
}

- (void) setPreset:(int)idx
{
	int c = [mPresetArray count], i;
	if (idx < 0 || idx >= c) return;

	SBPreset *preset = [mPresetArray objectAtIndex:idx];
	
	c = [mArgumentArray count];
	for (i = 0; i < c; i++)
	{
		SBArgument *a = [mArgumentArray objectAtIndex:i];
		[a loadPreset:[preset objectAtIndex:i]];
	}
	
	[self didChangeView];
}

- (void) deletePreset:(int)idx
{
	int c = [mPresetArray count];
	if (idx < 0 || idx >= c) return;
	
	[mPresetArray removeObjectAtIndex:idx];
}

- (int) numberOfPresets
{
	return [mPresetArray count];
}

- (SBPreset*) presetAtIndex:(int)idx
{
	int c = [mPresetArray count];
	if (idx < 0 || idx >= c) return nil;
	
	return [mPresetArray objectAtIndex:idx];
}

- (void) moveUpPreset:(int)idx
{
	int c = [mPresetArray count];
	if (idx <= 0) return;
	if (idx >= c) return;
	
	int a = idx - 1;
	int b = idx;
	
	[mPresetArray exchangeObjectAtIndex:a withObjectAtIndex:b];
}

- (void) moveDownPreset:(int)idx
{
	int c = [mPresetArray count];
	if (idx < 0) return;
	if (idx >= c - 1) return;
	
	int a = idx;
	int b = idx + 1;
	
	[mPresetArray exchangeObjectAtIndex:a withObjectAtIndex:b];
}

- (void) moveUpArgument:(int)idx
{
	int c = [mArgumentArray count];
	if (idx <= 0) return;
	if (idx >= c) return;
	
	int a = idx - 1;
	int b = idx;
	
	SBElement *ea = [mArgumentArray objectAtIndex:a];
	SBElement *eb = [mArgumentArray objectAtIndex:b];
	
	[mArgumentArray exchangeObjectAtIndex:a withObjectAtIndex:b];
	
	a = [mElementArray indexOfObjectIdenticalTo:ea];
	b = [mElementArray indexOfObjectIdenticalTo:eb];
	
	[mElementArray exchangeObjectAtIndex:a withObjectAtIndex:b];
}

- (void) moveDownArgument:(int)idx
{
	int c = [mArgumentArray count];
	if (idx < 0) return;
	if (idx >= c - 1) return;
	
	int a = idx;
	int b = idx + 1;
	
	SBElement *ea = [mArgumentArray objectAtIndex:a];
	SBElement *eb = [mArgumentArray objectAtIndex:b];
	
	[mArgumentArray exchangeObjectAtIndex:a withObjectAtIndex:b];
	
	a = [mElementArray indexOfObjectIdenticalTo:ea];
	b = [mElementArray indexOfObjectIdenticalTo:eb];
	
	[mElementArray exchangeObjectAtIndex:a withObjectAtIndex:b];
}


- (NSMutableDictionary*) saveData
{
	NSMutableArray *ma;
	int c, i;
	NSData *dt;
	NSNumber *n;
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:kCurrentVersionNSString forKey:@"sonicbirth_version"];
	
	[md setObject:mAuthor forKey:@"author"];
	[md setObject:mCompany forKey:@"company"];
	[md setObject:mPluginDescription forKey:@"pluginDescription"];

	n = [NSNumber numberWithInt:(mHasCustomGui) ? 2 : 1];
	[md setObject:n forKey:@"hasCustomGui"];
	
	n = [NSNumber numberWithInt:(mMiniMode) ? 2 : 1];
	[md setObject:n forKey:@"miniMode"];
	
	n = [NSNumber numberWithInt:(mGuiMode == kCircuitDesign) ? 1 : ((mGuiMode == kGuiDesign) ? 2 : 3)];
	[md setObject:n forKey:@"guiMode"];
	
	n = [NSNumber numberWithInt:mGuiSize.width];
	[md setObject:n forKey:@"guiWidth"];
	
	n = [NSNumber numberWithInt:mGuiSize.height];
	[md setObject:n forKey:@"guiHeight"];

	n = [NSNumber numberWithDouble:mLatency];
	[md setObject:n forKey:@"latency"];
	
	n = [NSNumber numberWithDouble:mLatencySamples];
	[md setObject:n forKey:@"latencySamples"];
	
	n = [NSNumber numberWithDouble:mTailTime];
	[md setObject:n forKey:@"tailTime"];
	
	n = [NSNumber numberWithInt:(mNeedsTempo) ? 2 : 1];
	[md setObject:n forKey:@"needsTempo"];
	
	n = [NSNumber numberWithInt:(mHasSideChain) ? 2 : 1];
	[md setObject:n forKey:@"hasSideChain"];
	
	n = [NSNumber numberWithUnsignedInt:*(unsigned int*)mSubType];
	[md setObject:n forKey:@"subType"];
	
	ma = [[NSMutableArray alloc] init];
		c = [mPresetArray count];
		for (i = 0; i < c; i++)
		{
			SBPreset *p = [mPresetArray objectAtIndex:i];
			NSMutableDictionary *mde = [[NSMutableDictionary alloc] init];
			
			NSString *name = [[p name] copy];
				[mde setObject:name forKey:@"name"];
			[name release];
			
			[mde setObject:[p saveData] forKey:@"data"];
			
			[ma addObject:mde];
			[mde release];
		}
	[md setObject:ma forKey:@"PresetArray"];
	[ma release];
	
	dt = [NSArchiver archivedDataWithRootObject:mColorBack];
	[md setObject:dt forKey:@"backColor"];
	
	dt = [NSArchiver archivedDataWithRootObject:mColorContour];
	[md setObject:dt forKey:@"contourColor"];
	
	dt = [NSArchiver archivedDataWithRootObject:mColorFront];
	[md setObject:dt forKey:@"frontColor"];
	
	if (mBgImageData)
		[md setObject:mBgImageData forKey:@"imageData"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	if (!data) return NO;

	int c, i;
	NSData *dt;
	NSArray *a;
	NSString *s;
	NSNumber *n;
	
	n = [data objectForKey:@"needsTempo"];
	if (n) mNeedsTempo = ([n intValue] == 2);
	
	n = [data objectForKey:@"hasSideChain"];
	if (n) mHasSideChain = ([n intValue] == 2);
	
	if (![super loadData:data]) return NO;

	s = [data objectForKey:@"author"];
	if (s) [self setAuthor:s];
	
	s = [data objectForKey:@"company"];
	if (s) [self setCompany:s];
	
	s = [data objectForKey:@"pluginDescription"];
	if (s) [self setPluginDescription:s];
	
	n = [data objectForKey:@"hasCustomGui"];
	if (n) mHasCustomGui = ([n intValue] == 2);
	
	n = [data objectForKey:@"miniMode"];
	if (n)
	{
		mMiniMode = ([n intValue] == 2);
		[self setMiniMode:mMiniMode];
	}
	
	n = [data objectForKey:@"guiMode"];
	if (n)
	{
		int intVal = [n intValue];
		mGuiMode = (intVal == 1) ? kCircuitDesign : ((intVal == 2) ? kGuiDesign : kRuntime);
		[self setGuiMode:mGuiMode];
	}
	
	n = [data objectForKey:@"guiWidth"];
	if (n) { mGuiSize.width = [n intValue]; if (mGuiSize.width < kGuiMinSize) mGuiSize.width = kGuiMinSize; }
	
	n = [data objectForKey:@"guiHeight"];
	if (n) { mGuiSize.height = [n intValue]; if (mGuiSize.height < kGuiMinSize) mGuiSize.height = kGuiMinSize; }
	
	n = [data objectForKey:@"latency"];
	if (n) mLatency = [n doubleValue];
	
	n = [data objectForKey:@"latencySamples"];
	if (n) mLatencySamples = [n doubleValue];
	
	n = [data objectForKey:@"tailTime"];
	if (n) mTailTime = [n doubleValue];
	
	n = [data objectForKey:@"subType"];
	if (n) *(unsigned int*)mSubType = [n unsignedIntValue];
	
	a = [data objectForKey:@"PresetArray"];
	if (a)
	{
		c = [a count];
		for (i = 0; i < c; i++)
		{
			NSDictionary *d = [a objectAtIndex:i];
			
			s = [d objectForKey:@"name"];
			if (s)
			{
				SBPreset *p = [[SBPreset alloc] init];
				if (p)
				{
					[p setName:s];
					
					BOOL isOK = [p loadData:[d objectForKey:@"data"]];
					if (isOK) [mPresetArray addObject:p];
					
					[p release];
				}
			}
		}
	}
	
	dt = [data objectForKey:@"backColor"];
	if (dt)
	{
		[mColorBack release];
		mColorBack = [(NSColor *)[NSUnarchiver unarchiveObjectWithData:dt] retain];
	}
	
	dt = [data objectForKey:@"contourColor"];
	if (dt)
	{
		[mColorContour release];
		mColorContour = [(NSColor *)[NSUnarchiver unarchiveObjectWithData:dt] retain];
	}
	
	dt = [data objectForKey:@"frontColor"];
	if (dt)
	{
		[mColorFront release];
		mColorFront = [(NSColor *)[NSUnarchiver unarchiveObjectWithData:dt] retain];
	}
	
	dt = [data objectForKey:@"imageData"];
	if (dt)
	{
		NSImage *image = [[NSImage alloc] initWithData:dt];
		if (image)
		{
			mBgImage = [image toOgImage];
			[image release];
		}
		
		if (mBgImage)
		{
			mBgImageData = [[NSData dataWithData:dt] retain];
		}	
	}
	
	[self setColorsBack:mColorBack contour:mColorContour front:mColorFront];
	
	// force refresh of setting view
	[self awakeFromNib];
	
	return YES;
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBRootCircuit" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	if (!mSettingsView) return;

	[super awakeFromNib];
	
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
	
	[mColorWellBack setColor:mColorBack];
	[mColorWellContour setColor:mColorContour];
	[mColorWellFront setColor:mColorFront];
	
	[mAuthorTF setStringValue:[self author]];
	[mCompanyTF setStringValue:[self company]];
	[mPluginDescriptionTF setStringValue:[self pluginDescription]];
	
	[mLatencyTF setDoubleValue:mLatency];
	[mLatencySamplesTF setDoubleValue:mLatencySamples];
	[mTailTimeTF setDoubleValue:mTailTime];
	
	char subType[5]; subType[4] = 0;
	memcpy(subType, [self subType], 4);
	[mSubTypeTF setStringValue:[NSString stringWithCString:subType]];
	
	[mArgumentTableView reloadData];
	[mPresetTableView reloadData];
	
	[mHasCustomGuiBt setState:(mHasCustomGui) ? NSOnState : NSOffState];
	
	[mGuiModeBt setEnabled:mHasCustomGui];
	[mGuiWidthTF setEnabled:mHasCustomGui];
	[mGuiHeightTF setEnabled:mHasCustomGui];
	[mLoadBgImage setEnabled:mHasCustomGui];
	[mClearBgImage setEnabled:mHasCustomGui];
	[mTakeBgImageSize setEnabled:mHasCustomGui];
	
	if (!mHasCustomGui)
	{
		[mGuiModeBt selectCellAtRow:0 column:0];
	}
	else
	{
		int i = (mGuiMode == kCircuitDesign) ? 0 : ((mGuiMode == kGuiDesign) ? 1 : 2);
		[mGuiModeBt selectCellAtRow:0 column:i];
		[mClearBgImage setEnabled:(mBgImage != nil)];
		[mTakeBgImageSize setEnabled:(mBgImage != nil)];
	}
	
	[mGuiWidthTF setIntValue:mGuiSize.width];
	[mGuiHeightTF setIntValue:mGuiSize.height];
	
	if (mMainScrollView)
	{
		// try to scroll to top left
		NSClipView *clipView = [mMainScrollView contentView];
		NSClipView *docView = [mMainScrollView documentView];
		NSSize ctSize = [clipView frame].size;
		NSSize docSize = [docView frame].size;
		NSPoint pt = {0, docSize.height - ctSize.height};
		[clipView scrollToPoint:pt];
		[mMainScrollView reflectScrolledClipView:clipView];
	}
	
	[mSideChainButton setState:(mHasSideChain) ? NSOnState: NSOffState];
	[mTempoButton setState:(mNeedsTempo) ? NSOnState: NSOffState];
	[mLatencySamplesTF setDoubleValue:mLatencySamples];
	
	[mSideChainButton setEnabled:mCanChangeHasSideChain];
}

- (void) controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if ((tf == mNumberOfInputTF) ||
		(tf == mNumberOfOutputTF) ||
		(tf == mNameTF) ||
		(tf == mCommentsTF) ||
		(tf == mWidthTF) ||
		(tf == mHeightTF))
	{	
		[super controlTextDidEndEditing:aNotification];
		return;
	}

	if (tf == mAuthorTF)
	{
		[self setAuthor:[mAuthorTF stringValue]];
		[mAuthorTF setStringValue:[self author]];
	}
	else if (tf == mCompanyTF)
	{
		[self setCompany:[mCompanyTF stringValue]];
		[mCompanyTF setStringValue:[self company]];
	}
	else if (tf == mPluginDescriptionTF)
	{
		[self setPluginDescription:[mPluginDescriptionTF stringValue]];
		[mPluginDescriptionTF setStringValue:[self pluginDescription]];
	}
	else if (tf == mLatencyTF)
	{
		[self setLatency:[mLatencyTF doubleValue]];
		[mLatencyTF setDoubleValue:[self latency]];
	}
	else if (tf == mLatencySamplesTF)
	{
		[self setLatencySamples:[mLatencySamplesTF doubleValue]];
		[mLatencySamplesTF setDoubleValue:[self latencySamples]];
	}
	else if (tf == mTailTimeTF)
	{
		[self setTailTime:[mTailTimeTF doubleValue]];
		[mTailTimeTF setDoubleValue:[self tailTime]];
	}
	else if (tf == mSubTypeTF)
	{
		NSString *newSubType = [mSubTypeTF stringValue];
		if ([newSubType length] < 4) newSubType = [NSString stringWithFormat:@"%@_____", newSubType];
		
		const char *cstring = [newSubType cString];
		BOOL applyChange = YES;
	
		if ((*cstring == 'S') && (*[self subType] != 'S'))
		{
			int choice = NSRunAlertPanel(@"SonicBirth",
							@"Subtypes beginning by a capital 'S' are reserved for prebuilt plugins. "
							@"Are you sure you want to continue?",
							@"Revert", @"Continue", nil);
									
			if (choice == NSAlertDefaultReturn) applyChange = NO;
		}
		
		if (applyChange) [self setSubType:cstring];
		
		char subType[5]; subType[4] = 0;
		memcpy(subType, [self subType], 4);
		[mSubTypeTF setStringValue:[NSString stringWithCString:subType]];
	}
	else if (tf == mGuiWidthTF)
	{
		int w = [mGuiWidthTF intValue];
		if (w < kGuiMinSize) w = kGuiMinSize;
		mGuiSize.width = w;
		[mGuiWidthTF setIntValue:w];
		[self didChangeMinSize];
	}
	else if (tf == mGuiHeightTF)
	{
		int h = [mGuiHeightTF intValue];
		if (h < kGuiMinSize) h = kGuiMinSize;
		mGuiSize.height = h;
		[mGuiHeightTF setIntValue:h];
		[self didChangeMinSize];
	}
}

- (void) moveUpArgumentBt:(id)sender
{
	int i = [mArgumentTableView selectedRow];
	if (i == -1) return;
	
	[self moveUpArgument:i];
	[mArgumentTableView selectRow:i-1 byExtendingSelection:NO];
	[mArgumentTableView reloadData];
}

- (void) moveDownArgumentBt:(id)sender
{
	int i = [mArgumentTableView selectedRow];
	if (i == -1) return;
	
	[self moveDownArgument:i];
	[mArgumentTableView selectRow:i+1 byExtendingSelection:NO];
	[mArgumentTableView reloadData];
}

- (void) moveUpPresetBt:(id)sender
{
	int i = [mPresetTableView selectedRow];
	if (i == -1) return;
	
	[self moveUpPreset:i];
	[mPresetTableView selectRow:i-1 byExtendingSelection:NO];
	[mPresetTableView reloadData];
}

- (void) moveDownPresetBt:(id)sender
{
	int i = [mPresetTableView selectedRow];
	if (i == -1) return;
	
	[self moveDownPreset:i];
	[mPresetTableView selectRow:i+1 byExtendingSelection:NO];
	[mPresetTableView reloadData];
}

- (void) createPresetBt:(id)sender
{
	[self createPreset];
	[mPresetTableView reloadData];
}

- (void) setPresetBt:(id)sender
{
	int i = [mPresetTableView selectedRow];
	if (i == -1) return;
	
	[self setPreset:i];
}

- (void) deletePresetBt:(id)sender
{
	int i = [mPresetTableView selectedRow];
	if (i == -1) return;
	
	[self deletePreset:i];
	[mPresetTableView reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == mArgumentTableView)
		return [self numberOfArguments];
	else if (aTableView == mPresetTableView)
		return [self numberOfPresets];
	else
		return [super numberOfRowsInTableView:aTableView];
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *ident = [aTableColumn identifier];
	
	if (aTableView == mArgumentTableView)
	{
		SBArgument *a = [self argumentAtIndex:rowIndex];
		if (!a) return nil;
		
		if ([ident isEqual:@"index"])
			return [NSNumber numberWithInt:rowIndex];
		else if ([ident isEqual:@"name"])
			return [a name];
		else if ([ident isEqual:@"type"])
			return [[a class] name];

	}
	else if (aTableView == mPresetTableView)
	{
		SBPreset *p = [self presetAtIndex:rowIndex];
		if (!p) return nil;
		
		if ([ident isEqual:@"index"])
			return [NSNumber numberWithInt:rowIndex];
		else if ([ident isEqual:@"name"])
			return [p name];
	}
	else
		return [super tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *ident = [aTableColumn identifier];
	if (![ident isEqual:@"name"]) return;
	
	if (aTableView == mArgumentTableView)
	{
		SBArgument *a = [self argumentAtIndex:rowIndex];
		if (!a) return;
		
		if ([anObject isKindOfClass:[NSString class]])
			[a setName:anObject];
	}
	else if (aTableView == mPresetTableView)
	{
		SBPreset *p = [self presetAtIndex:rowIndex];
		if (!p) return;
		
		if ([anObject isKindOfClass:[NSString class]])
			[p setName:anObject];
	}
	else
		[super tableView:aTableView setObjectValue:anObject forTableColumn:aTableColumn row:rowIndex];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *aTableView = [aNotification object];
	if (aTableView == mArgumentTableView)
	{
		int c = [self numberOfArguments];
		int i = [mArgumentTableView selectedRow];
		
		if (c <= 1 || i == -1)
		{
			[mArgumentMoveUp setEnabled:NO];
			[mArgumentMoveDown setEnabled:NO];
		}
		else
		{
			if (i == 0) [mArgumentMoveUp setEnabled:NO];
			else [mArgumentMoveUp setEnabled:YES];
			
			if (i == c - 1) [mArgumentMoveDown setEnabled:NO];
			else [mArgumentMoveDown setEnabled:YES];
		}
	}
	else if (aTableView == mPresetTableView)
	{
		int c = [self numberOfPresets];
		int i = [mPresetTableView selectedRow];
		
		[mPresetSet setEnabled:(i != -1)];
		[mPresetDelete setEnabled:(i != -1)];
		
		if (c <= 1 || i == -1)
		{
			[mPresetMoveUp setEnabled:NO];
			[mPresetMoveDown setEnabled:NO];
		}
		else
		{
			if (i == 0) [mPresetMoveUp setEnabled:NO];
			else [mPresetMoveUp setEnabled:YES];
			
			if (i == c - 1) [mPresetMoveDown setEnabled:NO];
			else [mPresetMoveDown setEnabled:YES];
		}
	}
}

- (SBPrecision) precision
{
	return mPrecision;
}
- (SBInterpolation) interpolation
{
	return mInterpolation;
}

- (SBRootCircuitInterpolation*) rciElement
{
	int c = [mArgumentArray count], i;
	for (i = 0; i < c; i++)
	{
		SBArgument *a = [mArgumentArray objectAtIndex:i];
		if ([a isKindOfClass:[SBRootCircuitInterpolation class]])
				return (SBRootCircuitInterpolation*)a;
	}
	return nil;
}

- (SBRootCircuitPrecision*) rcpElement
{
	int c = [mArgumentArray count], i;
	for (i = 0; i < c; i++)
	{
		SBArgument *a = [mArgumentArray objectAtIndex:i];
		if ([a isKindOfClass:[SBRootCircuitPrecision class]])
				return (SBRootCircuitPrecision*)a;
	}
	return nil;
}

- (SBRootCircuitMidi*) rcmElement
{
	int c = [mArgumentArray count], i;
	for (i = 0; i < c; i++)
	{
		SBArgument *a = [mArgumentArray objectAtIndex:i];
		if ([a isKindOfClass:[SBRootCircuitMidi class]])
				return (SBRootCircuitMidi*)a;
	}
	return nil;
}

- (void) changedColor:(id)sender
{
	NSColor *back = [[mColorWellBack color] retain];
	NSColor *contour = [[mColorWellContour color] retain];
	NSColor *front = [[mColorWellFront color] retain];

	[mColorBack release];
	[mColorContour release];
	[mColorFront release];
	
	[self setColorsBack:back contour:contour front:front];
	
	[self didChangeGlobalView];
}

- (BOOL) hasCustomGui
{
	return mHasCustomGui;
}

- (void) changedHasCustomGui:(id)sender
{
	mHasCustomGui = ([mHasCustomGuiBt state] == NSOnState);
	[mGuiModeBt setEnabled:mHasCustomGui];
	[mGuiWidthTF setEnabled:mHasCustomGui];
	[mGuiHeightTF setEnabled:mHasCustomGui];
	[mLoadBgImage setEnabled:mHasCustomGui];
	[mClearBgImage setEnabled:mHasCustomGui];
	[mTakeBgImageSize setEnabled:mHasCustomGui];
	if (!mHasCustomGui)
	{
		[self setGuiMode:kCircuitDesign];
		[mGuiModeBt selectCellAtRow:0 column:0];
		mGuiMode = kCircuitDesign;
		[super setGuiMode:mGuiMode];
	}
	else
	{
		[mClearBgImage setEnabled:(mBgImage != nil)];
		[mTakeBgImageSize setEnabled:(mBgImage != nil)];
	}
	[self didChangeMinSize];
	[self didChangeGlobalView];
}

- (void) changedGuiMode:(id)sender
{
	int i = [mGuiModeBt selectedColumn];
	if (i < 0) i = 0; else if (i > 2) i = 2;
	SBGuiMode mode;
	if (i == 0) mode = kCircuitDesign;
	else if (i == 1) mode = kGuiDesign;
	else mode = kRuntime;
	if (mode != mGuiMode)
	{
		[self setGuiMode:mode];
		[self didChangeMinSize];
		[self didChangeGlobalView];
	}
}

- (void)updateGUIModeMatrixFromInternalState
{
	if ([mGuiModeBt selectedColumn] != mGuiMode)
		{ [mGuiModeBt selectCellWithTag:mGuiMode]; }
}

- (BOOL) minSizeIsMaxSize
{
	return (mGuiMode != kCircuitDesign);
}

- (NSSize) circuitMinSize
{
	if (mGuiMode == kCircuitDesign)
		return [super circuitMinSize];
	return mGuiSize;
}

- (void) setCircuitSize:(NSSize)s
{
	if (mGuiMode == kCircuitDesign)
	{
		[super setCircuitSize:s];
		return;
	}

	mCircuitSize = mGuiSize;
}

- (void) setCircuitMinSize:(NSSize)s
{
	if (mGuiMode == kCircuitDesign)
	{
		[super setCircuitMinSize:s];
		return;
	}

	mGuiSize = s;
	if (mGuiSize.width < kGuiMinSize) mGuiSize.width = kGuiMinSize;
	if (mGuiSize.height < kGuiMinSize) mGuiSize.height = kGuiMinSize;
	
	if (mGuiWidthTF) [mGuiWidthTF setFloatValue:mGuiSize.width];
	if (mGuiHeightTF) [mGuiHeightTF setFloatValue:mGuiSize.height];
	
	[self didChangeMinSize];
}

- (void) loadBgImage:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	
	[op setCanChooseFiles:YES];
	[op setCanChooseDirectories:NO];
	[op setAllowsMultipleSelection:NO];
	
	int result = [op runModalForTypes:[NSArray arrayWithObjects:@"jpg", @"jpeg", @"tif", @"tiff", @"png", @"gif", nil]];
	if (result != NSOKButton) return;
	
	NSString *path = [op filename];
	
	NSData *dt = [NSData dataWithContentsOfFile:path];
	if (!dt) return;
	
	NSImage *im = [[NSImage alloc] initWithData:dt];
	if (!im) return;
	
	if (mBgImage) ogReleaseImage(mBgImage);
	if (mBgImageData) [mBgImageData release];
	
	mBgImageData = [dt retain];
	mBgImage = [im toOgImage];
	[im release];
	
	if (!mBgImage && mBgImageData) { [mBgImageData release]; mBgImageData = nil; }
	
	[self didChangeGlobalView];
	[mClearBgImage setEnabled:YES];
	[mTakeBgImageSize setEnabled:YES];
}

- (void) clearBgImage:(id)sender
{
	if (mBgImage) ogReleaseImage(mBgImage);
	if (mBgImageData) [mBgImageData release];
	
	mBgImage = nil;
	mBgImageData = nil;
	
	
	[self didChangeGlobalView];
	[mClearBgImage setEnabled:NO];
	[mTakeBgImageSize setEnabled:NO];
}

- (void) takeBgImageSize:(id)sender
{
	if (!mBgImage) return;
	
	NSSize s = { ogImageWidth(mBgImage), ogImageHeight(mBgImage) };
	
	mGuiSize = s;
	if (mGuiSize.width < kGuiMinSize) mGuiSize.width = kGuiMinSize;
	if (mGuiSize.height < kGuiMinSize) mGuiSize.height = kGuiMinSize;
	
	[mGuiWidthTF setIntValue:mGuiSize.width];
	[mGuiHeightTF setIntValue:mGuiSize.height];
	[self didChangeMinSize];
}

- (void) drawRect:(NSRect)rect
{
	if ((!mActsAsCircuit) || (mGuiMode == kCircuitDesign) || (!mBgImage))
	{
		[super drawRect:rect];
		return;
	}
	

	//[mBgImage compositeToPoint:origin operation:NSCompositeSourceOver];
	ogDrawImage(mBgImage, 0, 0);
	
	[super drawRect:rect];
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
			
	pPrecision = mPrecision;	
}

- (NSString*) company
{
	return mCompany;
}

- (void) setCompany:(NSString*)company
{
	[mCompany setString:stringFix(company)];
}

- (NSString*) pluginDescription
{
	return mPluginDescription;
}

- (void) setPluginDescription:(NSString*)pluginDescription
{
	[mPluginDescription setString:stringFix(pluginDescription)];
}

- (void) changeInputType:(int)idx newType:(SBConnectionType)type
{
	return;
}

- (void) changeOutputType:(int)idx newType:(SBConnectionType)type
{
	return;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	return kNormal;
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	return kNormal;
}

- (BOOL) hasSideChain
{
	return mHasSideChain;
}

- (BOOL) needsTempo
{
	return mNeedsTempo;
}

- (void) changedHasSideChain:(id)sender
{
	[self setHasSideChain:([mSideChainButton state] == NSOnState)];
}

- (void) setHasSideChain:(BOOL)has
{
	[self willChangeAudio];

	BOOL hadSideChain = mHasSideChain;
	mHasSideChain = has;
	
	if (!mHasSideChain && hadSideChain)
	{
		int max = [self numberOfInputs];
		int c = [mWireArray count], i;
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
	[self didChangeView];
	[self didChangeAudio];
}

- (void) setCanChangeHasSideChain:(BOOL)canChange
{
	mCanChangeHasSideChain = canChange;
	if (mSideChainButton) [mSideChainButton setEnabled:mCanChangeHasSideChain];
}

- (void) changedNeedsTempo:(id)sender
{
	[self willChangeAudio];
	
	BOOL hadTempo = mNeedsTempo;
	mNeedsTempo = [mTempoButton state] == NSOnState;
	
	if (mNeedsTempo && !hadTempo)
	{
		int c = [mWireArray count], i;
		for (i = 0; i < c; i++)
		{
			SBWire *wire = [mWireArray objectAtIndex:i];
			if ([wire outputElement] == self)
			{
				[wire setOutputIndex:[wire outputIndex] + 2];
				mIsCompiled = NO;
			}
		}
	}
	else if (!mNeedsTempo && hadTempo)
	{
		int c = [mWireArray count], i;
		for (i = 0; i < c; i++)
		{
			SBWire *wire = [mWireArray objectAtIndex:i];
			if ([wire outputElement] == self)
			{
				int oi = [wire outputIndex];
				if (oi < 2)
				{
					[mWireArray removeObject:wire]; mIsCompiled = NO;
					i--; c--;
				}
				else
				{
					[wire setOutputIndex:oi - 2];
					mIsCompiled = NO;
				}
			}
		}
	}
	
	[self didChangeConnections];
	[self didChangeView];
	[self didChangeAudio];
}

- (int) numberOfInputs
{
	int count = [mInputNames count];
	if (mHasSideChain) count *= 2;
	if (mNeedsTempo) count += 2;
	return count;
}

- (NSString*) nameOfInputAtIndex:(int)idx
{
	if (idx < 0) return nil;
	if (idx >= [self numberOfInputs]) return nil;
	
	if (mNeedsTempo)
	{
		if (idx == 0) return @"Tempo";
		else if (idx == 1) return @"Beat";
		else idx -= 2;
	}
	
	int count = [mInputNames count];
	if (idx < count)
		return [mInputNames objectAtIndex:idx];
	else
		return [NSString stringWithFormat:@"%@ (side)", [mInputNames objectAtIndex:idx - count]];
}

- (void) changeInputName:(int)idx newName:(NSString*)newName
{
	int min = (mNeedsTempo) ? 2 : 0;
	if (idx < min) return;
	if (idx >= [mInputNames count] + min) return;

	return [super changeInputName:idx newName:newName];
}

- (void) setNumberOfInputs:(int)count
{
	int max = (kMaxChannels/2 - 5);
	if (count > max) count = max;
	[super setNumberOfInputs:count];
}

- (void) setNumberOfOutputs:(int)count
{
	if (count < 1) count = 1;
	[super setNumberOfOutputs:count];
}

- (int) numberOfRealInputs
{
	return [mInputNames count];
}

- (void) shareArgumentsFrom:(SBCircuit*)circuit shareCount:(int)shareCount
{
	if (circuit == self) return;

	[super shareArgumentsFrom:circuit shareCount:shareCount];
	
	// release bg image to save some memory
	if (mBgImageData) [mBgImageData release];
	if (mBgImage) ogReleaseImage(mBgImage);
	
	mBgImageData = nil;
	mBgImage = nil;
}

- (void) clearState
{
	[super clearState];
	
	[mPresetArray removeAllObjects];
	
	if (mBgImage) { ogReleaseImage(mBgImage); mBgImage = nil; }
	if (mBgImageData) { [mBgImageData release]; mBgImageData = nil; }
}

@end
