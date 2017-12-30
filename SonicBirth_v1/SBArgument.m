/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBArgument.h"

NSString *kSBArgumentDidChangeParameterValueNotification = @"kSBArgumentDidChangeParameterValueNotification";
NSString *kSBArgumentBeginGestureNotification = @"kSBArgumentBeginGestureNotification";
NSString *kSBArgumentEndGestureNotification = @"kSBArgumentEndGestureNotification";
NSString *kSBArgumentDidChangeParameterInfo = @"kSBArgumentDidChangeParameterInfo";


@implementation SBArgument

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mCircuitColors[0] = mCircuitColors[1] = mCircuitColors[2] = nil;
		mCustomColors[0] = mCustomColors[1] = mCustomColors[2] = nil;
		mUseCustomColor = NO;
	}
	return self;
}

- (void) dealloc
{
	if (mCustomColors[0]) [mCustomColors[0] release];
	if (mCustomColors[1]) [mCustomColors[1] release];
	if (mCustomColors[2]) [mCustomColors[2] release];
	
	if (mColorsView) [mColorsView release];
	
	[super dealloc];
}

- (NSView*) settingsView
{
	if (mColorsView) return mColorsView;
	else
	{
		[NSBundle loadNibNamed:@"SBArgumentColors" owner:self];
		return mColorsView;
	}
}

- (void) changeCustomColor:(id)sender
{
	mUseCustomColor = ([mUseCustomColorBt state] == NSOnState);
	
	if (sender == mUseCustomColorBt)
	{
		[mColorWellBack setEnabled:mUseCustomColor];
		[mColorWellContour setEnabled:mUseCustomColor];
		[mColorWellFront setEnabled:mUseCustomColor];
	}
	
	if (mUseCustomColor)
	{
		if (mCustomColors[0]) [mCustomColors[0] release];
		if (mCustomColors[1]) [mCustomColors[1] release];
		if (mCustomColors[2]) [mCustomColors[2] release];
			
		mCustomColors[0] = [[mColorWellBack color] retain];
		mCustomColors[1] = [[mColorWellContour color] retain];
		mCustomColors[2] = [[mColorWellFront color] retain];
		
		[super setColorsBack:mCustomColors[0] contour:mCustomColors[1] front:mCustomColors[2]];
	}
	else
		[super setColorsBack:mCircuitColors[0] contour:mCircuitColors[1] front:mCircuitColors[2]];
		
	[self didChangeGlobalView];
}

- (void) setColorsBack:(NSColor*)back contour:(NSColor*)contour front:(NSColor*)front
{
	mCircuitColors[0] = back;
	mCircuitColors[1] = contour;
	mCircuitColors[2] = front;
	
	if (!mUseCustomColor)
		[super setColorsBack:back contour:contour front:front];	
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
	
	[mUseCustomColorBt setState:(mUseCustomColor ? NSOnState : NSOffState)];
	
	if (mCustomColors[0]) [mColorWellBack setColor:mCustomColors[0]];
	if (mCustomColors[1]) [mColorWellContour setColor:mCustomColors[1]];
	if (mCustomColors[2]) [mColorWellFront setColor:mCustomColors[2]];
	
	[mColorWellBack setEnabled:mUseCustomColor];
	[mColorWellContour setEnabled:mUseCustomColor];
	[mColorWellFront setEnabled:mUseCustomColor];
}

- (void) setName:(NSString*)name
{
	
}

- (int) numberOfParameters
{
	return 0;
}

- (double) minValueForParameter:(int)i
{
	return 0;
}

- (double) maxValueForParameter:(int)i
{
	return 0;
}

- (BOOL) logarithmicForParameter:(int)i
{
	return NO;
}

- (BOOL) realtimeForParameter:(int)i
{
	return NO;
}

- (SBParameterType) typeForParameter:(int)i
{
	return kParameterUnit_Generic;
}

- (double) currentValueForParameter:(int)i
{
	return 0;
}

