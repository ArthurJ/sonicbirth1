/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBIndexed.h"
#import "SBIndexedCell.h"

@implementation SBIndexed

+ (NSString*) name
{
	return @"Indexed";
}

- (NSString*) informations
{
	return @"Indexed popup button with multiple values.";
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBIndexed" owner:self];
		return mSettingsView;
	}
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mValues = [[NSMutableArray alloc] init];
		if (!mValues)
		{
			[self release];
			return nil;
		}
		
		mNames = [[NSMutableArray alloc] init];
		if (!mNames)
		{
			[self release];
			return nil;
		}
		
		[self createItem:nil];
		[self createItem:nil];
		
		mCurIndex = 0;
		
		[mName setString:@"indexed"];
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	if (mValues) [mValues release];
	if (mNames) [mNames release];
	[super dealloc];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:mNames forKey:@"names"];
	[md setObject:mValues forKey:@"values"];
	[md setObject:[NSNumber numberWithInt:mCurIndex] forKey:@"curIndex"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	[mNames removeAllObjects];
	[mValues removeAllObjects];

	int c1, c2, i;
	NSArray *a1, *a2;
	NSString *s;
	NSNumber *n;
	
	a1 = [data objectForKey:@"names"];
	a2 = [data objectForKey:@"values"];
	if (a1 && a2)
	{
		c1 = [a1 count];
		c2 = [a2 count];
		if (c1 == c2)
		{
			for (i = 0; i < c1; i++)
			{
				s = [a1 objectAtIndex:i];
				n = [a2 objectAtIndex:i];
				
				[mNames addObject:[NSMutableString stringWithString:s]];
				[mValues addObject:[NSNumber numberWithDouble:[n doubleValue]]];
			}
		}
	}
	
	n = [data objectForKey:@"curIndex"];
	if (n) mCurIndex = [n intValue];
	else mCurIndex = 0;
	
	while([mValues count] < 2) [self createItem:nil];
	if (mCurIndex < 0 || mCurIndex >= [mValues count]) mCurIndex = 0;
	
	[self takeValue:mCurIndex offsetToChange:0];
	
	return YES;
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mTableView selectRow:mCurIndex byExtendingSelection:NO];
	[self updateButtons];
}

- (NSArray*) indexedNames
{
	return mNames;
}

- (double) minValue
{
	return 0;
}

- (double) maxValue
{
	return [mValues count] - 1;
}

- (SBParameterType) type
{
	return kParameterUnit_Indexed;
}

- (double) currentValue
{
	return mCurIndex;
}

- (void) takeValue:(double)preset offsetToChange:(int)offset
{
	int idx = (int)(preset + 0.4);
	if (idx < 0 || idx >= [mValues count]) return;
	mCurIndex = idx;
	NSNumber *n = [mValues objectAtIndex:mCurIndex];
	[self setValue:[n doubleValue] forOutput:0 offsetToChange:offset];
	
	if (mTableView) [mTableView selectRow:mCurIndex byExtendingSelection:NO];
	[self didChangeView];
}

- (void) moveUp:(id)sender
{
	int srow = [mTableView selectedRow];
	int c = [mValues count];
	if (srow <= 0) return;
	if (srow >= c) return;
	
	int a = srow - 1;
	int b = srow;
	
	[mNames exchangeObjectAtIndex:a withObjectAtIndex:b];
	[mValues exchangeObjectAtIndex:a withObjectAtIndex:b];

	[mTableView selectRow:srow-1 byExtendingSelection:NO];
	[mTableView reloadData];
	[self didChangeParameterInfo];
}

- (void) moveDown:(id)sender
{
	int srow = [mTableView selectedRow];
	int c = [mValues count];
	if (srow < 0) return;
	if (srow >= c - 1) return;
	
	int a = srow;
	int b = srow + 1;
	
	[mNames exchangeObjectAtIndex:a withObjectAtIndex:b];
	[mValues exchangeObjectAtIndex:a withObjectAtIndex:b];
	
	[mTableView selectRow:srow+1 byExtendingSelection:NO];
	[mTableView reloadData];
	[self didChangeParameterInfo];
}

- (void) createItem:(id)sender
{
	NSMutableString *ms = [NSMutableString stringWithString:@"Unnamed"];
	NSNumber *n = [NSNumber numberWithDouble:0];

	if (ms && n)
	{
		[mValues addObject:n];
		[mNames addObject:ms];
		
		if (mSettingsView)
		{
			[self updateButtons];
			[mTableView reloadData];
		}
	}
	[self didChangeParameterInfo];
}

- (void) deleteItem:(id)sender
{
	int srow = [mTableView selectedRow];
	if (srow == -1) return;
	
	[mValues removeObjectAtIndex:srow];
	[mNames removeObjectAtIndex:srow];
	
	[self updateButtons];
	[mTableView reloadData];
	[self didChangeParameterInfo];
}


- (void) updateButtons
{
	int c = [mValues count];
	int srow = [mTableView selectedRow];
	
	[mDelete setEnabled:(c > 2)];
	[mMoveUp setEnabled:(c > 1 && srow > 0)];
	[mMoveDown setEnabled:(c > 1 && srow != -1 && srow < c - 1)];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [mValues count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *ident = [aTableColumn identifier];
	if ([ident isEqual:@"index"])
			return [NSNumber numberWithInt:rowIndex];
	else if ([ident isEqual:@"name"])
		return [mNames objectAtIndex:rowIndex];
	else if ([ident isEqual:@"value"])
		return [mValues objectAtIndex:rowIndex];
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *ident = [aTableColumn identifier];
	if ([ident isEqual:@"name"] && [anObject isKindOfClass:[NSString class]])
	{
		[[mNames objectAtIndex:rowIndex] setString:anObject];
		[self didChangeParameterInfo];
	}
	else if ([ident isEqual:@"value"])
	{
		[mValues removeObjectAtIndex:rowIndex];
		NSNumber *n = [NSNumber numberWithDouble:[anObject doubleValue]];
		[mValues insertObject:n atIndex:rowIndex];
		if (rowIndex == mCurIndex)
		{
			// [self setValue:[n doubleValue] forOutput:0 offsetToChange:0]; // keep only one setValue call...
			[self takeValue:mCurIndex offsetToChange:0];
			[self didChangeView];
		}
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int srow = [mTableView selectedRow];
	if (srow != -1)
	{
		[self takeValue:srow offsetToChange:0];
		[self didChangeView];
	}
	[self updateButtons];
}

- (SBCell*) createCell
{
	SBIndexedCell *cell = [[SBIndexedCell alloc] init];
	if (cell) [cell setArgument:self parameter:0];
	return cell;
}

@end
