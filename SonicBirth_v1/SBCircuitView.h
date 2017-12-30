/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBRootCircuit.h"
#import "SBSettingsServer.h"
#import "SBInfoServer.h"

@class SBCircuitDocument;

@interface SBCircuitView : NSOpenGLView
{	
	IBOutlet NSWindow		*mWindow;
	
	IBOutlet NSTextField	*mCurrentLevel;
	IBOutlet NSButton		*mPrevLevel;
	IBOutlet NSButton		*mNextLevel;
	
	IBOutlet NSButton		*mMini;
	
	IBOutlet NSPopUpButton	*mElementsPopUp;
	
	IBOutlet NSWindow		*mGetStringWindow;
	IBOutlet NSTextField	*mGetStringDesc;
	IBOutlet NSTextField	*mGetStringTF;
	
	IBOutlet SBSettingsServer	*mSettingsServer;
	IBOutlet SBInfoServer		*mInfoServer;
	
	
	SBRootCircuit			*mRootCircuit;
	SBCircuit				*mCurCircuit;
	
	float					mLastX;
	float					mLastY;
	
	NSMutableArray			*mLevels;
	
	BOOL					mGuiMode;
	
	SBCircuitDocument		*mParent;
	
	NSMenu					*mMenu;
	
	NSMutableArray			*mReleaseArray;
	
	ogWrap					*mW;
	
	int						mTimers;
	
	BOOL					mLasso;
	NSPoint					mLassoStart, mLassoEnd;
}

- (void) importCircuit:(id)sender;
- (BOOL) importCircuitAtPath:(NSString *)inPath atPosition:(NSPoint)inPosition positionElement:(BOOL)positionElement;
- (void) saveCircuit:(id)sender;

- (void) setParent:(SBCircuitDocument*)parent;

- (void) updateCurCircuit;
- (void) setRootCircuit:(SBRootCircuit*)c;

- (IBAction) insertElement:(id)sender;
- (BOOL)insertElementWithName:(NSString *)inName atPosition:(NSPoint)inPosition positionElement:(BOOL)positionElement;

- (IBAction) prevLevel:(id)sender;
- (IBAction) nextLevel:(id)sender;

- (IBAction) setMinSizeToCurrentSize:(id)sender;

- (void) elementPopUpWillShow:(NSNotification *)notification;

- (void) reselect;
- (void) updateForSelectedElement:(SBElement*)e;
- (void) circuitDidChangeView:(NSNotification *)notification;
- (void) circuitDidChangeGlobalView:(NSNotification *)notification;
- (void) circuitDidChangeMinSize:(NSNotification *)notification;

- (void) cut:(id)sender;
- (void) copy:(id)sender;
- (void) paste:(id)sender;
- (void) duplicate:(id)sender;
- (void) selectAll:(id)sender;

- (NSString*) newStringForDescription:(NSString*)desc oldString:(NSString*)oldString;
- (void) newStringCancel:(id)sender;
- (void) newStringOk:(id)sender;

- (void) mini:(id)sender;

- (void) addObjectToArray:(id)object;

// for copy/paste
+ (NSDictionary*) saveElement:(SBElement*)e;
+ (SBElement*) loadElement:(NSDictionary*)d;

+ (NSArray*) saveElements:(NSArray*)a;
+ (NSArray*) loadElements:(NSArray*)a;

+ (NSDictionary*) saveWire:(SBWire*)w elements:(NSArray*)e;
+ (SBWire*) loadWire:(NSDictionary*)d elements:(NSArray*)e;

+ (NSArray*) saveWires:(NSArray*)a elements:(NSArray*)e;
+ (NSArray*) loadWires:(NSArray*)a elements:(NSArray*)e;

- (NSButton *)mPrevLevel;
- (NSButton *)mNextLevel;

- (SBCircuit *)mCurCircuit;

@end
