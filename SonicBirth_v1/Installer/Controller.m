/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "Controller.h"

@implementation Controller

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		#define ALLOC(t, i) i = [[t alloc] init]; if (!i) { [self release]; return nil; }
		
		ALLOC(NSMutableArray, mFilesToDelete)
		ALLOC(NSMutableArray, mFilesToDeleteActive)
		ALLOC(NSMutableArray, mFilesToInstallSrc)
		ALLOC(NSMutableArray, mFilesToInstallDst)
		ALLOC(NSMutableArray, mFilesToInstallActive)
		
		#undef ALLOC
	}
	return self;
}

- (void) dealloc
{
	#define RELEASE(x) if (x) [x release];
	
	RELEASE(mFilesToDelete)
	RELEASE(mFilesToDeleteActive)
	RELEASE(mFilesToInstallSrc)
	RELEASE(mFilesToInstallDst)
	RELEASE(mFilesToInstallActive)
	
	#undef RELEASE
	
	if (mAuth) AuthorizationFree(mAuth, kAuthorizationFlagDefaults);
	
	[super dealloc];
}

- (void) checkSystemRequirements
{
	#define kMinOSVersion (0x1039)
	#define kMinQuicktimeVersion (0x700)
	
	OSErr err;
	
	int systemVersion = kMinOSVersion;
	int quicktimeVersion = kMinQuicktimeVersion;

	long result = 0;
	err = Gestalt(gestaltSystemVersion , &result);
	if (!err) systemVersion = result & 0xFFFF;
	
	err = Gestalt(gestaltQuickTimeVersion , &result);
	if (!err) quicktimeVersion = result >> 16;

	//printf("systemVersion: 0x%X quicktimeVersion: 0x%X\n", systemVersion, quicktimeVersion);
	if (systemVersion < kMinOSVersion || quicktimeVersion < kMinQuicktimeVersion)
	{
		NSRunAlertPanel(@"System requirements failure",
							[NSString stringWithFormat:
							
								@"Your system does not meet SonicBirth requirements. "
								@"You need at least MacOS %i%i.%i.%i and Quicktime %i.%i.%i. "
								@"You appear to be running MacOS %i%i.%i.%i and Quicktime %i.%i.%i.",
								
								((kMinOSVersion >> 12) & 0xF),
								((kMinOSVersion >> 8) & 0xF),
								((kMinOSVersion >> 4) & 0xF),
								(kMinOSVersion & 0xF),
								
								((kMinQuicktimeVersion >> 8) & 0xF),
								((kMinQuicktimeVersion >> 4) & 0xF),
								(kMinQuicktimeVersion & 0xF),
								
								((systemVersion >> 12) & 0xF),
								((systemVersion >> 8) & 0xF),
								((systemVersion >> 4) & 0xF),
								(systemVersion & 0xF),

								((quicktimeVersion >> 8) & 0xF),
								((quicktimeVersion >> 4) & 0xF),
								(quicktimeVersion & 0xF)
							
							],
							nil, nil, nil);
	
		[NSApp terminate:nil];
	}
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self checkSystemRequirements];

	[self setStatus:@"Scanning files..."];
	[mProgress startAnimation:nil];
	
	[self listFilesToDelete];
	[self listFilesToInstall];
	
	[mFilesToDeleteTable reloadData];
	[mFilesToInstallTable reloadData];
	
	[self setStatus:@"Ready."];
	[mProgress stopAnimation:nil];
}

- (void) awakeFromNib
{
	//[super awakeFromNib];

	[self setStatus:@""];
	[mProgress stopAnimation:nil];
	
	[mFilesToDeleteTable reloadData];
	[mFilesToInstallTable reloadData];
}

- (void) listFilesToDelete
{
	[mFilesToDelete removeAllObjects];
	[mFilesToDeleteActive removeAllObjects];

	[self findApplicationToDelete];
	[self findFrameworksToDelete];
	[self findPluginsToDelete];
	
	int c = [mFilesToDelete count];
	while([mFilesToDeleteActive count] < c)
		[mFilesToDeleteActive addObject:[NSNumber numberWithInt:1]];
}

