/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBVisibleComment.h"
#import "SBEditCell.h"

//--------------------------------------------------------------
@interface SBStaticTextCell : SBCell
{
	NSString *mText;
	NSSize mSize;
}
- (void) setText:(NSString*)text;
@end

//--------------------------------------------------------------
@implementation SBStaticTextCell
- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mText = nil;
		mSize.width = 100;
		mSize.height = 16;
	}
	return self;
}

- (void) dealloc
{
	if (mText) [mText release];
	[super dealloc];
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	ogSetColor(mColorBack);
	ogFillRectangle(origin.x, origin.y, mSize.width, mSize.height);
	
	ogSetColor(mColorContour);
	ogStrokeRectangle(origin.x, origin.y, mSize.width, mSize.height);

	ogSetColor(mColorFront);
	ogDrawStringAtPoint([mText cString], origin.x + 6, origin.y + 1);
}

- (NSSize) contentSize
{
	return mSize;
}

- (void) setText:(NSString*)text
{
	[text retain];
	if (mText) [mText release];
	mText = text;
	
	mSize.width = ogStringWidth([mText cString]) + 12;
}
@end

//--------------------------------------------------------------
@implementation SBVisibleComment
+ (NSString*) name
{
	return @"Visible comment";
}

+ (SBElementCategory) category
{
	return kDisplay;
}

- (NSString*) informations
{
	return	@"Comment visible in GUI.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[mName setString:@"comment"];
		mNumberOfOutputs = 0;
		
		mText = [[NSMutableString alloc] initWithString:@"comment"];
		if (!mText)
		{
			[self release];
			return nil;
		}
		
		SBStaticTextCell *cell = (SBStaticTextCell*)mCell;
		if (cell)
		{
			[cell setText:mText];
		}
	}
	return self;
}

- (void) dealloc
{
	if (mText) [mText release];
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[mTextTF setStringValue:mText];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBVisibleComment" owner:self];
		return mSettingsView;
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if (tf != mTextTF)
	{
		[super controlTextDidEndEditing:aNotification];
		return;
	}
	
	[mText setString:[mTextTF stringValue]];
	
	SBStaticTextCell *cell = (SBStaticTextCell*)mCell;
	if (cell)
	{
		[cell setText:mText];
		[self didChangeGlobalView];
	}
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;

	[md setObject:mText forKey:@"text"];

	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSString *s = [data objectForKey:@"text"];
	if (s) [mText setString:s];
	
	SBStaticTextCell *cell = (SBStaticTextCell*)mCell;
	if (cell)
	{
		[cell setText:mText];
	}

	return YES;
}

- (int) numberOfParameters
{
	return 0;
}

- (SBCell*) createCell
{
	SBStaticTextCell *cell = [[SBStaticTextCell alloc] init];
	if (cell) [cell setText:mText];
	return cell;
}

- (void) setName:(NSString*)name
{
	[mName setString:name];
	if (mNameTF) [mNameTF setStringValue:name];
	[self didChangeGlobalView];
	[self didChangeParameterInfo];
}

@end

