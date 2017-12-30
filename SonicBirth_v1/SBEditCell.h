/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCell.h"

@interface SBEditCell : SBCell
{
	id					mTarget;
	NSMutableString		*mString;
	int					mStringLength;
	int					mWidth, mHeight;
	int					mBeg, mEnd, mDisOff;
	BOOL				mFocused, mModified, mDoubleClicked;
}

- (void) setTarget:(id)target;
- (void) setWidth:(int)width height:(int)height;

- (NSString*) string;
- (void) setString:(NSString*)string;

- (BOOL) editingValue;
- (void) endEditing;

- (int) posForX:(int)x;
- (int) xForPos:(int)pos;
- (void) updateDisplayOffset;

@end
