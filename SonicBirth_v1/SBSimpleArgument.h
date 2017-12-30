/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBArgument.h"

@interface SBSimpleArgument : SBArgument
{
@public
	IBOutlet NSButton   *mRealtimeButton;
	IBOutlet NSTextField *mNameTF;
	IBOutlet NSSlider		*mAverageSlider;
	IBOutlet NSTextField	*mAverageTF;
	
	NSMutableString *mName;
	BOOL mRealtime;

	double mCurrentCoeff, mTargetCoeff;
	int mOffsetToChange[kMaxChannels];
	double mNewValue[kMaxChannels];
	double mTargetValue[kMaxChannels];
	double mCurrentValue[kMaxChannels];
	
	int mNumberOfOutputs;
	float mAverageMs;
}

- (void) setValue:(double)value forOutput:(int)output offsetToChange:(int)offset;

- (void) setName:(NSString*)name;
- (void) setRealtime:(BOOL)realtime;

- (double) minValue;
- (double) maxValue;
- (BOOL) logarithmic;
- (BOOL) realtime;
- (SBParameterType) type;

// for indexed types:
- (NSArray*) indexedNames;

- (double) currentValue;
- (void) takeValue:(double)preset offsetToChange:(int)offset;

- (IBAction) pushedRealtimeButton:(id)sender;
- (void) controlTextDidEndEditing:(NSNotification *)aNotification;

- (IBAction) changedAverage:(id)sender;

@end
