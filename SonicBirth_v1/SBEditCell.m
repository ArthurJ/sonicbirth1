/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBEditCell.h"
#import "SBElement.h"

#define kLetterWidth (5.f) // gFontMove in openGlWrap
#define kMaxStringLength (4000)

@implementation SBEditCell

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mTarget = nil;
		mString = [[NSMutableString alloc] init];
		if (!mString)
		{
			[self release];
			return nil;
		}
		
		mStringLength = 0;
		
		mWidth = 64;
		mHeight = 16;
		
		mFocused = NO;
		mModified = NO;
		
		mBeg = mEnd = 0;
		
		mDisOff = 0;
	}
	return self;
}

- (void) dealloc
{
	if (mString) [mString release];
	[super dealloc];
}

- (void) setTarget:(id)target
{
	mTarget = target;
}

- (void) setWidth:(int)width height:(int)height
{
	if (width < 10) width = 10; else if (width > 500) width = 500;
	if (height < 10) height = 10; else if (height > 500) height = 500;

	mWidth = width;
	mHeight = height;
}

- (NSString*) string
{
	return mString;
}

- (void) setString:(NSString*)string
{
	[mString setString:(string) ? string : @""];
	mStringLength = [mString length];
	if (mBeg > mStringLength) mBeg = mStringLength;
	if (mEnd > mStringLength) mEnd = mStringLength;
	[self updateDisplayOffset];
}

- (BOOL) editingValue
{
	return mFocused;
}

- (void) endEditing
{
	if (mTarget && [mTarget respondsToSelector:@selector(editCellUpdated:)])
		[(NSObject*)mTarget performSelector:@selector(editCellUpdated:) withObject:self];

	mModified = NO;
	mFocused = NO;
}

- (NSSize) contentSize
{
	NSSize s = { mWidth, mHeight }; 
	return s;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	NSRect back = { origin, { mWidth, mHeight }};

	// draw back	
	ogSetColor(mColorBack);
	ogFillRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height);

	// draw selection
	if (mFocused)
	{
		if (mBeg == mEnd)
		{
			int ox = origin.x + [self xForPos:mBeg];
			
			ogSetColor(mColorFront);
			ogStrokeLine(ox, origin.y, ox, origin.y + mHeight);
		}
		else
		{
			int beg = (mBeg < mEnd) ? mBeg : mEnd;
			int end = (mBeg > mEnd) ? mBeg : mEnd;
		
			int x1 = [self xForPos:beg];
			int x2 = [self xForPos:end];

			ogSetColor(gSelectedColor);
			ogFillRectangle(origin.x + x1, origin.y, x2 - x1, mHeight);
		}
	}
	
	// draw contour
	ogSetColor(mColorContour);
	ogStrokeRectangle(back.origin.x, back.origin.y, back.size.width, back.size.height);
	
	// draw text
	ogSetColor(mColorFront);
	if (mFocused)
		ogDrawStringInRect([mString UTF8String] + mDisOff,
								back.origin.x + 2, back.origin.y + 1,
								back.size.width - 4, back.size.height - 2);
	else
	{
		NSString *st = mString;
		int ln = mWidth / kLetterWidth;
		if (mStringLength > ln && ln > 7)
		{
			st = [mString substringToIndex:ln - 2];
			st = [st stringByAppendingString:@".."];
		}
		ogDrawStringInRect([st UTF8String],
								back.origin.x + 2, back.origin.y + 1,
								back.size.width - 4, back.size.height - 2);
	}
}

- (int) posForX:(int)x
{
	int pos;

	int ln = mWidth / kLetterWidth;
	if (mStringLength < ln) ln = mStringLength;

	float ox = (mWidth - (ln * kLetterWidth)) * 0.5f;
	pos = (x - ox) / kLetterWidth;

	pos += mDisOff;
	
	if (pos < 0) pos = 0;
	if (pos > mStringLength) pos = mStringLength;
	
	return pos;
}

