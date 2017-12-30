/*
	Copyright 2005-2007 Antoine Missout, J Carlson
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAppDelegate.h"
#import "SBSettingsServer.h"

#include "FrameworkSettings.h"

#import "SBCircuitDocument.h"

@interface SBBlackBorderView : NSView
{}
@end

@implementation SBBlackBorderView
- (void)drawRect:(NSRect)aRect
{
	NSRect bd = [self bounds];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:bd];
}
- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (![self mouse:ml inRect:[self bounds]]) { [super mouseDown:theEvent]; return; }
	NSWindow *w = [self window];
	if (w) [w orderOut:nil];
}
@end

@interface SBSplashImageView : NSImageView
{}
@end

@implementation SBSplashImageView
- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint ml = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (![self mouse:ml inRect:[self bounds]]) { [super mouseDown:theEvent]; return; }
	NSWindow *w = [self window];
	if (w) [w orderOut:nil];
}
@end

@implementation SBAppDelegate

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[self beginSplashScreen];
	}
	return self;
}

- (void) dealloc
{
	if (mSplashWindow) [mSplashWindow release];
	[super dealloc];
}

- (void) checkVersion:(id)ignored
{
	NSURL *url = [NSURL URLWithString:@"http://" kHostnameNSString @"/Version.plist"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:url];
	if (dict)
	{
		int version = [[dict objectForKey:@"version"] intValue];
		if (version > kCurrentVersion)
			[self performSelectorOnMainThread:@selector(newVersionAvailable:) withObject:nil waitUntilDone:NO];
	}
	else
		NSLog(@"Can't connect to %@", [url description]);
}

- (void) newVersionAvailable:(id)ignored
{
	int choice = NSRunAlertPanel(@"SonicBirth",
							@"A new version is available. Visit http://" kHostnameNSString @" to learn more.",
							@"Download",
							@"Not now",
							@"Don't remind me");

	if (choice == NSAlertDefaultReturn) //Download
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://" kHostnameNSString]];

	if (choice == NSAlertOtherReturn) //Don't remind me
	{
		[mCheckAtStart setState:NSOffState];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"checkVersion"];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//[self endSplashScreen];

	// version check
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	NSNumber *check = [userDefaults objectForKey:@"checkVersion"];
	if (!check)
	{
		int choice = NSRunAlertPanel(@"SonicBirth",
									@"Would you like SonicBirth to check for version update at startup?.",
									@"Yes", @"No", nil);

		check = [NSNumber numberWithInt:(choice == NSAlertDefaultReturn) ? 2 : 1];
		[userDefaults setObject:check forKey:@"checkVersion"];
	}

	BOOL doTheCheck = ([check intValue] == 2);
	[mCheckAtStart setState:((doTheCheck) ? NSOnState : NSOffState)];

	if (doTheCheck)
		[NSApplication detachDrawingThread:@selector(checkVersion:) toTarget:self withObject:nil];

	NSDocumentController *dc = [NSDocumentController sharedDocumentController];
	if ([[dc documents] count] <= 0) [dc newDocument:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	if (mSettingsServer) [mSettingsServer setSettingsView:nil];
}

- (void) displayHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:
		[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Documentation.pdf"]];
}

- (void) confirm:(id)sender
{
	[NSApp stopModalWithCode:1];
}

- (void) demo:(id)sender
{
	[NSApp stopModalWithCode:0];
}

- (void) changedCheckAtStartUpPref:(id)sender
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	NSNumber *n = [NSNumber numberWithInt:(([mCheckAtStart state] == NSOnState) ? 2 : 1)];
	[userDefaults setObject:n forKey:@"checkVersion"];
}

- (void) awakeFromNib
{
	//[super awakeFromNib];

	[mDuplicate setTarget:nil];
	[mDuplicate setAction:@selector(duplicate:)];
}

- (void) openPlugin:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:YES];
	int result = [panel runModalForTypes:[NSArray arrayWithObjects: @"vst",
																	@"component",
																	nil]];

	if (result != NSOKButton) return;

	NSString *path = [panel filename];

	SBCircuitDocument *doc = [[SBCircuitDocument alloc] init];
	BOOL success = [doc readFromFile:path ofType:@"plugin"];
	if (!success)
	{
		[doc release];
		NSRunAlertPanel(@"SonicBirth",
						@"The selected file does not appear to be a plugin exported from SonicBirth.",
						nil, nil, nil);
		return;
	}


	[[NSDocumentController sharedDocumentController] addDocument:doc];
	[doc makeWindowControllers];
	[doc showWindows];
	[doc release];
}

- (void) beginSplashScreen
{
	NSRect windowRect	= { { 0, 0 },		{ 506, 155 } };
	NSRect imageRect	= { { 17, 17 },		{ 469, 100 } };
	NSRect versRect		= { { 450, 128 },	{ 50, 17 } };

	imageRect.origin.y = windowRect.size.height - imageRect.origin.y - imageRect.size.height;
	versRect.origin.y  = windowRect.size.height - versRect.origin.y  - versRect.size.height;

	// create the window
	mSplashWindow = [[NSWindow alloc] initWithContentRect:windowRect
										styleMask:NSBorderlessWindowMask
										backing:NSBackingStoreRetained
										defer:NO];
	if (!mSplashWindow) return;

	[mSplashWindow setLevel:NSModalPanelWindowLevel];

	// create the border view
	SBBlackBorderView *contentView = [[SBBlackBorderView alloc] initWithFrame:windowRect];
	if (!contentView)
	{
		[mSplashWindow release];
		return;
	}

	[mSplashWindow setContentView:contentView];
	[contentView release];

	// set the background color
	[mSplashWindow setBackgroundColor:[NSColor colorWithCalibratedRed:(255.f/255.f)
																green:(203.f/255.f)
																blue:(54.f/255.f)
																alpha:1.0f]];

	// create the image view
	SBSplashImageView *imageView = [[SBSplashImageView alloc] initWithFrame:imageRect];
	if (!imageView)
	{
		[mSplashWindow release];
		return;
	}

	NSBundle *mainBundle = [NSBundle mainBundle];
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[mainBundle pathForImageResource:@"sonicbirth_title.png"]];
	if (!image)
	{
		[imageView release];
		[mSplashWindow release];
		return;
	}

	[imageView setImage:image];
	[image release];

	[imageView setEditable:NO];

	[contentView addSubview:imageView];
	[imageView release];

	// create the version text field
	NSTextField *vers = [[NSTextField alloc] initWithFrame:versRect];
	if (!vers)
	{
		[mSplashWindow release];
		return;
	}

	[vers setEditable:NO]; [vers setBordered:NO]; [vers setDrawsBackground:NO];
	[vers setAlignment:NSRightTextAlignment];
	[vers setStringValue:[NSString stringWithFormat:@"v%i.%i.%i",
								((kCurrentVersion >> 16) & 0xFF),
								((kCurrentVersion >>  8) & 0xFF),
								(kCurrentVersion & 0xFF)]];
	[contentView addSubview:vers];
	[vers release];

	[mSplashWindow center];
	[mSplashWindow makeKeyAndOrderFront:nil];

	[self performSelector:@selector(endSplashScreen) withObject:nil afterDelay:2];
}

- (void) endSplashScreen
{
	if (mSplashWindow) { [mSplashWindow release]; mSplashWindow = nil; }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(performDisplayCircuitDesign:))
	{
		SBRootCircuit * rc = [self rootCircuitOfCurrentDocument];
		if (rc != nil && [rc guiMode] != kCircuitDesign)
			{ return YES; }
		return NO;
	}
	if ([menuItem action] == @selector(performDisplayGUIDesign:))
	{
		SBRootCircuit * rc = [self rootCircuitOfCurrentDocument];
		if (rc != nil && [rc guiMode] != kGuiDesign && [rc hasCustomGui])
			{ return YES; }
		return NO;
	}
	if ([menuItem action] == @selector(performDisplayRuntime:))
	{
		SBRootCircuit * rc = [self rootCircuitOfCurrentDocument];
		if (rc != nil && [rc guiMode] != kRuntime && [rc hasCustomGui])
			{ return YES; }
		return NO;
	}
// Antoine, I really couldn't see a way to validate previousLevel/nextLevel without relying on the UI (or having to write a lot of code).
// Can you think of a better way?
	if ([menuItem action] == @selector(performGoToNextLevel:))
	{
		SBCircuitView * cv = [self circuitViewOfCurrentDocument];
		if (cv != nil && [[cv mNextLevel] isEnabled])
			{ return YES; }
		return NO;
	}
	if ([menuItem action] == @selector(performGoToPreviousLevel:))
	{
		SBCircuitView * cv = [self circuitViewOfCurrentDocument];
		if (cv != nil && [[cv mPrevLevel] isEnabled])
			{ return YES; }
		return NO;
	}
	if ([menuItem action] == @selector(performImportCircuit:))
	{
		if ([[NSDocumentController sharedDocumentController] currentDocument] != nil)
			{ return YES; }
		return NO;
	}
	if ([menuItem action] == @selector(performSaveSelectedCircuitAs:))
		{ return [self eligibleForSaveSelectedCircuitAs]; }
	return YES;
}

- (IBAction)performImportCircuit:(id)sender
{
	SBCircuitView * cv = [self circuitViewOfCurrentDocument];
	if (cv != nil)
		{ [cv importCircuit:nil]; }
}

- (IBAction)performGoToPreviousLevel:(id)sender
{
	SBCircuitDocument * doc = [self currentSBCircuitDocument];
	if (doc != nil && [doc respondsToSelector:@selector(circuitView)] && [doc circuitView] != nil && [[doc circuitView] respondsToSelector:@selector(prevLevel:)])
		{ [[doc circuitView] prevLevel:nil]; }
}

- (IBAction)performGoToNextLevel:(id)sender
{
	SBCircuitDocument * doc = [self currentSBCircuitDocument];
	if (doc != nil && [doc respondsToSelector:@selector(circuitView)] && [doc circuitView] != nil && [[doc circuitView] respondsToSelector:@selector(nextLevel:)])
		{ [[doc circuitView] nextLevel:nil]; }
}

- (IBAction)performDisplayCircuitDesign:(id)sender
{
	SBRootCircuit * circuit = [self rootCircuitOfCurrentDocument];
	if (circuit != nil && [circuit guiMode] != kCircuitDesign)
	{
		[circuit setGuiMode:kCircuitDesign];
		[circuit didChangeMinSize];
		[circuit didChangeGlobalView];
		[circuit updateGUIModeMatrixFromInternalState];
	}
}

- (IBAction)performDisplayGUIDesign:(id)sender
{
	SBRootCircuit * circuit = [self rootCircuitOfCurrentDocument];
	if (circuit != nil && [circuit hasCustomGui] && [circuit guiMode] != kGuiDesign)
	{
		[circuit setGuiMode:kGuiDesign];
		[circuit didChangeMinSize];
		[circuit didChangeGlobalView];
		[circuit updateGUIModeMatrixFromInternalState];
	}
}

- (IBAction)performDisplayRuntime:(id)sender
{
	SBRootCircuit * circuit = [self rootCircuitOfCurrentDocument];
	if (circuit != nil && [circuit hasCustomGui] && [circuit guiMode] != kRuntime)
	{
		[circuit setGuiMode:kRuntime];
		[circuit didChangeMinSize];
		[circuit didChangeGlobalView];
		[circuit updateGUIModeMatrixFromInternalState];
	}
}

- (SBCircuitDocument *)currentSBCircuitDocument
{
	id doc = [[NSDocumentController sharedDocumentController] currentDocument];
	if ([[doc className] isEqualToString:[SBCircuitDocument className]])
		{ return doc; }
	return nil;
}

- (SBRootCircuit *)rootCircuitOfCurrentDocument
{
	SBCircuitDocument * doc = [self currentSBCircuitDocument];
	if (doc != nil && [doc respondsToSelector:@selector(circuit)])
		{ return [doc circuit]; }
	return nil;
}

- (SBCircuitView *)circuitViewOfCurrentDocument
{
	SBCircuitDocument * doc = [self currentSBCircuitDocument];
	if (doc != nil && [doc respondsToSelector:@selector(circuitView)])
		{ return [doc circuitView]; }
	return nil;
}

- (IBAction)performSaveSelectedCircuitAs:(id)sender
{
	BOOL userCanceled = NO;
	BOOL savedOK = [self saveSelectedCircuitUsingPrompt:&userCanceled];
	if (userCanceled)
		{ return; }
	if (savedOK == NO)
		{ NSRunAlertPanel(@"Alert", @"An error was encountered while attempting to save the circuit.", @"Continue", nil, nil); } 
}

- (BOOL)eligibleForSaveSelectedCircuitAs
{
	SBCircuitView * cv = [self circuitViewOfCurrentDocument];
	if (cv == nil)
		{ return NO; }

	NSArray * selection = [[cv mCurCircuit] selectedElements];
	if (selection == nil || [selection count] != 1)
		{ return NO; }

	if ([[[selection objectAtIndex:0] className] isEqualToString:@"SBCircuit"])
		{ return YES; }
	return NO;
}

- (BOOL)saveSelectedCircuitUsingPrompt:(BOOL*)userCanceled
{
	*userCanceled = NO;
	NSString * circuitName;
	NSDictionary * outDict = [self dictionaryRepresentationForSelectedCircuit:&circuitName];

	if (outDict == nil)
	{
		// NSLog(@"Unable to create dictionary representation for selection. The selection may not have been valid.");
		return NO;
	}

	NSSavePanel * panel = [NSSavePanel savePanel];
	NSString * requiredExtension = [NSString stringWithString:@"sbc"];

	[panel setCanCreateDirectories:YES];
	[panel setCanSelectHiddenExtension:YES];
	[panel setExtensionHidden:YES];
	[panel setRequiredFileType:requiredExtension];

	int result = [panel runModalForDirectory:nil file:circuitName];
	if (result != NSOKButton)
	{ 
		*userCanceled = YES;
		return NO;
	}

	NSString * filename = [panel filename];

	if (filename == nil || [filename length] < 4)
		{ return NO; }

	BOOL res = [self writeDictionaryRepresentation:outDict toPath:filename];
	return res;
}

- (NSDictionary *)dictionaryRepresentationForSelectedCircuit:(NSString **)circuitName
{
	SBCircuitView * cv = [self circuitViewOfCurrentDocument];
	if (cv == nil)
		{ return nil; }

	NSArray * selection = [[cv mCurCircuit] selectedElements];
	if (selection == nil || [selection count] != 1)
		{ return nil; }

	if ([[[selection objectAtIndex:0] className] isEqualToString:@"SBCircuit"] == NO)
		{ return nil; }

	SBCircuit * circuit = [selection objectAtIndex:0];
	if (circuit == nil)
		{ return nil; }

	*circuitName = [NSString string];

	if ([circuit name] != nil)
		{ *circuitName = [NSString stringWithString:[circuit name]]; }

	NSMutableDictionary * tmpDict = [circuit saveData];
	if (tmpDict == nil)
		{ return nil; }
	NSDictionary * outDict = [NSDictionary dictionaryWithDictionary:tmpDict];
	if (outDict == nil)
		{ return nil; }
	return outDict;
}

#warning Antoine, should we declare a new type for exported subcircuits?

- (BOOL)writeDictionaryRepresentation:(NSDictionary *)dictRep toPath:(NSString *)inPath
{
	if (inPath == nil || dictRep == nil)
		{ return NO; }

	NSString * path = [NSString stringWithString:inPath];

	NSString * error = nil;
	NSData * data = [NSPropertyListSerialization dataFromPropertyList:dictRep format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];

	if (data != nil && error == nil && [data writeToFile:path atomically:YES])
	{
		//NSLog(@"Export succeeded");
		return YES;
	} else {
		//NSLog(@"Error while serializing: %@", error);
		return NO;
	}

	return NO;
}

@end