- (void) findApplicationToDelete
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	
	NSString *path1 = @"/Applications/SonicBirth.app";
	
	if ([fm fileExistsAtPath:[path1 stringByExpandingTildeInPath] isDirectory:&isDir] && isDir)
		[mFilesToDelete addObject:path1];
	
	
	NSString *path2 = @"~/Applications/SonicBirth.app";
	
	if ([fm fileExistsAtPath:[path2 stringByExpandingTildeInPath] isDirectory:&isDir] && isDir)
		[mFilesToDelete addObject:path2];
}

- (void) findFrameworksToDelete
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	
	NSString *path1 = @"/Library/Frameworks/SonicBirth.framework";
	
	if ([fm fileExistsAtPath:[path1 stringByExpandingTildeInPath] isDirectory:&isDir] && isDir)
		[mFilesToDelete addObject:path1];
	
	
	NSString *path2 = @"~/Library/Frameworks/SonicBirth.framework";
	
	if ([fm fileExistsAtPath:[path2 stringByExpandingTildeInPath] isDirectory:&isDir] && isDir)
		[mFilesToDelete addObject:path2];
}

- (BOOL) shouldDeletePluginAtPath:(NSString*)path
{
	// path is a fully expanded path in the form:
	//	/Library/Audio/Plug-Ins/Components/something.component

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	BOOL shouldDelete = NO;
	NSData *data;

	// try to open the model file and check if prebuilt
	data = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"Contents/Resources/model.sbc"]];
	if (data)
	{
		NSString *error = nil;
		NSDictionary *d = [NSPropertyListSerialization
								propertyListFromData:data
								mutabilityOption:NSPropertyListImmutable
								format:nil
								errorDescription:&error];
		if (d && !error)
		{
			NSNumber *n = [d objectForKey:@"subType"];
			if (n)
			{
				unsigned int st = [n unsignedIntValue];
				if ((st >> 24) == 'S') shouldDelete = YES;
			}
		}
		else
		{
			NSLog(@"Error while deserializing: %@", error);
			// [error release];
		}
	}

	if (!shouldDelete)
	{
		// try to check version from info.plist
		data = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"Contents/Info.plist"]];
		if (data)
		{
			NSString *error = nil;
			NSDictionary *d = [NSPropertyListSerialization
									propertyListFromData:data
									mutabilityOption:NSPropertyListImmutable
									format:nil
									errorDescription:&error];
			if (d && !error)
			{
				NSString *s = [d objectForKey:@"CFBundleVersion"];
				if (s)
				{
					NSComparisonResult cr = [s compare:@"1.0.2"]; // backward compatibility version for plugins
					if (cr == NSOrderedAscending) shouldDelete = YES;
				}
			}
			else
			{
				NSLog(@"Error while deserializing: %@", error);
				// [error release];
			}
		}

	}
	
	if (pool) [pool release];
	return shouldDelete;
}

- (void) findPluginsToDelete
{
	[self findPluginToDelete:@"/Library/Audio/Plug-Ins/Components" extension:@"component"];
	[self findPluginToDelete:@"~/Library/Audio/Plug-Ins/Components" extension:@"component"];
	
	[self findPluginToDelete:@"/Library/Audio/Plug-Ins/VST" extension:@"vst"];
	[self findPluginToDelete:@"~/Library/Audio/Plug-Ins/VST" extension:@"vst"];
}

- (void) findPluginToDelete:(NSString*)path extension:(NSString*)extension
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	NSString *path2 = [path stringByExpandingTildeInPath];
	
	NSArray *a = [fm subpathsAtPath:path2];
	int c = [a count], i;
	for (i = 0; i < c; i++)
	{
		NSString *pt = [a objectAtIndex:i];
		if (	[pt rangeOfString:@"SonicBirth"].location != NSNotFound
			&&	[pt rangeOfString:@"Contents"].location   == NSNotFound)
		{
			// this is for the in host design plugin
			[mFilesToDelete addObject:[path stringByAppendingPathComponent:pt]];
		}
		else
		{
			NSString *pt2 = [path2 stringByAppendingPathComponent:pt];
			if (	[[pt2 pathExtension] isEqual:extension]
				&&	[fm fileExistsAtPath:pt2 isDirectory:&isDir]
				&&	isDir)
			{
				NSString *pt3 = [pt2 stringByAppendingPathComponent:@"Contents/Resources/model.sbc"];
				if (	[fm fileExistsAtPath:pt3]
					&&	[self shouldDeletePluginAtPath:pt2])
					[mFilesToDelete addObject:[path stringByAppendingPathComponent:pt]];
			}
		}
	}
}