// for indexed types:
- (NSArray*) indexedNamesForParameter:(int)i
{
	return nil;
}

- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i
{
}

- (NSString*) nameForParameter:(int)i
{
	return nil;
}

- (void) didChangeParameterInfo
{
	[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBArgumentDidChangeParameterInfo
			object:self
			userInfo:nil];
}

- (void) didChangeParameterValueAtIndex:(int)idx
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
											self, @"argument",
											[NSNumber numberWithInt:idx], @"index",
											nil];

	[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBArgumentDidChangeParameterValueNotification
			object:self
			userInfo:dict];
	// NSLog(@"SonicBirth: Sent AUParameterListenerNotify for param: %i.", index);
}

- (void) beginGestureForParameterAtIndex:(int)idx
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
											self, @"argument",
											[NSNumber numberWithInt:idx], @"index",
											nil];

	[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBArgumentBeginGestureNotification
			object:self
			userInfo:dict];
}

- (void) endGestureForParameterAtIndex:(int)idx
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
											self, @"argument",
											[NSNumber numberWithInt:idx], @"index",
											nil];

	[[NSNotificationCenter defaultCenter]
			postNotificationName:kSBArgumentEndGestureNotification
			object:self
			userInfo:dict];
}

- (id) savePreset
{
	NSMutableArray *a = [[[NSMutableArray alloc] init] autorelease];
	if (a)
	{
		int c = [self numberOfParameters], i;
		for (i = 0; i < c; i++)
			[a addObject:[NSNumber numberWithDouble:[self currentValueForParameter:i]]];
	}
	return a;
}

- (void) loadPreset:(id)preset
{
	NSArray *a = preset;
	if (a)
	{
		int c = [self numberOfParameters], i;
		for (i = 0; i < c; i++)
		{
			NSNumber *n = [a objectAtIndex:i];
			[self takeValue:[n doubleValue] offsetToChange:0 forParameter:i];
		}
	}
}

- (BOOL) selfManagesSharingArgumentFrom:(SBArgument*)argument shareCount:(int)shareCount
{
	return NO;
}

- (BOOL) executeEvenIfShared
{
	return NO;
}

- (BOOL) readFlagForParameter:(int)i
{
	return YES;
}

- (BOOL) writeFlagForParameter:(int)i
{
	return YES;
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!mUseCustomColor) return md;
	
	if (mCustomColors[0]) [md setObject:[NSArchiver archivedDataWithRootObject:mCustomColors[0]] forKey:@"customBackColor"];
	if (mCustomColors[1]) [md setObject:[NSArchiver archivedDataWithRootObject:mCustomColors[1]] forKey:@"customContourColor"];
	if (mCustomColors[2]) [md setObject:[NSArchiver archivedDataWithRootObject:mCustomColors[2]] forKey:@"customFrontColor"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	if (!data) return YES;
	
	NSData *dt;
	
	if (mCustomColors[0]) [mCustomColors[0] release];
	if (mCustomColors[1]) [mCustomColors[1] release];
	if (mCustomColors[2]) [mCustomColors[2] release];
	
	mCustomColors[0] = mCustomColors[1] = mCustomColors[2] = nil;
	
	dt = [data objectForKey:@"customBackColor"];
	if (dt) mCustomColors[0] = [(NSColor *)[NSUnarchiver unarchiveObjectWithData:dt] retain];
	
	dt = [data objectForKey:@"customContourColor"];
	if (dt) mCustomColors[1] = [(NSColor *)[NSUnarchiver unarchiveObjectWithData:dt] retain];
	
	dt = [data objectForKey:@"customFrontColor"];
	if (dt) mCustomColors[2] = [(NSColor *)[NSUnarchiver unarchiveObjectWithData:dt] retain];

	if (mCustomColors[0] && mCustomColors[1] && mCustomColors[2])
		mUseCustomColor = YES;

	if (mUseCustomColor)
		[super setColorsBack:mCustomColors[0] contour:mCustomColors[1] front:mCustomColors[2]];

	return YES;
}

@end
