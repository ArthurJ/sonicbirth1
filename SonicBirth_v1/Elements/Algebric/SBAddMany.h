

#import "SBElement.h"

@interface SBAddMany : SBElement
{
@public
	IBOutlet	NSTextField		*mTF;
	IBOutlet	NSView			*mSettingsView;
	
	int		mInputs;
}

- (void) updateInputs;

@end
