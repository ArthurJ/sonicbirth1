/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBBoolean.h"
#import "SBBooleanCell.h"

@implementation SBBoolean

+ (NSString*) name
{
	return @"Boolean";
}

- (NSString*) informations
{
	return @"Boolean button with value for true and for false.";
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBBoolean" owner:self];
		return mSettingsView;
	}
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mTrueValue = 1.;
		mFalseValue = 0.;
		mState = 0.;
		[mName setString:@"boolean"];
		
		mOnImage = mMidImage = mOffImage = nil;
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	if (mOffImage) [mOffImage release];
	if (mMidImage) [mMidImage release];
	if (mOnImage) [mOnImage release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mTrueValueEditTF setDoubleValue:mTrueValue];
	[mTrueValueTF setDoubleValue:mTrueValue];
	[mFalseValueEditTF setDoubleValue:mFalseValue];
	[mFalseValueTF setDoubleValue:mFalseValue];
	[mButton setState:(mState) ? NSOnState : NSOffState];
	[mButton setTitle:mName];
	
	if (mOffImage) [mOffImageView setImage:mOffImage];
	if (mMidImage) [mMidImageView setImage:mMidImage];
	if (mOnImage) [mOnImageView setImage:mOnImage];
}

- (IBAction) pushedButton:(id)sender
{
	mState = ([mButton state] == NSOnState);
	[self setValue:((mState) ? mTrueValue : mFalseValue) forOutput:0 offsetToChange:0];
	[self didChangeView];
}

- (void) setName:(NSString*)name
{
	[super setName:name];
	[mButton setTitle:mName];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[super controlTextDidEndEditing:aNotification];

	id tf = [aNotification object];
	if (tf == mTrueValueEditTF)
	{
		mTrueValue = [mTrueValueEditTF doubleValue];
		[mTrueValueTF setDoubleValue:mTrueValue];
		if (mState) [self setValue:mTrueValue forOutput:0 offsetToChange:0];
	}
	else if (tf == mFalseValueEditTF)
	{
		mFalseValue = [mFalseValueEditTF doubleValue];
		[mFalseValueTF setDoubleValue:mFalseValue];
		if (!mState) [self setValue:mFalseValue forOutput:0 offsetToChange:0];
	}
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mTrueValue] forKey:@"truevalue"];
	[md setObject:[NSNumber numberWithDouble:mFalseValue] forKey:@"falsevalue"];
	[md setObject:[NSNumber numberWithDouble:(mState) ? 2 : 1] forKey:@"state"];
	
	if (mOffImage) [md setObject:[mOffImage TIFFRepresentation] forKey:@"offImage"];
	if (mMidImage) [md setObject:[mMidImage TIFFRepresentation] forKey:@"midImage"];
	if (mOnImage) [md setObject:[mOnImage TIFFRepresentation] forKey:@"onImage"];

	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n;
	
	n = [data objectForKey:@"truevalue"];
	if (n) mTrueValue = [n doubleValue];
	
	n = [data objectForKey:@"falsevalue"];
	if (n) mFalseValue = [n doubleValue];
	
	n = [data objectForKey:@"state"];
	if (n) mState = ([n intValue] == 2);
	
	[self setValue:((mState) ? mTrueValue : mFalseValue) forOutput:0 offsetToChange:0];
	
		
	NSData *dt;
	
	dt = [data objectForKey:@"offImage"];
	if (dt) mOffImage = [[NSImage alloc] initWithData:dt];
	
	dt = [data objectForKey:@"midImage"];
	if (dt) mMidImage = [[NSImage alloc] initWithData:dt];
	
	dt = [data objectForKey:@"onImage"];
	if (dt) mOnImage = [[NSImage alloc] initWithData:dt];
	
	SBBooleanCell *cell = (SBBooleanCell*)mCell;
	if (cell) [cell setOffImage:mOffImage midImage:mMidImage onImage:mOnImage];

	
	return YES;
}

- (double) minValue
{
	return 0;
}

- (double) maxValue
{
	return 1;
}

- (SBParameterType) type
{
	return kParameterUnit_Boolean;
}

- (double) currentValue
{
	return (mState) ? 1 : 0;
}

- (void) takeValue:(double)preset offsetToChange:(int)offset
{
	mState = preset;
	if (mButton) [mButton setState:(mState) ? NSOnState : NSOffState];
	[self setValue:((mState) ? mTrueValue : mFalseValue) forOutput:0 offsetToChange:offset];
	[self didChangeView];
}

- (SBCell*) createCell
{
	SBBooleanCell *cell = [[SBBooleanCell alloc] init];
	if (cell) [cell setArgument:self parameter:0];
	return cell;
}


- (IBAction) changedImages:(id)sender
{
	NSImage *noff = [[mOffImageView image] retain];
	NSImage *nmid = [[mMidImageView image] retain];
	NSImage *non  = [[mOnImageView image] retain];
	
	if (mOffImage) [mOffImage release];
	if (mMidImage) [mMidImage release];
	if (mOnImage) [mOnImage release];
	
	mOffImage = noff;
	mMidImage = nmid;
	mOnImage  = non;
	
	SBBooleanCell *cell = (SBBooleanCell*)mCell;
	if (cell)
	{
		[cell setOffImage:mOffImage midImage:mMidImage onImage:mOnImage];
		
		[self didChangeGlobalView];
	}
}

@end
