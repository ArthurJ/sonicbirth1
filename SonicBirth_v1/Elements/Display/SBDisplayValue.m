/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBDisplayValue.h"
#import "SBValueCell.h"

// we could export a read only parameter here...

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBDisplayValue *obj = inObj;
	
	if (!count) return;
	double cur = 0;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		cur = *i;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		cur = *i;
	}
	
	SBValueCell *cell = (SBValueCell*)obj->mCell;
	if (cell) [cell setValue:cur];
}

@implementation SBDisplayValue

+ (NSString*) name
{
	return @"Display value";
}

- (NSString*) name
{
	return mName;
}

- (void) setName:(NSString*)name
{
	[mName setString:name];
	if (mNameTF) [mNameTF setStringValue:name];
	[self didChangeGlobalView];
	[self didChangeParameterInfo];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if (tf == mNameTF)
	{
		[self setName:[mNameTF stringValue]];
	}
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:mName forKey:@"argName"];

	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSString *s = [data objectForKey:@"argName"];
	if (s) [mName setString:s];

	return YES;
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	if (mNameTF) [mNameTF setStringValue:mName];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBDisplayValue" owner:self];
		return mSettingsView;
	}
}

- (NSString*) informations
{
	return	@"Shows the first value of the input of each audio cycle. Can be used in the plugin interface.";
}

+ (SBElementCategory) category
{
	return kDisplay;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;

		[mInputNames addObject:@"in"];
		
		mName = [[NSMutableString alloc] initWithString:@"dis val"];
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
	if (mName) [mName release];
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}


- (SBCell*) createCell
{
	return [[SBValueCell alloc] init];
}

- (BOOL) alwaysExecute
{
	return YES;
}

- (BOOL) constantRefresh
{
	return YES;
}

@end
