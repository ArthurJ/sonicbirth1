/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import <Foundation/Foundation.h>

enum
{
	FAILURE = 1,
	SUCCESS = 0
};

int main(int argc, char *argv[])
{
	if (argc < 2) return FAILURE;


	if (!strcmp(argv[1], "delete") && argc == 3)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *pt = [NSString stringWithCString:argv[2]];
		
		NSFileManager *fm = [NSFileManager defaultManager];

		BOOL ok = [fm removeFileAtPath:pt handler:nil];
	
		[pool release];
		
		return (ok) ? SUCCESS : FAILURE;
	}
	
	
	if (!strcmp(argv[1], "copy") && argc == 4)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *s = [NSString stringWithCString:argv[2]];
		NSString *d = [NSString stringWithCString:argv[3]];
		
		NSFileManager *fm = [NSFileManager defaultManager];
		
		// create directories
		NSArray *a = [d pathComponents];
		int c = [a count] - 1, i;
		
		// object 0 is "/" which always exists
		
		NSString *cur = [a objectAtIndex:0];
		for (i = 1; i < c; i++)
		{
			cur = [cur stringByAppendingPathComponent:[a objectAtIndex:i]];
			
			if (![fm fileExistsAtPath:cur])
			{
				BOOL ok = [fm createDirectoryAtPath:cur attributes:nil];
				if (!ok)
				{
					[pool release];
					return FAILURE;
				}
			}
		}
	
		BOOL ok = [fm copyPath:s toPath:d handler:nil];
		
		[pool release];
		
		return (ok) ? SUCCESS : FAILURE;
	}


	return FAILURE;
}







