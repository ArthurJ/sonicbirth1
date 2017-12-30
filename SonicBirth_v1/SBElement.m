/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBElement.h"
#import "SBCell.h"
#import "SBDefaultCell.h"

NSString *kSBElementWillChangeAudioNotification = @"kSBElementWillChangeAudioNotification";
NSString *kSBElementDidChangeAudioNotification = @"kSBElementDidChangeAudioNotification";
NSString *kSBElementDidChangeViewNotification = @"kSBElementDidChangeViewNotification";
NSString *kSBElementDidChangeGlobalViewNotification = @"kSBElementDidChangeGlobalViewNotification";
NSString *kSBElementDidChangeConnectionsNotification = @"kSBElementDidChangeConnectionsNotification";

NSMutableDictionary *gTextAttributes = nil;

static int gInited = 0;
ogColor gSelectedColor = { 1, 1, 1, 1 };

static NSString* gCategoryNames[kCategoryCount] =
{
	@"Common",
	
	@"Algebraic",
	@"Function",
	@"Trigonometric",
	
	@"Arguments ",
	@"Midi arguments",
	@"Display",
	
	@"Analysis",
	@"Comparators",
	@"Converters",
	@"Delays",
	@"Generators",
	@"Filters",
	@"Feedback",
	@"Distortion",
	@"Audio file",
	@"FFT",
	
	@"Miscellaneous",
	@"Internal"
};

#define kMiniSize 8.f

@implementation SBElement

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mSampleRate = 0;
		mSampleCount = 0;
		mPrecision = kFloatPrecision;
		mInterpolation = kNoInterpolation;
		mAudioBuffersCount = 0;
		mLastCircuit = YES;
		
		mGuiOrigin.x = mGuiOrigin.y = 100;
		mGuiMode = kCircuitDesign;
	
		mInputNames = [[NSMutableArray alloc] init];
		if (!mInputNames)
		{
			[self release];
			return nil;
		}
		
		mOutputNames = [[NSMutableArray alloc] init];
		if (!mOutputNames)
		{
			[self release];
			return nil;
		}
		
		mIsSelected = NO;
		mCalculatedFrame = NO;
		mImage = nil;
		
		if (!gTextAttributes)
		{
			gTextAttributes = [[NSMutableDictionary alloc] init];
			
			// align center
			NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
			[ps setAlignment:NSCenterTextAlignment];
			[gTextAttributes setObject:ps forKey:NSParagraphStyleAttributeName];
			[ps release];
		
			// set font
			NSFont *ft = [NSFont fontWithName:@"Courier" size:9.0f];
			[gTextAttributes setObject:ft forKey:NSFontAttributeName];
		}
		
		if (!gInited)
		{
			gInited = 1;
			NSColor *c = [[NSColor selectedControlColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			gSelectedColor.r = [c redComponent];
			gSelectedColor.g = [c greenComponent];
			gSelectedColor.b = [c blueComponent];
			gSelectedColor.a = [c alphaComponent];
		}
		
		mCell = [self createCell];
		if (!mCell)
		{
			NSLog(@"Can't allocate cell!");
			[self release];
			return nil;
		}
	}
	return self;
}

- (void) dealloc
{
	if (mInputNames) [mInputNames release];
	if (mOutputNames) [mOutputNames release];
	if (mImage) [mImage release];
	if (mCell) [mCell release];
	
	int i;
	for (i = 0; i < mAudioBuffersCount; i++)
		free(mAudioBuffers[i].ptr);
	
	[super dealloc];
}

+ (NSString*) name
{
	return @"Undefined";
}

- (NSString*) name
{
	return [[self class] name];
}

