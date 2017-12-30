/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSelectionList.h"
#import "SBWire.h"

@implementation SBSelectionList

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mList = [[NSMutableArray alloc] init];
		if (!mList)
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (void) dealloc
{
	if (mList) [mList release];
	[super dealloc];
}

- (void) addElement:(SBElement*)e
{
	if (!e) return;
	[e setSelected:YES];
	
	NSUInteger idx = [mList indexOfObjectIdenticalTo:e];
	if (idx == NSNotFound)
		[mList addObject:e];
	else
		[mList	exchangeObjectAtIndex:	idx
				withObjectAtIndex:		[mList count] - 1 ];
}

- (void) toggleElement:(SBElement*)e
{
	if (!e) return;

	unsigned index = [mList indexOfObjectIdenticalTo:e];
	if (index == NSNotFound) [self addElement:e];
	else [self removeElement:e];
}

- (void) setElement:(SBElement*)e
{
	if (!e) return;
	[self removeAllElements];
	[self addElement:e];
}

- (void) removeElement:(SBElement*)e
{
	if (!e) return;
	[e setSelected:NO];
	[mList removeObject:e];
}

- (void) removeAllElements
{
	int i, c = [mList count];
	if (c > 0)
	{
		for (i = 0; i < c; i++)
		{
			SBElement *e = [mList objectAtIndex:i];
			[e setSelected:NO];
		}
		[mList removeAllObjects];
	}
}


- (SBElement*) element
{
	if ([mList count] > 0) return [mList lastObject];
	else return nil;
}

- (NSArray*) elements
{
	if ([mList count] > 0) return mList;
	else return nil;
}

- (int) count
{
	return [mList count];
}

- (void) translateElementsDeltaX:(int)x deltaY:(int)y content:(BOOL)content
{
	int i, c = [mList count];
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mList objectAtIndex:i];
		if (content)
		{
			NSPoint origin = [e contentOrigin];
			origin.x += x;
			origin.y += y;
			[e setGuiOriginX:origin.x Y:origin.y];
		}
		else
		{
			NSPoint origin = [e designOrigin];
			origin.x += x;
			origin.y += y;
			[e setOriginX:origin.x Y:origin.y];
		}
	}
	
	if (!content)
	{
		NSArray *wa = [self selectedWires];
		if (wa)
		{
			c = [wa count];
			for (i = 0; i < c; i++)
			{
				SBWire *w = [wa objectAtIndex:i];
				[w translateDeltaX:x deltaY:y];
			}
		}
	}
}

- (BOOL) hitTestX:(int)x Y:(int)y
{
	int i, c = [mList count];
	for (i = 0; i < c; i++)
	{
		SBElement *e = [mList objectAtIndex:i];
		if ([e hitTestX:x Y:y]) return YES;
	}
	return NO;
}

- (BOOL) isSelected:(SBElement*)e
{
	return ([mList indexOfObjectIdenticalTo:e] != NSNotFound);
}

- (void) setWireArray:(NSArray*)wa
{
	mWireArray = wa;
}

- (NSArray*) selectedWires
{
	if (!mWireArray) return nil;
	
	int i, c = [mWireArray count];
	if (c <= 0) return nil;
	
	NSMutableArray *wa = [[[NSMutableArray alloc] init] autorelease];

	for (i = 0; i < c; i++)
	{
		SBWire *w = [mWireArray objectAtIndex:i];
		if ([self isSelected:[w inputElement]] && [self isSelected:[w outputElement]])
			[wa addObject:w];
	}

	if ([wa count] > 0) return wa;
	return nil;
}

@end
