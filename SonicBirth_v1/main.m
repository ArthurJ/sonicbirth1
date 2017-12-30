/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import <Cocoa/Cocoa.h>
#import "FrameworkVersion.h"
#import "SBExportServer.h"
#import "SBElementServer.h"
/*
#import "equation.h"

int main(int argc, const char *argv[])
{
	for (int i = 0; i < 1000; i++)
	{
		EquationState eqs = parseEquation("sin(i0)+i0;", 1);
	}

	return 0;
}
*/

int main(int argc, const char *argv[])
{

	NSAutoreleasePool * loaderPool = [[NSAutoreleasePool alloc] init];
	
	frameworkInit(0);
	
	if (getSonicBirthFrameworkVersion() != kCurrentVersion)
	{
		NSApplicationLoad();
		
		NSRunAlertPanel(@"SonicBirth",
						@"The framework version does not match the application version. "
						@"Please update both of them.",
						nil, nil, nil);
		
		[loaderPool release];
		
		return 2;
	}
	
	if (argc >= 4)
	{
		if (!strcmp(argv[1], "-batchToAU"))
		{
			NSApplicationLoad(); 
			[[SBElementServer alloc] init]; 
			SBExportServer *es = [[[SBExportServer alloc] init] autorelease];
			
			[es batchExportFrom:[NSString stringWithCString:argv[2]]
							 to:[NSString stringWithCString:argv[3]]
						   toAU:YES];
			[loaderPool release]; 
			return 0;
		}
		else if (!strcmp(argv[1], "-batchToVST"))
		{
			NSApplicationLoad(); 
			[[SBElementServer alloc] init]; 
			SBExportServer *es = [[[SBExportServer alloc] init] autorelease];
			
			[es batchExportFrom:[NSString stringWithCString:argv[2]]
							 to:[NSString stringWithCString:argv[3]]
						   toAU:NO];
			[loaderPool release]; 
			return 0;
			
		}
		else if (!strcmp(argv[1], "-singleToAU"))
		{
			NSApplicationLoad(); 
			[[SBElementServer alloc] init]; 
			SBExportServer *es = [[[SBExportServer alloc] init] autorelease];
			
			[es exportFrom:[NSString stringWithCString:argv[2]]
						to:[NSString stringWithCString:argv[3]]
					  toAU:YES];
			[loaderPool release]; 
			return 0;
			
		}
		else if (!strcmp(argv[1], "-singleToVST"))
		{
			NSApplicationLoad(); 
			[[SBElementServer alloc] init]; 
			SBExportServer *es = [[[SBExportServer alloc] init] autorelease];
			
			[es exportFrom:[NSString stringWithCString:argv[2]]
						to:[NSString stringWithCString:argv[3]]
					  toAU:NO];
			[loaderPool release]; 
			return 0;
			
		}
	}
	
	[loaderPool release];
	
	return NSApplicationMain(argc, argv);
}

