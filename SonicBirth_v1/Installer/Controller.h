/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import <Cocoa/Cocoa.h>
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>


@interface Controller : NSObject
{
	IBOutlet NSTableView		*mFilesToDeleteTable;
	NSMutableArray				*mFilesToDelete;
	NSMutableArray				*mFilesToDeleteActive;
	
	IBOutlet NSTableView		*mFilesToInstallTable;
	NSMutableArray				*mFilesToInstallSrc;
	NSMutableArray				*mFilesToInstallDst;
	NSMutableArray				*mFilesToInstallActive;
	
	IBOutlet NSTextField			*mStatus;
	IBOutlet NSProgressIndicator	*mProgress;
	IBOutlet NSMatrix				*mInstallDst;
	
	BOOL						mErrorHappened;
	AuthorizationRef			mAuth;
}

- (void) checkSystemRequirements;
- (BOOL) shouldDeletePluginAtPath:(NSString*)path;

- (void) listFilesToDelete;
- (void) findApplicationToDelete;
- (void) findFrameworksToDelete;
- (void) findPluginsToDelete;
- (void) findPluginToDelete:(NSString*)path extension:(NSString*)extension;

- (void) listFilesToInstall;
- (void) listFilesToInstallFrom:(NSString*)source installPrefix:(NSString*)prefix;

- (void) cantDeleteFile:(NSString*) path;
- (void) cantInstallFile:(NSString*) path;
- (void) cantCreateDirectory:(NSString*) path;

- (void) startInstall:(id)sender;
- (void) startUninstall:(id)sender;
- (void) deleteFileAtPath:(NSString*)path;
- (void) installFileFromPath:(NSString*)src toPath:(NSString*)dst;
- (void) createDirectoryAtPath:(NSString*)path;

- (void) changedConfig:(id)sender;
- (void) setStatus:(NSString*)status;

- (void) authorize;
- (BOOL) executeFileHelperArg1:(NSString*)arg1 arg2:(NSString*)arg2 arg3:(NSString*)arg3;

@end