- (void) listFilesToInstall
{
	[mFilesToInstallSrc removeAllObjects];
	[mFilesToInstallDst removeAllObjects];
	[mFilesToInstallActive removeAllObjects];
	
	NSBundle *bdl = [NSBundle mainBundle];
	NSString *rs = [bdl resourcePath];
	
	[self listFilesToInstallFrom:	[rs stringByAppendingPathComponent:@"Applications"]
					installPrefix:	@"/Applications"];
					
	[self listFilesToInstallFrom:	[rs stringByAppendingPathComponent:@"Frameworks"]
					installPrefix:	@"/Library/Frameworks"];
					
	[self listFilesToInstallFrom:	[rs stringByAppendingPathComponent:@"AU"]
					installPrefix:	@"/Library/Audio/Plug-Ins/Components"];
					
	[self listFilesToInstallFrom:	[rs stringByAppendingPathComponent:@"VST"]
					installPrefix:	@"/Library/Audio/Plug-Ins/VST"];
	
	int c = [mFilesToInstallSrc count];
	while([mFilesToInstallActive count] < c)
		[mFilesToInstallActive addObject:[NSNumber numberWithInt:1]];
}

- (void) listFilesToInstallFrom:(NSString*)source installPrefix:(NSString*)prefix
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	
	NSArray *a = [fm directoryContentsAtPath:source];
	int c = [a count], i;
	for (i = 0; i < c; i++)
	{
		NSString *pt = [a objectAtIndex:i];
		NSString *pt2 = [source stringByAppendingPathComponent:pt];
		if (	[fm fileExistsAtPath:pt2 isDirectory:&isDir]
			&&	isDir)
		{
			[mFilesToInstallSrc addObject:pt2];
			[mFilesToInstallDst addObject:[prefix stringByAppendingPathComponent:pt]];
		}
	}
}

- (void) cantDeleteFile:(NSString*) path
{
	NSString *msg = (mAuth) ? @"Cannot delete file at %@" : @"Cannot delete file at %@, will retry with privileges.";
	NSRunAlertPanel(@"Delete failure", [NSString stringWithFormat:msg, path], nil, nil, nil);
	mErrorHappened = YES;
}

- (void) cantInstallFile:(NSString*) path
{
	NSString *msg = (mAuth) ? @"Cannot install file at %@" : @"Cannot install file at %@, will retry with privileges.";
	NSRunAlertPanel(@"Install failure", [NSString stringWithFormat:msg, path], nil, nil, nil);
	mErrorHappened = YES;
}

