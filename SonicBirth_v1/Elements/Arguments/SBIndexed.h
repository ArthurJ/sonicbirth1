/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSimpleArgument.h"

@interface SBIndexed : SBSimpleArgument
{
	IBOutlet NSTableView	*mTableView;
	IBOutlet NSButton		*mCreate;
	IBOutlet NSButton		*mDelete;
	IBOutlet NSButton		*mMoveUp;
	IBOutlet NSButton		*mMoveDown;
	IBOutlet NSView			*mSettingsView;
	
	NSMutableArray			*mValues;
	NSMutableArray			*mNames;
	int						mCurIndex;
}

- (void) moveUp:(id)sender;
- (void) moveDown:(id)sender;
- (void) createItem:(id)sender;
- (void) deleteItem:(id)sender;

- (void) updateButtons;

@end
