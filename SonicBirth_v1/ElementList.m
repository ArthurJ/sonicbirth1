/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import <Cocoa/Cocoa.h>
#import "FrameworkVersion.h"
#import "SBElementServer.h"

int main(int argc, const char *argv[])
{
	frameworkInit(1);
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if (getSonicBirthFrameworkVersion() != kCurrentVersion)
	{
		NSRunAlertPanel(@"SonicBirth",
				@"The framework version does not match the application version. "
				@"Please update both of them.",
				nil, nil, nil);

		return 2;
	}
	
	// create the server
	[[SBElementServer alloc] init];
	
	// gElementServer
	NSArray *elements = [gElementServer rawElements];
	int c = [elements count];
	
	/*int j;
	for (j = 0; j < c; j++)
	{
		SBElement *e = [elements objectAtIndex:j];
		printf("%s == %s\n", [[[e class] name] cString], [[[e className] stringByAppendingPathExtension:@"png"] cString]);
	}
	
	return 0;*/
	
	printf("%%================================\n");
	printf("<p><b>%i</b> elements, with more to come!</p>\n", c);
	
	printf("%%================================\n");
	int i, cat = kCategoryCount;
	int first = 1;
	for (i = 0; i < cat; i++)
	{
		int headerDone = 0;
		int j;
		
		for (j = 0; j < c; j++)
		{
			SBElement *e = [elements objectAtIndex:j];
			if ([e category] == i)
			{
				if (!headerDone)
				{
					if (!first) printf("</ul>");
					printf("<p><b>%s</b></p><ul>\n", [[SBElement nameForCategory:i] cString]);
					headerDone = 1;
					first = 0;
				}
				
				printf("<li><p><em>%s</em>:\n", [[[e class] name] cString]);
				
				NSMutableString *infos = [NSMutableString stringWithCapacity:200];
				//[infos appendString:@"<p>"];
				[infos appendString:[e informations]];
				//[infos appendString:@"</p>"];
				
				int inputs = [e numberOfInputs];
				int outputs = [e numberOfOutputs];
				int k;
				
				if (inputs)
				{
					[infos appendString:@"\n<br>\nInputs : "];
					[infos appendString:[e nameOfInputAtIndex:0]];
					for (k = 1; k < inputs; k++)
					{
						[infos appendString:@", "];
						[infos appendString:[e nameOfInputAtIndex:k]];
					}
					[infos appendString:@"."];
				}
				
				if (outputs)
				{
					[infos appendString:@"\n<br>\nOutputs : "];
					[infos appendString:[e nameOfOutputAtIndex:0]];
					for (k = 1; k < outputs; k++)
					{
						[infos appendString:@", "];
						[infos appendString:[e nameOfOutputAtIndex:k]];
					}
					[infos appendString:@"."];
				}
				
				[infos appendString:@"</p></li>\n\n"];
				
				/*
				[infos replaceOccurrencesOfString:@"\\"
							withString:@"\\\\"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];
				
				[infos replaceOccurrencesOfString:@"_"
							withString:@"\\_"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];
				
				[infos replaceOccurrencesOfString:@"^"
							withString:@"\\^"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];
							
				[infos replaceOccurrencesOfString:@"&"
							withString:@"\\&"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];
							
				[infos replaceOccurrencesOfString:@"%"
							withString:@"\\%"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];
				*/

				printf("%s", [infos cString]);
			}
		}
	}
	printf("</ul>\n\n\n");
	
	printf("%%================================\n");
	printf("%%%i elements\n", c);
	printf("\\newpage\n");
	printf("\\section{List of elements}\n");
	for (i = 0; i < cat; i++)
	{
		int headerDone = 0;
		int j;
		
		for (j = 0; j < c; j++)
		{
			SBElement *e = [elements objectAtIndex:j];
			if ([e category] == i)
			{
				if (!headerDone)
				{
					printf("\\subsection{%s}\n", [[SBElement nameForCategory:i] cString]);
					headerDone = 1;
				}
				
				printf("\\subsubsection{%s}\n", [[[e class] name] cString]);
				
				NSMutableString *infos = [NSMutableString stringWithCapacity:200];
				[infos appendString:[e informations]];
				
				int inputs = [e numberOfInputs];
				int outputs = [e numberOfOutputs];
				int k;
				
				if (inputs)
				{
					[infos appendString:@"\n\nInputs : "];
					[infos appendString:[e nameOfInputAtIndex:0]];
					for (k = 1; k < inputs; k++)
					{
						[infos appendString:@", "];
						[infos appendString:[e nameOfInputAtIndex:k]];
					}
					[infos appendString:@"."];
				}
				
				if (outputs)
				{
					[infos appendString:@"\n\nOutputs : "];
					[infos appendString:[e nameOfOutputAtIndex:0]];
					for (k = 1; k < outputs; k++)
					{
						[infos appendString:@", "];
						[infos appendString:[e nameOfOutputAtIndex:k]];
					}
					[infos appendString:@"."];
				}
				
				[infos appendString:@"\n\n"];
				
				
				[infos replaceOccurrencesOfString:@"\\"
							withString:@"\\\\"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];
				
				[infos replaceOccurrencesOfString:@"_"
							withString:@"\\_"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];
				
				[infos replaceOccurrencesOfString:@"^"
							withString:@"\\^"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];
							
				[infos replaceOccurrencesOfString:@"&"
							withString:@"\\&"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];
							
				[infos replaceOccurrencesOfString:@"%"
							withString:@"\\%"
							options:NSLiteralSearch
							range:NSMakeRange(0, [infos length])];

				printf("%s", [infos cString]);
			}
		}
	}
	
	[pool release];
    return 0;
}