+ (NSString*) nameForCategory:(SBElementCategory)category
{
	if (category < 0 || category >= kCategoryCount) return @"";
	return gCategoryNames[category];
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (SBElementCategory) category
{
	return [[self class] category];
}

- (int) numberOfInputs
{
	return [mInputNames count];
}

- (NSString*) nameOfInputAtIndex:(int)idx
{
	if (idx < 0) return nil;
	if (idx >= [mInputNames count]) return nil;
	return [mInputNames objectAtIndex:idx];
}

- (int) numberOfOutputs
{
	return [mOutputNames count];
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	if (idx < 0) return nil;
	if (idx >= [mOutputNames count]) return nil;
	return [mOutputNames objectAtIndex:idx];
}

- (NSString*) informations
{
	return @"No informations.";
}

- (NSView*) settingsView
{
	return nil;
}

- (void) willChangeAudio
{
	[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBElementWillChangeAudioNotification object:self];
}

- (void) didChangeAudio
{
	[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBElementDidChangeAudioNotification object:self];
}

- (void) didChangeView
{
	[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBElementDidChangeViewNotification object:self];
}

- (void) didChangeGlobalView
{
	mCalculatedFrame = NO;
	[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBElementDidChangeGlobalViewNotification object:self];
}

- (void) didChangeConnections
{
	[[NSNotificationCenter defaultCenter]
		postNotificationName:kSBElementDidChangeConnectionsNotification object:self];
}

- (SBCircuit*)subCircuit
{
	return nil;
}

// gui stuff

- (void) setGuiMode:(SBGuiMode)mode
{
	mGuiMode = mode;
}

- (void) setGuiOriginX:(int)x Y:(int)y
{
	if (x < 0) x = 0;
	if (y < 0) y = 0;
	mGuiOrigin.x = x;
	mGuiOrigin.y = y;
}

- (NSPoint) guiOrigin
{
	return mGuiOrigin;
}

- (NSPoint) contentOrigin
{
	if (mGuiMode != kCircuitDesign)
		return mGuiOrigin;

	NSPoint pt = mFrame.origin;

	if ([self numberOfInputs] > 0)
		pt.x += kSocketWidth + mInputNameWidth;
		
	NSSize contentSize = [mCell contentSize];
	
	pt.x += kContentSpace/2;
	pt.y += kContentSpace/2;
	
	float extraWidth = mContentFrame.size.width - contentSize.width - kContentSpace;
	float extraHeight = mContentFrame.size.height - contentSize.height - kContentSpace;
	
	pt.x += extraWidth/2;
	pt.y += extraHeight/2;
	
	return pt;
}

- (void) drawContent
{
	[mCell drawContentAtPoint:[self contentOrigin]];
}

- (NSRect) frame
{
	if (mCalculatedFrame) return mFrame;
	else if (mMiniMode)
	{
		int height = kMiniSize;
		int width = kMiniSize;
		
		int inputCount = [self numberOfInputs];
		int outputCount = [self numberOfOutputs];
		
		int inputHeight = inputCount * kMiniSize;
		int outputHeight = outputCount * kMiniSize;
		
		if (inputHeight > height) height = inputHeight;
		if (outputHeight > height) height = outputHeight;
		
		if (inputCount) width += kMiniSize;
		if (outputCount) width += kMiniSize;
		
		mFrame.size.width = width;
		mFrame.size.height = height;
		
		mFrame.origin.x = mDesignOrigin.x - mFrame.size.width / 2;
		mFrame.origin.y = mDesignOrigin.y - mFrame.size.height / 2;
		
		mCalculatedFrame = YES;
		return mFrame;
	}
	else
	{
		NSSize contentSize = [mCell contentSize];
	
		int inputCount = [self numberOfInputs];
		int outputCount = [self numberOfOutputs];
		
		int height = contentSize.height + kContentSpace + kTextHeight;
		int inputHeight = inputCount * kTextHeight;
		int outputHeight = outputCount * kTextHeight;
		
		if (inputHeight > height) height = inputHeight;
		if (outputHeight > height) height = outputHeight;
		
		mFrame.size.height = height;
		
		int i;
		
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
		
		mFrame.size.width = contentSize.width + kContentSpace;
		mElementNameWidth = [[self name] sizeWithAttributes:gTextAttributes].width + kNameSpace;
		
		if (mElementNameWidth < mFrame.size.width) mElementNameWidth = mFrame.size.width;
		else mFrame.size.width = mElementNameWidth;
		
		if (inputCount > 0) mFrame.size.width += kSocketWidth + inputNameWitdh;
		if (outputCount > 0) mFrame.size.width += kSocketWidth + outputNameWitdh;
		
		if (inputCount > 0) mInputNameWidth = inputNameWitdh;
		if (outputCount > 0) mOutputNameWidth = outputNameWitdh;
		
		mContentFrame.origin.x = 0;
		mContentFrame.origin.y = 0;
		mContentFrame.size = mFrame.size;
		
		if (inputCount > 0) mContentFrame.origin.x += kSocketWidth + inputNameWitdh;
		
		if (inputCount > 0) mContentFrame.size.width -= kSocketWidth + inputNameWitdh;
		if (outputCount > 0) mContentFrame.size.width -= kSocketWidth + outputNameWitdh;
		
		mContentFrame.size.height -= kTextHeight;

		mFrame.origin.x = mDesignOrigin.x - mFrame.size.width / 2;
		mFrame.origin.y = mDesignOrigin.y - mFrame.size.height / 2;
		
		mCalculatedFrame = YES;
		return mFrame;
	}
}

- (NSRect) rectForInput:(int)idx
{
	NSRect r = {{0.f, 0.f}, {0.f, 0.f}};
	
	if (idx < 0) return r;

	int inputs = [self numberOfInputs];
	if (idx >= inputs) return r;
	
	if (!mCalculatedFrame) (void)[self frame];
	
	float inputHeight = mFrame.size.height / inputs;
	
	r.origin = mFrame.origin;
	r.origin.y += inputHeight * idx;
	r.size.height = inputHeight;
	r.size.width = (mMiniMode) ? kMiniSize : kSocketWidth;
	
	return r;
}

- (NSRect) rectForOutput:(int)idx
{
	NSRect r = {{0.f, 0.f}, {0.f, 0.f}};
	
	if (idx < 0) return r;

	int outputs = [self numberOfOutputs];
	if (idx >= outputs) return r;
	
	if (!mCalculatedFrame) (void)[self frame];
	
	float outputHeight = mFrame.size.height / outputs;
	
	r.origin = mFrame.origin;
	r.origin.x += mFrame.size.width;
	r.origin.x -= (mMiniMode) ? kMiniSize : kSocketWidth;
	r.origin.y += outputHeight * idx;
	r.size.height = outputHeight;
	r.size.width = (mMiniMode) ? kMiniSize : kSocketWidth;
	
	return r;
}

- (int) inputForX:(int)x Y:(int)y
{
	int inputs = [self numberOfInputs];
	if (inputs <= 0) return -1;
	if (![self hitTestX:x Y:y]) return -1;
	
	if (!mCalculatedFrame) (void)[self frame];
	
	x -= mFrame.origin.x;
	y -= mFrame.origin.y;
	
	if (x > ((mMiniMode) ? kMiniSize : kSocketWidth)) return -1;
	
	float inputHeight = mFrame.size.height / [self numberOfInputs];
	
	int p = floor(y / inputHeight);
	
	if (p < 0 || p >= inputs) return -1; 
	return p;
}

- (int) outputForX:(int)x Y:(int)y
{
	int outputs = [self numberOfOutputs];
	if (outputs <= 0) return -1;
	if (![self hitTestX:x Y:y]) return -1;

	if (!mCalculatedFrame) (void)[self frame];
	
	x -= mFrame.origin.x;
	y -= mFrame.origin.y;
	
	if (x < (mFrame.size.width - ((mMiniMode) ? kMiniSize : kSocketWidth))) return -1;
	
	float outputHeight = mFrame.size.height / [self numberOfOutputs];
	
	int p = floor(y / outputHeight);
	
	if (p < 0 || p >= outputs) return -1; 
	return p;
}

- (void) setOriginX:(int)x Y:(int)y
{
	mDesignOrigin.x = x;
	mDesignOrigin.y = y;
	
	mCalculatedFrame = NO;
}

- (BOOL) hitTestX:(int)x Y:(int)y
{
	if (mGuiMode == kCircuitDesign) 
	{
		if (!mCalculatedFrame) (void)[self frame];
		return (   x >= mFrame.origin.x
				&& x <= (mFrame.origin.x + mFrame.size.width)
				&& y >= mFrame.origin.y
				&& y <= (mFrame.origin.y + mFrame.size.height)  );
	}
	else
		return [mCell contentHitTestX:x - mGuiOrigin.x Y:y - mGuiOrigin.y];
}

- (void) drawRect:(NSRect)rect
{
	if (mGuiMode != kCircuitDesign) 
	{
		[self drawContent];
		return;
	}

	if (!mCalculatedFrame) (void)[self frame];
	
	if (mIsSelected)
	{
		//[[NSColor selectedControlColor] set];
		//NSColor *c = [NSColor selectedControlColor];
		ogSetColor(gSelectedColor);
	}
	else
		//[[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
		ogSetColorComp(0.95f, 0.95f, 0.95f, 1.f);
	
	if (mMiniMode)
	{
		//[NSBezierPath fillRect:mFrame];
		ogFillRectangle(mFrame.origin.x, mFrame.origin.y, mFrame.size.width, mFrame.size.height);
		
		//[[NSColor blackColor] set];
		ogSetColorIndex(ogBlack);
		
		//[NSBezierPath strokeRect:mFrame];
		ogStrokeRectangle(mFrame.origin.x, mFrame.origin.y, mFrame.size.width, mFrame.size.height);
	}
	
	else
	{
		//NSBezierPath *roundedFrame = [NSBezierPath bezierPathWithRect:mFrame cornerRadius: (kSocketWidth / 2)];
		//[roundedFrame fill];
		ogFillRoundedRectangle(mFrame.origin.x, mFrame.origin.y, mFrame.size.width, mFrame.size.height, (kSocketWidth / 2));
		
		//[[NSColor blackColor] set];
		ogSetColorIndex(ogBlack);
		
		//[roundedFrame stroke];
		ogStrokeRoundedRectangle(mFrame.origin.x, mFrame.origin.y, mFrame.size.width, mFrame.size.height, (kSocketWidth / 2));
	}	
	
	int i;
	int inputCount = [self numberOfInputs];
	int outputCount = [self numberOfOutputs];
	
	if (mMiniMode)
	{
		if (inputCount > 0)
		{
			NSPoint top, bot;
		
			bot.x = top.x = mFrame.origin.x + kMiniSize;
			top.y = mFrame.origin.y;
			bot.y = top.y + mFrame.size.height;
			
			//[NSBezierPath strokeLineFromPoint:top toPoint:bot];
			ogStrokeLine(top.x, top.y, bot.x, bot.y);

			float inputHeight = mFrame.size.height / inputCount;
		
			NSPoint lef, rig;
			lef.y = rig.y = mFrame.origin.y;
			lef.x = mFrame.origin.x;
			rig.x = mFrame.origin.x + kMiniSize;
	
			for (i = 0; i < inputCount; i++)
			{
				SBConnectionType type = [self typeOfInputAtIndex:i];
				if (type != kNormal)
				{
					SET_TYPE_COLOR(type)
					
					// NSRect rect = {{lef.x + 1, lef.y + 1}, {kMiniSize - 2, inputHeight - 2}};
					NSRect oRect = NSMakeRect(lef.x + 1.f, lef.y + 1.f, kMiniSize - 2.f, inputHeight - 2.f);

					//[NSBezierPath fillRect:rect];
					ogFillRectangle(oRect.origin.x, oRect.origin.y, oRect.size.width, oRect.size.height);
					
					//[[NSColor blackColor] set];
					ogSetColorIndex(ogBlack);
				}
				  
				
				if (i != inputCount - 1)
				{
					lef.y += inputHeight;
					rig.y += inputHeight;
				
					//[NSBezierPath strokeLineFromPoint:lef toPoint:rig];
					ogStrokeLine(lef.x, lef.y, rig.x, rig.y);
				}
			}
		}
		
		if (outputCount > 0)
		{
			NSPoint top, bot;
		
			bot.x = top.x = mFrame.origin.x + mFrame.size.width - kMiniSize;
			top.y = mFrame.origin.y;
			bot.y = top.y + mFrame.size.height;
			
			//[NSBezierPath strokeLineFromPoint:top toPoint:bot];
			ogStrokeLine(top.x, top.y, bot.x, bot.y);

			float outputHeight = mFrame.size.height / outputCount;
		
			NSPoint lef, rig;
			lef.y = rig.y = mFrame.origin.y;
			rig.x = mFrame.origin.x + mFrame.size.width;
			lef.x = rig.x - kMiniSize;
	
			for (i = 0; i < outputCount; i++)
			{
				SBConnectionType type = [self typeOfOutputAtIndex:i];
				if (type != kNormal)
				{
					SET_TYPE_COLOR(type)
					
					// NSRect rect = {{lef.x + 1, lef.y + 1}, {kMiniSize - 2, outputHeight - 2}};
					NSRect oRect = NSMakeRect(lef.x + 1.f, lef.y + 1.f, kMiniSize - 2.f, outputHeight - 2.f);
					//[NSBezierPath fillRect:rect];
					ogFillRectangle(oRect.origin.x, oRect.origin.y, oRect.size.width, oRect.size.height);
				
					//[[NSColor blackColor] set];
					ogSetColorIndex(ogBlack);
				} 
				
				if (i != outputCount - 1)
				{
					lef.y += outputHeight;
					rig.y += outputHeight;
				
					//[NSBezierPath strokeLineFromPoint:lef toPoint:rig];
					ogStrokeLine(lef.x, lef.y, rig.x, rig.y);
				}
			}
		}
	
		return;
	}
	
	// normal mode
	// do input sockets
	if (inputCount > 0)
	{
		NSPoint top, bot;
		
		bot.x = top.x = mFrame.origin.x + kSocketWidth;
		top.y = mFrame.origin.y;
		bot.y = top.y + mFrame.size.height;
		
		//[[NSColor grayColor] set];
		ogSetColorIndex(ogGray);
		
		//[NSBezierPath strokeLineFromPoint:top toPoint:bot];
		ogStrokeLine(top.x, top.y, bot.x, bot.y);
		
		//[[NSColor blackColor] set];
		ogSetColorIndex(ogBlack);
		
		top.x += mInputNameWidth;
		bot.x = top.x;
		
		//[NSBezierPath strokeLineFromPoint:top toPoint:bot];
		ogStrokeLine(top.x, top.y, bot.x, bot.y);
	
		float inputHeight = mFrame.size.height / inputCount;
		
		NSPoint lef, rig;
		lef.y = rig.y = mFrame.origin.y;
		lef.x = mFrame.origin.x;
		rig.x = mFrame.origin.x + kSocketWidth + mInputNameWidth;
		
		NSRect txtRect;
		txtRect.origin.x = lef.x + kSocketWidth;
		txtRect.origin.y = rig.y;
		txtRect.size.width = mInputNameWidth;
		txtRect.size.height = inputHeight;
		
		for (i = 0; i < inputCount; i++)
		{
			SBConnectionType type = [self typeOfInputAtIndex:i];
			if (type != kNormal)
			{
				SET_TYPE_COLOR(type)
				
				// NSRect rect = {{lef.x + 1, lef.y + 1}, {kSocketWidth - 2, inputHeight - 2}};
				NSRect oRect = NSMakeRect(lef.x + 1.f, lef.y + 1.f, kSocketWidth - 2.f, inputHeight - 2.f);

				//[NSBezierPath fillRect:rect];
				ogFillRectangle(oRect.origin.x, oRect.origin.y, oRect.size.width, oRect.size.height);
				
				//[[NSColor blackColor] set];
				ogSetColorIndex(ogBlack);
			}
		
		
			NSString *name = [self nameOfInputAtIndex:i];
			//[name drawInRect:txtRect withAttributes:gTextAttributes];
			ogDrawStringInRect([name UTF8String], txtRect.origin.x, txtRect.origin.y, txtRect.size.width, txtRect.size.height);
			
			lef.y += inputHeight;
			rig.y += inputHeight;
			txtRect.origin.y += inputHeight;
			
			if (i < inputCount - 1)
				//[NSBezierPath strokeLineFromPoint:lef toPoint:rig];
				ogStrokeLine(lef.x, lef.y, rig.x, rig.y);
		}
	}
	
	// do output sockets
	if (outputCount > 0)
	{
		NSPoint top, bot;
		
		bot.x = top.x = mFrame.origin.x + mFrame.size.width - kSocketWidth;
		top.y = mFrame.origin.y;
		bot.y = top.y + mFrame.size.height;
		
		//[[NSColor grayColor] set];
		ogSetColorIndex(ogGray);
		
		//[NSBezierPath strokeLineFromPoint:top toPoint:bot];
		ogStrokeLine(top.x, top.y, bot.x, bot.y);
		
		//[[NSColor blackColor] set];
		ogSetColorIndex(ogBlack);
		
		top.x -= mOutputNameWidth;
		bot.x = top.x;
		
		//[NSBezierPath strokeLineFromPoint:top toPoint:bot];
		ogStrokeLine(top.x, top.y, bot.x, bot.y);
	
		float outputHeight = mFrame.size.height / outputCount;
		
		NSPoint lef, rig;
		lef.y = rig.y = mFrame.origin.y;
		rig.x = mFrame.origin.x + mFrame.size.width;
		lef.x = rig.x - kSocketWidth - mOutputNameWidth;
		
		NSRect txtRect;
		txtRect.origin.x = lef.x;
		txtRect.origin.y = lef.y;
		txtRect.size.width = mOutputNameWidth;
		txtRect.size.height = outputHeight;
		
		for (i = 0; i < outputCount; i++)
		{
			SBConnectionType type = [self typeOfOutputAtIndex:i];
			if (type != kNormal)
			{
				SET_TYPE_COLOR(type)
				
				// NSRect rect = {{rig.x - (kSocketWidth - 1), rig.y + 1}, {kSocketWidth - 2, outputHeight - 2}};
				NSRect oRect = NSMakeRect(rig.x - (kSocketWidth - 1.f), rig.y + 1.f, kSocketWidth - 2.f, outputHeight - 2.f);

				//[NSBezierPath fillRect:rect];
				ogFillRectangle(oRect.origin.x, oRect.origin.y, oRect.size.width, oRect.size.height);
				
				//[[NSColor blackColor] set];
				ogSetColorIndex(ogBlack);
			}
		
		
			NSString *name = [self nameOfOutputAtIndex:i];
			//[name drawInRect:txtRect withAttributes:gTextAttributes];
			ogDrawStringInRect([name UTF8String], txtRect.origin.x, txtRect.origin.y, txtRect.size.width, txtRect.size.height);
			
			lef.y += outputHeight;
			rig.y += outputHeight;
			txtRect.origin.y += outputHeight;
			
			if (i < outputCount - 1)
				//[NSBezierPath strokeLineFromPoint:lef toPoint:rig];
				ogStrokeLine(lef.x, lef.y, rig.x, rig.y);
		}
	}
	
	NSPoint lef, rig;
	rig.y = lef.y = mFrame.origin.y + mFrame.size.height - kTextHeight;
	lef.x = mFrame.origin.x;
	if (inputCount > 0) lef.x += kSocketWidth + mInputNameWidth;
	rig.x = mFrame.origin.x + mFrame.size.width;
	if (outputCount > 0) rig.x -= kSocketWidth + mOutputNameWidth;
	
	//[NSBezierPath strokeLineFromPoint:lef toPoint:rig];
	ogStrokeLine(lef.x, lef.y, rig.x, rig.y);
	
	NSRect txtRect;
	txtRect.size.width = mElementNameWidth;
	txtRect.size.height = kTextHeight;
	txtRect.origin = lef;

	//[[self name] drawInRect:txtRect withAttributes:gTextAttributes];
	ogDrawStringInRect([[self name] UTF8String], txtRect.origin.x, txtRect.origin.y, txtRect.size.width, txtRect.size.height);
	
	[self drawContent];
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	if (mMiniMode && mGuiMode == kCircuitDesign) return NO;
	NSPoint pt = [self contentOrigin];
	return [mCell mouseDownX:x - pt.x Y:y - pt.y clickCount:clickCount];
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	if (mMiniMode && mGuiMode == kCircuitDesign) return NO;
	NSPoint pt = [self contentOrigin];
	return [mCell mouseDraggedX:x - pt.x Y:y - pt.y lastX:lx - pt.x lastY:ly - pt.y];
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	if (mMiniMode && mGuiMode == kCircuitDesign) return NO;
	NSPoint pt = [self contentOrigin];
	return [mCell mouseUpX:x - pt.x Y:y - pt.y];
}

- (BOOL) keyDown:(unichar)ukey
{
	if (mMiniMode && mGuiMode == kCircuitDesign) return NO;
	return [mCell keyDown:ukey];
}

- (void) setSelected:(BOOL)s
{
	mIsSelected = s;
	if (mCell) [mCell setSelected:s];
}

- (void) reset
{
	int i;
	if (mPrecision == kFloatPrecision)
	{
		for (i = 0; i < mAudioBuffersCount; i++)
			memset(mAudioBuffers[i].ptr, 0, mSampleCount * sizeof(float));
	}
	else
	{
		for (i = 0; i < mAudioBuffersCount; i++)
			memset(mAudioBuffers[i].ptr, 0, mSampleCount * sizeof(double));
	}
}

- (void) changeInterpolation:(SBInterpolation)interpolation
{
	mInterpolation = interpolation;
}

- (void) prepareForSamplingRate:(int)samplingRate
			sampleCount:(int)sampleCount
			precision:(SBPrecision)precision
			interpolation:(SBInterpolation)interpolation
{
	int outputs = [self numberOfOutputs];

	if (sampleCount == 0 || samplingRate == 0) return;
	if (mSampleRate == samplingRate && mSampleCount == sampleCount && mAudioBuffersCount == outputs)
	{
		if (mPrecision != precision) [self changePrecision:precision];
		mInterpolation = interpolation;
		[self reset];
		return;
	}

	mInterpolation = interpolation;
	mSampleRate = samplingRate;
	mSampleCount = sampleCount;
	mPrecision = precision;
	
	int i;
	for (i = 0; i < mAudioBuffersCount; i++)
		free(mAudioBuffers[i].ptr);
	
	mAudioBuffersCount = outputs;
	for (i = 0; i < mAudioBuffersCount; i++)
	{
		mAudioBuffers[i].ptr = malloc(sampleCount * sizeof(double));
		assert(mAudioBuffers[i].ptr);
	}
	
	[self specificPrepare];
	[self reset];
}

- (void) changePrecision:(SBPrecision)precision
{
	int i, j;
	
	if (mPrecision == precision) return;
	if (mPrecision == kFloatPrecision)
	{
		// float to double
		for (i = 0; i < mAudioBuffersCount; i++)
			for (j = mSampleCount - 1; j >= 0; j--)
				mAudioBuffers[i].doubleData[j] = mAudioBuffers[i].floatData[j];

	}
	else
	{
		// double to float
		for (i = 0; i < mAudioBuffersCount; i++)
			for (j = 0; j < mSampleCount; j++)
				mAudioBuffers[i].floatData[j] = mAudioBuffers[i].doubleData[j];
	}
	mPrecision = precision;
}

- (SBBuffer) outputAtIndex:(int)idx
{
	return mAudioBuffers[idx];
}

- (NSMutableDictionary*) saveData
{
	return nil;
}

- (BOOL) loadData:(NSDictionary*)data
{
	return YES;
}

- (void) specificPrepare
{
	// meant to be overloaded
}

- (SBCell*) createCell
{
	// meant to be overloaded
	SBDefaultCell *cell = [[SBDefaultCell alloc] init];
	if (cell) [cell setElement:self];
	return cell;
}

- (void) setColorsBack:(NSColor*)back contour:(NSColor*)contour front:(NSColor*)front
{
//	[mCell setColorsBack:back contour:contour front:front];

	ogColor b, c, f;
	
	b.r = b.g = b.b = b.a = 1;
	c.r = c.g = c.b = c.a = 1;
	f.r = f.g = f.b = f.a = 1;
	
	if (back)
	{
		NSColor *col = [back colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		b.r = [col redComponent];
		b.g = [col greenComponent];
		b.b = [col blueComponent];
		b.a = [col alphaComponent];
	}
	
	if (contour)
	{
		NSColor *col = [contour colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		c.r = [col redComponent];
		c.g = [col greenComponent];
		c.b = [col blueComponent];
		c.a = [col alphaComponent];
	}
	
	if (front)
	{
		NSColor *col = [front colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		f.r = [col redComponent];
		f.g = [col greenComponent];
		f.b = [col blueComponent];
		f.a = [col alphaComponent];
	}

	[mCell setColorsBack:b contour:c front:f];
}

- (SBGuiMode) guiMode
{
	return mGuiMode;
}

- (void) setMiniMode:(BOOL)mini
{
	mMiniMode = mini;
	mCalculatedFrame = NO;
}

- (BOOL) miniMode
{
	return mMiniMode;
}

- (NSPoint) designOrigin
{
	return mDesignOrigin;
}

- (void) setLastCircuit:(BOOL)isLastCircuit
{
	mLastCircuit = isLastCircuit;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	return kNormal;
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	return kNormal;
}

- (void) awakeFromNib
{

}

- (BOOL) alwaysExecute
{
	return NO;
}

- (BOOL) constantRefresh
{
	return NO;
}

- (void) trimDebug
{
	
}

@end
