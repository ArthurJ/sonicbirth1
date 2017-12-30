/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
// ============================================================================================
// from http://www.cocoadev.com/index.pl?AudioUnitEditorWindow (Jeremy Jurksztowicz)

#import <AppKit/AppKit.h>
#include <AudioUnit/AudioUnit.h>

// ============================================================================================
@interface SBAudioUnitEditor : NSObject
{
	AudioUnit mEditUnit;
	id mDelegate;
	NSWindow *mWindow;
}

// --------------------------------------------------------------------------------------------
- (id) initWithAudioUnit:(AudioUnit)unit forceGeneric:(BOOL)forceGeneric delegate:(id)delegate;
- (void) show;

@end






