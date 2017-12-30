/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSettingsServer.h"

@class SBCircuitDocument, SBRootCircuit, SBCircuitView;

@interface SBAppDelegate : NSObject
{
	IBOutlet NSWindow		*mRegWindow;
	IBOutlet NSTextField	*mName;
	IBOutlet NSTextField	*mNumber;

	IBOutlet NSButton		*mCheckAtStart;

	IBOutlet NSMenuItem		*mDuplicate;

	IBOutlet SBSettingsServer *mSettingsServer;

	NSWindow				*mSplashWindow;
}

- (void) displayHelp:(id)sender;

- (void) confirm:(id)sender;
- (void) demo:(id)sender;

- (void) checkVersion:(id)ignored;
- (void) newVersionAvailable:(id)ignored;

- (void) changedCheckAtStartUpPref:(id)sender;

- (void) openPlugin:(id)sender;

- (void) beginSplashScreen;
- (void) endSplashScreen;

// Simple method to get the current SBCircuitDocument. May return nil.
- (SBCircuitDocument *)currentSBCircuitDocument;
// Simple method to get the current doc's SBRootCircuit. May return nil.
- (SBRootCircuit *)rootCircuitOfCurrentDocument;
// Simple method to get the current doc's SBCircuitView. May return nil.
- (SBCircuitView *)circuitViewOfCurrentDocument;

- (IBAction)performImportCircuit:(id)sender;

- (IBAction)performGoToPreviousLevel:(id)sender;
- (IBAction)performGoToNextLevel:(id)sender;

- (IBAction)performDisplayCircuitDesign:(id)sender;
- (IBAction)performDisplayGUIDesign:(id)sender;
- (IBAction)performDisplayRuntime:(id)sender;

#pragma mark Save Selected Circuit As

- (IBAction)performSaveSelectedCircuitAs:(id)sender;
- (BOOL)eligibleForSaveSelectedCircuitAs;
- (BOOL)saveSelectedCircuitUsingPrompt:(BOOL*)userCanceled;
- (NSDictionary *)dictionaryRepresentationForSelectedCircuit:(NSString **)circuitName;
- (BOOL)writeDictionaryRepresentation:(NSDictionary *)dictRep toPath:(NSString *)inPathe;

@end