- (void) cantCreateDirectory:(NSString*) path
{
	NSString *msg = (mAuth) ? @"Cannot create directory at %@" : @"Cannot create directory at %@, will retry with privileges.";
	NSRunAlertPanel(@"Install failure", [NSString stringWithFormat:msg, path], nil, nil, nil);
	mErrorHappened = YES;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{	
	if (aTableView == mFilesToDeleteTable)
	{
		return [mFilesToDelete count];
	}
	else if (aTableView == mFilesToInstallTable)
	{
		return [mFilesToInstallDst count];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *ident = [aTableColumn identifier];
	
	if (aTableView == mFilesToDeleteTable)
	{
		if ([ident isEqual:@"path"]) return [mFilesToDelete objectAtIndex:rowIndex];
		else if ([ident isEqual:@"active"]) return [mFilesToDeleteActive objectAtIndex:rowIndex]; 
	}
	else if (aTableView == mFilesToInstallTable)
	{
		if ([ident isEqual:@"path"])
		{
			return [NSString stringWithFormat:@"%@%@",
						(([mInstallDst selectedColumn] == 0) ? @"" : @"~"),
						[mFilesToInstallDst objectAtIndex:rowIndex]];
		}
		else if ([ident isEqual:@"active"]) return [mFilesToInstallActive objectAtIndex:rowIndex];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *ident = [aTableColumn identifier];
	if (![ident isEqual:@"active"]) return;
	
	NSNumber *active = [NSNumber numberWithInt:([anObject intValue] != 0) ? 1 : 0];
	
	if (aTableView == mFilesToDeleteTable)
	{
		[mFilesToDeleteActive replaceObjectAtIndex:rowIndex withObject:active];
	}
	else if (aTableView == mFilesToInstallTable)
	{
		[mFilesToInstallActive replaceObjectAtIndex:rowIndex withObject:active];
	}
}

- (void) startInstall:(id)sender
{
	mErrorHappened = NO;

	int c, i;
	
	[self setStatus:@"Starting installation..."];
	[mProgress startAnimation:nil];
	

	c = [mFilesToDelete count];
	for (i = 0; i < c; i++)
		if ([[mFilesToDeleteActive objectAtIndex:i] intValue])
		{
			[self deleteFileAtPath:[mFilesToDelete objectAtIndex:i]];
			if (mErrorHappened)
			{
				if (mAuth) goto error;
				[self authorize];
				if (!mAuth) goto error;
				
				 // retry
				mErrorHappened = NO;
				i--;
			}
		}
			
			
	c = [mFilesToInstallDst count];
	for (i = 0; i < c; i++)
		if ([[mFilesToInstallActive objectAtIndex:i] intValue])
		{
			[self installFileFromPath:	[mFilesToInstallSrc objectAtIndex:i]
								toPath:	[NSString stringWithFormat:@"%@%@",
										(([mInstallDst selectedColumn] == 0) ? @"" : @"~"),
										[mFilesToInstallDst objectAtIndex:i]]];
			if (mErrorHappened)
			{
				if (mAuth) goto error;
				[self authorize];
				if (!mAuth) goto error;
				
				 // retry
				mErrorHappened = NO;
				i--;
			}
		}
								
	[self setStatus:@"Done."];
	[mProgress stopAnimation:nil];
	
	NSRunAlertPanel(@"Installation complete", @"Installation procedure has completed.", nil, nil, nil);
	
	// open application directory
	[[NSWorkspace sharedWorkspace] openFile:
						[[NSString stringWithFormat:@"%@%@",
						(([mInstallDst selectedColumn] == 0) ? @"" : @"~"),
						@"/Applications"]  stringByExpandingTildeInPath]];
	
	[NSApp terminate:nil];
	
	return;
	
error:

	[self setStatus:@"Scanning files..."];
	
	[self listFilesToDelete];
	[mFilesToDeleteTable reloadData];
	
	[self setStatus:@"Ready."];
	[mProgress stopAnimation:nil];
}

- (void) startUninstall:(id)sender
{
	mErrorHappened = NO;

	int c, i;
	
	[self setStatus:@"Starting uninstallation..."];
	[mProgress startAnimation:nil];
	
	c = [mFilesToDelete count];
	for (i = 0; i < c; i++)
		if ([[mFilesToDeleteActive objectAtIndex:i] intValue])
		{
			[self deleteFileAtPath:[mFilesToDelete objectAtIndex:i]];
			if (mErrorHappened)
			{
				if (mAuth) goto error;
				[self authorize];
				if (!mAuth) goto error;
				
				 // retry
				mErrorHappened = NO;
				i--;
			}
		}
								
	[self setStatus:@"Done."];
	[mProgress stopAnimation:nil];
	
	NSRunAlertPanel(@"Uninstallation complete", @"Uninstallation procedure has completed.", nil, nil, nil);
	[NSApp terminate:nil];
	
	return;
	
error:

	[self setStatus:@"Scanning files..."];
	
	[self listFilesToDelete];
	[mFilesToDeleteTable reloadData];
	
	[self setStatus:@"Ready."];
	[mProgress stopAnimation:nil];
}

- (void) deleteFileAtPath:(NSString*)path
{
	// expand tilde
	// NSLog(@"Delete %@\n", path);

	[self setStatus:[NSString stringWithFormat:@"Deleting %@...", path]];
	NSString *pt = [path stringByExpandingTildeInPath];
	
	BOOL ok;
	
	if (mAuth)
	{
		ok = [self executeFileHelperArg1:@"delete" arg2:pt arg3:nil];
	}
	else
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		ok = [fm removeFileAtPath:pt handler:nil];
	}

	if (!ok) [self cantDeleteFile:path];
}

- (void) installFileFromPath:(NSString*)src toPath:(NSString*)dst
{
	// expand tilde
	// NSLog(@"Install %@ to %@\n", src, dst);
	
	[self setStatus:[NSString stringWithFormat:@"Installing %@...", dst]];
	
	NSString *s = [src stringByExpandingTildeInPath];
	NSString *d = [dst stringByExpandingTildeInPath];
	
	BOOL ok;
	
	if (mAuth)
	{
		ok = [self executeFileHelperArg1:@"copy" arg2:s arg3:d];
	}
	else
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		[self createDirectoryAtPath:d];
		if (mErrorHappened) return;
	
		ok = [fm copyPath:s toPath:d handler:nil];
	}
	
	if (!ok) [self cantInstallFile:dst];
}

- (void) createDirectoryAtPath:(NSString*)path
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSArray *a = [path pathComponents];
	int c = [a count] - 1, i;
	
	// object 0 is "/" which always exists
	
	NSString *cur = [a objectAtIndex:0];
	for (i = 1; i < c; i++)
	{
		cur = [cur stringByAppendingPathComponent:[a objectAtIndex:i]];
		
		if (![fm fileExistsAtPath:cur])
		{
			BOOL ok = [fm createDirectoryAtPath:cur attributes:nil];
			if (!ok) [self cantCreateDirectory:path];
		}
	}
	
}

