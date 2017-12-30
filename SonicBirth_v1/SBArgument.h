/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

extern NSString *kSBArgumentDidChangeParameterValueNotification;
extern NSString *kSBArgumentBeginGestureNotification;
extern NSString *kSBArgumentEndGestureNotification;
extern NSString *kSBArgumentDidChangeParameterInfo;

@interface SBArgument : SBElement
{
	NSColor					*mCircuitColors[3];
	NSColor					*mCustomColors[3];
	BOOL					mUseCustomColor;
	
	IBOutlet NSView			*mColorsView;
	IBOutlet NSButton		*mUseCustomColorBt;
	IBOutlet NSColorWell	*mColorWellBack;
	IBOutlet NSColorWell	*mColorWellContour;
	IBOutlet NSColorWell	*mColorWellFront;
}
- (void) changeCustomColor:(id)sender;


- (void) setName:(NSString*)name;
- (int) numberOfParameters;

- (NSString*) nameForParameter:(int)i;
- (double) minValueForParameter:(int)i;
- (double) maxValueForParameter:(int)i;
- (BOOL) logarithmicForParameter:(int)i;
- (BOOL) realtimeForParameter:(int)i;
- (SBParameterType) typeForParameter:(int)i;
- (BOOL) readFlagForParameter:(int)i;
- (BOOL) writeFlagForParameter:(int)i;

// for indexed types:
- (NSArray*) indexedNamesForParameter:(int)i;

- (double) currentValueForParameter:(int)i;
- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i;

- (void) didChangeParameterInfo;
- (void) didChangeParameterValueAtIndex:(int)index;
- (void) beginGestureForParameterAtIndex:(int)index;
- (void) endGestureForParameterAtIndex:(int)index;

- (id) savePreset;
- (void) loadPreset:(id)preset;

- (BOOL) selfManagesSharingArgumentFrom:(SBArgument*)argument shareCount:(int)shareCount;
	// si retourne NO, releaser et mettre l'autre à sa place (comme d'habitude)
	// sinon, rien n'est fait: l'argument s'en est occupé
- (BOOL) executeEvenIfShared;
@end
