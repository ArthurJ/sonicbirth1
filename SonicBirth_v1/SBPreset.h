/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

@interface SBPreset : NSObject
{
	NSMutableArray	*mValues; // array of NSNumber (double)
	NSMutableString *mName;
}

- (NSString*) name;
- (void) setName:(NSString*)name;

//- (double) valueForIndex:(int)index;
//- (void) deleteValueAtIndex:(int)index;
//- (void) appendValue:(double)value;

//- (NSArray*) values;
//- (void) takeValues:(NSArray*)array;

- (id) objectAtIndex:(int)idx;
- (void) deleteValueAtIndex:(int)idx;
- (void) appendObject:(id)object;

- (NSData*) saveData;
- (BOOL) loadData:(NSData*)data;

@end