- (void) changedConfig:(id)sender
{
	[mFilesToInstallTable reloadData];
}

- (void) setStatus:(NSString*)status
{
	[mStatus setStringValue:status];
	[mStatus displayIfNeeded];
}

- (BOOL) executeFileHelperArg1:(NSString*)arg1 arg2:(NSString*)arg2 arg3:(NSString*)arg3
{
	if (!mAuth) return NO;

	NSBundle *bd = [NSBundle mainBundle];
	NSString *rs = [bd resourcePath];
	NSString *tool = [rs stringByAppendingPathComponent:@"fileHelper"];
	const char *toolCString = [tool fileSystemRepresentation];
	const char *args[] = {	(arg1) ? [arg1 cString] : nil,
							(arg2) ? [arg2 cString] : nil,
							(arg3) ? [arg3 cString] : nil,
							nil };
							
	OSStatus err = AuthorizationExecuteWithPrivileges(	mAuth, toolCString,
														kAuthorizationFlagDefaults,
														(char * const *)args, nil);
														
	if (err != errAuthorizationSuccess) return NO;
	 
	int status;
	int pid = wait(&status);
	if (pid == -1 || ! WIFEXITED(status))
		return NO;
		
	return (WEXITSTATUS(status) == 0) ? YES : NO;
}

- (void) authorize
{
	if (mAuth) return;
	
    OSStatus err = AuthorizationCreate(	nil, kAuthorizationEmptyEnvironment, 
										kAuthorizationFlagDefaults, &mAuth); 

    if (err != errAuthorizationSuccess)
	{
		mAuth = nil;
		return;
    }

	AuthorizationItem item = { kAuthorizationRightExecute, 0, NULL, 0}; 
	AuthorizationRights rights = {1, &item}; 

	AuthorizationFlags flags =	kAuthorizationFlagDefaults | 
								kAuthorizationFlagInteractionAllowed | 
								kAuthorizationFlagPreAuthorize | 
								kAuthorizationFlagExtendRights; 

	err = AuthorizationCopyRights (mAuth, &rights, nil, flags, nil); 
    if (err != errAuthorizationSuccess)
	{
		AuthorizationFree(mAuth, kAuthorizationFlagDefaults);
		mAuth = nil;
		return;
    }
}

@end
