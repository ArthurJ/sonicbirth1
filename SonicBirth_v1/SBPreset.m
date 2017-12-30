/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBPreset.h"


@implementation SBPreset

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
		
		mName = [[NSMutableString alloc] initWithString:@"Unnamed"];
		if (!mName)
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (void) dealloc
{
	if (mValues) [mValues release];
	if (mName) [mName release];
	[super dealloc];
}

- (NSString*) name
{
	return mName;
}

- (void) setName:(NSString*)name
{
	[mName setString:name];
}

/*
- (double) valueForIndex:(int)index
{
	int c = [mValues count];
	if (index < 0 || index >= c) return 0;

	NSNumber *n = [mValues objectAtIndex:index];
	return [n doubleValue];
}

- (void) deleteValueAtIndex:(int)index
{
	int c = [mValues count];
	if (index < 0 || index >= c) return;
	
	[mValues removeObjectAtIndex:index];
}

- (void) appendValue:(double)value
{
	NSNumber *n = [NSNumber numberWithDouble:value];
	[mValues addObject:n];
}

- (NSArray*) values
{
	return mValues;
}

- (void) takeValues:(NSArray*)array
{
	if (!array) return;
	
	[mValues removeAllObjects];
	[mValues addObjectsFromArray:array];
}*/

- (id) objectAtIndex:(int)idx
{
	int c = [mValues count];
	if (idx < 0 || idx >= c) return nil;

	return [mValues objectAtIndex:idx];
}

- (void) deleteValueAtIndex:(int)idx
{
	int c = [mValues count];
	if (idx < 0 || idx >= c) return;
	
	[mValues removeObjectAtIndex:idx];
}

- (void) appendObject:(id)object
{
	if (object) [mValues addObject:object];
}

- (NSData*) saveData
{
	NSString *error;
	return [NSPropertyListSerialization dataFromPropertyList:mValues
										format:NSPropertyListXMLFormat_v1_0
										errorDescription:&error];
}

- (BOOL) loadData:(NSData*)data
{
	if (!data) return NO;
	
	NSString *error;
	NSArray *a = [NSPropertyListSerialization	propertyListFromData:data
												mutabilityOption:NSPropertyListImmutable
												format:nil
												errorDescription:&error];
	if (a)
	{
		[mValues removeAllObjects];
		[mValues addObjectsFromArray:a];
		return YES;
	}
	else
		return NO;
}

@end