- (int) xForPos:(int)pos
{
	pos -= mDisOff;

	int ln = mWidth / kLetterWidth;
	if (mStringLength < ln) ln = mStringLength;

	int x = (mWidth - (ln * kLetterWidth)) * 0.5f + pos * kLetterWidth;
	
	if (x < 0) return 0;
	if (x > mWidth) return mWidth;
	
	return x;
}

- (void) updateDisplayOffset
{
	int beg = (mBeg < mEnd) ? mBeg : mEnd;
	int end = (mBeg > mEnd) ? mBeg : mEnd;
	
	int ln = mWidth / kLetterWidth;
	int disOff = beg + ((end - beg - ln) >> 1);
	if (disOff > beg) disOff = beg;
	
	if (disOff > mStringLength - ln) disOff = mStringLength - ln;
	if (disOff < 0) disOff = 0;

	mDisOff = disOff;
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	mEnd = mBeg = 0; mFocused = NO;
	if (x < 0 || x >= mWidth || y < 0 || y >= mHeight) { if (mModified) [self endEditing]; return NO; }
	mFocused = YES;
	mDoubleClicked = NO;
	
	if (clickCount == 2)
	{
		mBeg = 0;
		mEnd = mStringLength;
		mDoubleClicked = YES;
		[self updateDisplayOffset];
		return YES;
	}

	mEnd = mBeg = [self posForX:x];
	
	return YES;
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	if (!mFocused) return NO;
	if (mDoubleClicked) return YES;
	
	mEnd = [self posForX:x];
	
	if (mEnd < mDisOff)
		mDisOff = mEnd;
	else
	{
		int ln = mWidth / kLetterWidth;
		if (mEnd > (mDisOff + ln))
			mDisOff = mEnd - ln;
	}

	return YES;
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	if (!mFocused) return NO;
	if (mDoubleClicked) return YES;
	
	mEnd = [self posForX:x];
	[self updateDisplayOffset];

	return YES;
}

- (BOOL) keyDown:(unichar)ukey
{
	if (!mFocused) return NO;

	int beg = (mBeg < mEnd) ? mBeg : mEnd;
	int end = (mBeg > mEnd) ? mBeg : mEnd;
	
	// move cursor left
	if (ukey == NSLeftArrowFunctionKey)
	{
		beg--;
		if (beg < 0) beg = 0;
		mEnd = mBeg = beg;
		[self updateDisplayOffset];
		return YES;
	}
	
	// move cursor right
	if (ukey == NSRightArrowFunctionKey)
	{
		end++;
		if (end > mStringLength) end = mStringLength;
		mEnd = mBeg = end;
		[self updateDisplayOffset];
		return YES;
	}
	
	// end editing
	if (ukey == '\n' || ukey == '\r' || ukey == 3)
	{
		[self endEditing];
		mBeg = 0;
		mEnd = mStringLength;
		[self updateDisplayOffset];
		return YES;
	}

	// delete left
	if (ukey == 0x7F)
	{
		if (beg == end && beg > 0) { beg--; [mString deleteCharactersInRange:NSMakeRange(beg, 1)]; }
		else [mString deleteCharactersInRange:NSMakeRange(beg, end - beg)];
	}
	
	// delete right
	else if (ukey == NSDeleteFunctionKey)
	{
		if (beg == end && beg < mStringLength) [mString deleteCharactersInRange:NSMakeRange(beg, 1)];
		else [mString deleteCharactersInRange:NSMakeRange(beg, end - beg)];
	}
	
	// insert char
	else if (ukey >= 33 && ukey <= 126 && mStringLength < kMaxStringLength)
	{
		if (beg == end) [mString insertString:[NSString stringWithCharacters:&ukey length:1] atIndex:beg];
		else [mString replaceCharactersInRange:NSMakeRange(beg, end - beg) withString:[NSString stringWithCharacters:&ukey length:1]];
		beg++;
	}
	
	else return NO;
	
	mStringLength = [mString length];
	mEnd = mBeg = beg;
	mModified = YES;
	[self updateDisplayOffset];
	
	return YES;
}

- (void) setSelected:(BOOL)selected
{
//	mSelected = selected;
	if (!selected)
	{
		if (mModified) [self endEditing];
		mFocused = NO;
		mEnd = mBeg = 0; 
	}
}

@end
