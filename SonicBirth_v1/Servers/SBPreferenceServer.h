/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

extern BOOL gShowWireAnchors;
extern BOOL gShowGuiDesignGrid;
extern float gBackgroundColor[3];

@interface SBPreferenceServer : NSObject
{
	IBOutlet NSButton		*mShowWireAnchors;
	IBOutlet NSButton		*mShowGuiDesignGrid;
	IBOutlet NSColorWell	*mColorWellBack;
}

- (IBAction) changedWireAnchors:(id)sender;
- (IBAction) changedGuiDesignGrid:(id)sender;
- (IBAction) changedBackColor:(id)sender;

+ (void) loadPref;
- (void) loadPref;
- (void) savePref;

- (void) updateCircuits;

@end
