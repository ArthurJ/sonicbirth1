/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBExportServer.h"

#import "SBCircuitDocument.h"
#import "SBRootCircuit.h"
#import "FrameworkVersion.h"

#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>

static int patchMemory(unsigned char *buf, int size, SBPassedData *passedData)
{
	if (!buf || size <= 0 || !passedData) return 0;
	
	const char *magicKey = "sonicfillbuffer ";
	int patchedCount = 0;
	
	int c = 0, beg = -1, i = 0;
	while (i < size)
	{
		if (size - i > 16)
		{
			if (memcmp(buf + i, magicKey, 16) == 0)
			{
				if (c == 0)
					beg = i;
					
				c++;
				i += 16;
				
				if (c == 64)
				{
					memcpy(buf + beg, passedData, sizeof(*passedData));
					c = 0;
					patchedCount++;
				}
			}
			else
			{
				c = 0;
				i++;
			}
		}
		else
			break;
	}
	
	return patchedCount;
}

@implementation SBExportServer

#define FAILURE(args...) NSRunAlertPanel(@"Export failure", [NSString stringWithFormat:args], nil, nil, nil)
#define SUCCESS(args...) NSRunAlertPanel(@"Export success", [NSString stringWithFormat:args], nil, nil, nil)

- (IBAction) installAsVST:(id)sender
{
	[self install:NO];
}

- (IBAction) batchExportToVSTs:(id)sender
{
	[self batchExport:NO];
}

- (IBAction) exportToVST:(id)sender
{
	[self export:NO];
}

- (IBAction) installAsAU:(id)sender
{
	[self install:YES];
}

- (IBAction) batchExportToAUs:(id)sender
{
	[self batchExport:YES];
}

- (IBAction) exportToAU:(id)sender
{
	[self export:YES];
}

- (void) install:(BOOL)toAU
{
	NSDocumentController *dc = [NSDocumentController sharedDocumentController];
	NSDocument *cur = [dc currentDocument];
	if (!cur) return;
	if (![cur isKindOfClass:[SBCircuitDocument class]]) return;
		
	SBCircuitDocument *cdoc = (SBCircuitDocument *)cur;
	SBRootCircuit *circuit = [cdoc circuit];
	
	NSString *fileName;
	if (toAU) fileName = @"~/Library/Audio/Plug-Ins/Components";
	else fileName = @"~/Library/Audio/Plug-Ins/VST";
	
	fileName = [fileName stringByExpandingTildeInPath];
	
	NSString *path;
	if (toAU) path = [[fileName stringByAppendingPathComponent:[circuit name]] stringByAppendingPathExtension:@"component"];
	else path = [[fileName stringByAppendingPathComponent:[circuit name]] stringByAppendingPathExtension:@"vst"];
	
	
	// check if file exists
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:path])
	{
		int result = NSRunAlertPanel(@"Overwrite?",
								[NSString stringWithFormat:@"File already exists at %@. Do you wish to overwrite ?", path],
								@"Overwrite", @"Cancel", nil);
		if (result == NSAlertAlternateReturn) return;
		[fm removeFileAtPath:path handler:nil]; // ignore error
	}
	
	BOOL suceeds;
	if (toAU) suceeds = [self exportCircuitAsAU:circuit toPath:fileName];
	else suceeds = [self exportCircuitAsVST:circuit toPath:fileName];
	if (suceeds)
	{
		SUCCESS(@"Export successful!");
	}
	
}

- (void) export:(BOOL)toAU
{
	NSDocumentController *dc = [NSDocumentController sharedDocumentController];
	NSDocument *cur = [dc currentDocument];
	if (!cur) return;
	if (![cur isKindOfClass:[SBCircuitDocument class]]) return;
		
	SBCircuitDocument *cdoc = (SBCircuitDocument *)cur;
	SBRootCircuit *circuit = [cdoc circuit];

	NSOpenPanel *panel = [NSOpenPanel openPanel];
	int result;
	[panel setAccessoryView:mCustomView];
	[panel setCanChooseFiles:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:YES];
	[panel setTitle:@"Choose destination directory"];
	
	result = [panel runModal];
	if (result != NSOKButton) return;
	
	NSString *path;
	if (toAU) path = [[[panel filename] stringByAppendingPathComponent:[circuit name]] stringByAppendingPathExtension:@"component"];
	else path = [[[panel filename] stringByAppendingPathComponent:[circuit name]] stringByAppendingPathExtension:@"vst"];
	
	// check if file exists
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:path])
	{
		result = NSRunAlertPanel(@"Overwrite?",
								[NSString stringWithFormat:@"File already exists at %@. Do you wish to overwrite ?", path],
								@"Overwrite", @"Cancel", nil);
		if (result == NSAlertAlternateReturn) return;
		[fm removeFileAtPath:path handler:nil]; // ignore error
	}
	
	BOOL suceeds;
	if (toAU) suceeds = [self exportCircuitAsAU:circuit toPath:[panel filename]];
	else suceeds = [self exportCircuitAsVST:circuit toPath:[panel filename]];
	if (suceeds)
	{
		SUCCESS(@"Export successful!");
	}
}

- (void) batchExport:(BOOL)toAU
{
	int result;

	// get the source folder
	NSOpenPanel *opanel = [NSOpenPanel openPanel];
	[opanel setCanChooseDirectories:YES];
	[opanel setCanChooseFiles:NO];
	[opanel setAllowsMultipleSelection:NO];
	[opanel setTitle:@"Choose source directory"];
	
	result = [opanel runModal];
	if (result != NSOKButton) return;
	
	NSString *folder = [opanel filename];
	
	// now ask for a destination
	NSSavePanel *spanel = [NSSavePanel savePanel];
	[spanel setAccessoryView:mCustomView];
	[spanel setRequiredFileType:@""];
	[spanel setTitle:@"Create destination directory"];
	result = [spanel runModal];
			
	if (result != NSOKButton) return;
	NSString *path = [spanel filename];

	[self batchExportFrom:folder to:path toAU:toAU];
}

	
- (void) batchExportFrom:(NSString*)from to:(NSString*)to toAU:(BOOL)toAU
{
	// prepare output directory
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeFileAtPath:to handler:nil]; // ignore error
	BOOL ok = [fm createDirectoryAtPath:to attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", to);
		return;
	}

	int good = 0, bad = 0;
	[self exportCircuitsFromFolder:from toPath:to goodCount:&good badCount:&bad toAU:toAU];
	if (good == 0 && bad == 0)
	{
		FAILURE(@"Could not find anything to export!");
	}
	else if (good == 0)
	{
		FAILURE(@"%i plugins could not be exported due to errors.", bad);
	}
	else if (bad == 0)
	{
		SUCCESS(@"All %i plugins have been exported.", good);
	}
	else
	{
		FAILURE(@"%i plugins could not be exported due to errors. %i have been exported successfully.", bad, good);
	}
}

- (void) exportFrom:(NSString*)from to:(NSString*)to toAU:(BOOL)toAU
{
	NSData *data = [NSData dataWithContentsOfFile:from];
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
			SBRootCircuit *c = [[SBRootCircuit alloc] init];
			if (c)
			{			
				if ([c loadData:d])
					[self exportCircuit:c to:to toAU:toAU];
					
				[c release];
			}
		}
		else
		{
			NSLog(@"Error while deserializing: %@", error);
			// [error release];
		}
	}
}


- (void) exportCircuit:(SBRootCircuit*)circuit to:(NSString*)to toAU:(BOOL)toAU
{
	// prepare output directory
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeFileAtPath:to handler:nil]; // ignore error
	BOOL ok = [fm createDirectoryAtPath:to attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", to);
		return;
	}

	BOOL suceeds;
	if (toAU) suceeds = [self exportCircuitAsAU:circuit toPath:to];
	else suceeds = [self exportCircuitAsVST:circuit toPath:to];

	if (suceeds)
	{
		SUCCESS(@"Export successful!");
	}
}

- (void) exportCircuitsFromFolder:(NSString*)folder toPath:(NSString*)path goodCount:(int*)good badCount:(int*)bad toAU:(BOOL)toAU
{
	//NSLog(@"exportCircuitsFromFolder: %@", folder);
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSArray *files = [fm directoryContentsAtPath:folder];
	if (!files) return;
	
	int c = [files count], i;
	for (i = 0; i < c; i++)
	{
		NSString *file = [files objectAtIndex:i];
		file = [folder stringByAppendingPathComponent:file];
		
		BOOL isDir;
		BOOL exists = [fm fileExistsAtPath:file isDirectory:&isDir];
		if (!exists) continue;
		
		//NSLog(@"file: %@ exists: %i isDir: %i", file, exists, isDir);
		if (isDir)
			[self exportCircuitsFromFolder:file toPath:path goodCount:good badCount:bad toAU:toAU];
		else if ([[file pathExtension] isEqual:@"sbc"])
		{
			//NSLog(@"testing %@", file);
			
			NSData *data = [NSData dataWithContentsOfFile:file];
			if (data)
			{
				//NSLog(@"got data");
				
				NSString *error = nil;
				NSDictionary *d = [NSPropertyListSerialization
								   propertyListFromData:data
								   mutabilityOption:NSPropertyListImmutable
								   format:nil
								   errorDescription:&error];
				if (d && !error)
				{
					SBRootCircuit *cct = [[SBRootCircuit alloc] init];
					if (!cct) continue;
					
					if (![cct loadData:d])
					{
						[cct release];
						continue;
					}
					
					BOOL suceeds;
					if (toAU) suceeds = [self exportCircuitAsAU:cct toPath:path];
					else suceeds = [self exportCircuitAsVST:cct toPath:path];
					
					if (suceeds)
						(*good)++;
					else
						(*bad)++;
					
					[cct release];
				}
				else
				{
					NSLog(@"Error while deserializing: %@", error);
					// [error release];
				}
			}
		}
	}
}
	
- (BOOL) exportCircuitAsVST:(SBRootCircuit*)circuit toPath:(NSString*)path
{
	BOOL doEncrypt = (mEncrypt) ? ([mEncrypt state] == NSOnState) : NO;
	int i;
	
	if ([circuit numberOfOutputs] < 1)
	{
		FAILURE(@"Error: Circuit must have at least 1 output!");
		return NO;
	}

	NSString *name = [circuit name];

	NSFileManager *fm = [NSFileManager defaultManager];

	NSString *componentDir = [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"vst"];
	BOOL ok = [fm createDirectoryAtPath:componentDir attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", componentDir);
		return NO;
	}
	
	NSString *contentsDir = [componentDir stringByAppendingPathComponent:@"Contents"];
	ok = [fm createDirectoryAtPath:contentsDir attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", contentsDir);
		return NO;
	}
	
	NSString *macosDir = [contentsDir stringByAppendingPathComponent:@"MacOS"];
	ok = [fm createDirectoryAtPath:macosDir attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", macosDir);
		return NO;
	}
	
	NSString *resDir = [contentsDir stringByAppendingPathComponent:@"Resources"];
	ok = [fm createDirectoryAtPath:resDir attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", resDir);
		return NO;
	}

	// create the pkginfo
	NSString *pkginfo = @"BNDLScBh";
	NSString *pkginfoPath = [contentsDir stringByAppendingPathComponent:@"PkgInfo"];
	ok = [pkginfo writeToFile:pkginfoPath atomically:NO];
	if (!ok)
	{
		FAILURE(@"Error: Can't write at %@!", pkginfoPath);
		return NO;
	}

	// now create plist
	NSString *identifier = [@"com.sonicbirth.vst." stringByAppendingString:name];
	NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
	[md setObject:@"English" forKey:@"CFBundleDevelopmentRegion"];
	[md setObject:name forKey:@"CFBundleExecutable"];
	[md setObject:@"SonicBirth version 1.3.5, Copyright 2004-2007 Antoine Missout." forKey:@"CFBundleGetInfoString"];
	[md setObject:identifier forKey:@"CFBundleIdentifier"];
	[md setObject:@"6.0" forKey:@"CFBundleInfoDictionaryVersion"];
	[md setObject:@"BNDL" forKey:@"CFBundlePackageType"];
	[md setObject:@"1.3.5" forKey:@"CFBundleShortVersionString"];
	[md setObject:@"ScBh" forKey:@"CFBundleSignature"];
	[md setObject:@"1.3.5" forKey:@"CFBundleVersion"];
	[md setObject:@"plugin" forKey:@"CFBundleIconFile"];

	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization
						dataFromPropertyList:md
						format:NSPropertyListXMLFormat_v1_0
						errorDescription:&error];
		
	if (!data || error)
	{
		FAILURE(@"Error while serializing: %@", error);
		// [error release];
		return NO;
	}
	
	NSString *plistPath = [contentsDir stringByAppendingPathComponent:@"Info.plist"];
	ok = [data writeToFile:plistPath atomically:NO];
	if (!ok)
	{
		FAILURE(@"Couldn't write to %@!", plistPath);
		return NO;
	}

	// create mach-o
	NSDictionary *d = [circuit saveData];
	if (!d)
	{
		FAILURE(@"No save data for circuit!");
		return NO;
	}
	
	data = [NSPropertyListSerialization
				dataFromPropertyList:d
				format:NSPropertyListXMLFormat_v1_0
				errorDescription:&error];				
	if (!data || error)
	{
		FAILURE(@"Error while serializing: %@", error);
		// [error release];
		return NO;
	}
	
	SBPassedData passedData;
	unsigned char *bytes = (unsigned char *)&passedData;
	for (i = 0; i < sizeof(passedData); i++)
		*bytes++ = random();
		
	if (!doEncrypt)
		memset(&(passedData.xorKey), 0, kFillBufferXORKeySize);
		
	if (doEncrypt)
	{
		NSMutableData *mdata = [NSMutableData dataWithData:data];
		unsigned char *mb = [mdata mutableBytes];
		int l = [mdata length];
		for (i = 0; i <l; i++)
			*mb++ ^= passedData.xorKey[i % kFillBufferXORKeySize];
		data = mdata;
	}
	
	// copy model
	NSString *modelPath = [resDir stringByAppendingPathComponent:@"model.sbc"];
	ok = [data writeToFile:modelPath atomically:NO];
	if (!ok)
	{
		FAILURE(@"Error: Can't write at %@!", modelPath);
		return NO;
	}
	
	// copy icns
	NSString *dstIconPath = [resDir stringByAppendingPathComponent:@"plugin.icns"];
	NSString *srcIconPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"plugin.icns"];
	ok = [fm copyPath:srcIconPath toPath:dstIconPath handler:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't copy %@ to %@!", srcIconPath, dstIconPath);
		return NO;
	}
	
	// create the code
	NSString *genericVST = [[[NSBundle mainBundle] resourcePath]
									stringByAppendingPathComponent:@"GenericVST"];
	int fd = open([genericVST fileSystemRepresentation], O_RDONLY, 0);
	if (fd < 0)
	{
		FAILURE(@"Error while opening: %@", genericVST);
		return NO;
	}
	
	int size = lseek(fd, 0, SEEK_END);
	int iok = lseek(fd, 0, SEEK_SET);
	
	if (size == -1 || iok == -1)
	{
		close(fd);
		FAILURE(@"Error while seeking: %@", genericVST);
		return NO;
	}
	
	unsigned char *buf = (unsigned char *) malloc(size);
	if (!buf)
	{
		close(fd);
		FAILURE(@"Error while allocating memory!");
		return NO;
	}
	
	iok = read(fd, buf, size);
	if (iok != size)
	{
		free(buf);
		close(fd);
		FAILURE(@"Error while reading data from %@!", genericVST);
		return NO;
	}
	
	close(fd);

	// NSLog(@"Inserting data at: %i", beg);
	if ([identifier length] > 1000)
	{
		free(buf);
		FAILURE(@"Identifier too long (%@)!", identifier);
		return NO;
	}
		
	// put identifier
	strcpy(passedData.identifier, [identifier UTF8String]);
	
	// copy data back
	int patchCount = patchMemory(buf, size, &passedData);
	if (patchCount < 1)
	{
		FAILURE(@"Sonic MagicKey not found!");
		return NO;
	}
	
	NSString *finalVST = [macosDir stringByAppendingPathComponent:name];
	
	fd = open([finalVST fileSystemRepresentation], O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fd < 0)
	{
		FAILURE(@"Error while opening: %@", finalVST);
		return NO;
	}
	
	iok = write(fd, buf, size);
	if (iok != size)
	{
		free(buf);
		close(fd);
		FAILURE(@"Error while writing data to %@!", finalVST);
		return NO;
	}
	
	close(fd);
	
	return YES;
}

- (BOOL) exportCircuitAsAU:(SBRootCircuit*)circuit toPath:(NSString*)path
{
	BOOL doEncrypt = (mEncrypt) ? ([mEncrypt state] == NSOnState) : NO;
	int i;
	
	if ([circuit numberOfOutputs] < 1)
	{
		FAILURE(@"Error: Circuit must have at least 1 output!");
		return NO;
	}

	NSString *name = [circuit name];

	NSFileManager *fm = [NSFileManager defaultManager];

	NSString *componentDir = [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"component"];
	BOOL ok = [fm createDirectoryAtPath:componentDir attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", componentDir);
		return NO;
	}
	
	NSString *tempDir = [componentDir stringByAppendingPathComponent:@"temp"];
	ok = [fm createDirectoryAtPath:tempDir attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", tempDir);
		return NO;
	}
	
	NSString *contentsDir = [componentDir stringByAppendingPathComponent:@"Contents"];
	ok = [fm createDirectoryAtPath:contentsDir attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", contentsDir);
		return NO;
	}
	
	NSString *macosDir = [contentsDir stringByAppendingPathComponent:@"MacOS"];
	ok = [fm createDirectoryAtPath:macosDir attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", macosDir);
		return NO;
	}
	
	NSString *resDir = [contentsDir stringByAppendingPathComponent:@"Resources"];
	ok = [fm createDirectoryAtPath:resDir attributes:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't create directory at %@!", resDir);
		return NO;
	}
	
	// create the pkginfo
	NSString *pkginfo = @"BNDLScBh";
	NSString *pkginfoPath = [contentsDir stringByAppendingPathComponent:@"PkgInfo"];
	ok = [pkginfo writeToFile:pkginfoPath atomically:NO];
	if (!ok)
	{
		FAILURE(@"Error: Can't write at %@!", pkginfoPath);
		return NO;
	}

	// make the ressource
	NSString *srcResPath = [tempDir stringByAppendingPathComponent:@"res.r"];
	
	char miniBuf[5]; miniBuf[4] = 0;
	memcpy(miniBuf, [circuit subType], 4);
	//NSString *subType = [NSString stringWithCString:miniBuf];
	unsigned int *subType = (unsigned int *)miniBuf;

	NSMutableString *res = [NSMutableString stringWithCapacity:1024];
	
	//[res appendString:@"#include <AudioUnit/AudioUnit.r>\n"];
	
	NSString *company = [circuit company];
	NSString *pluginDescription = [circuit pluginDescription];
	
	if ([company length] == 0) company = @"SonicBirth";
	if ([pluginDescription length] == 0) pluginDescription = @"An audio effect exported from SonicBirth";

	// ressource for the plugin
	[res appendString:@"#define RES_ID			10000\n"];
	
	[res appendString:@"#define COMP_SUBTYPE	"];
	[res appendString:[NSString stringWithFormat:@"0x%X", *subType]];
	[res appendString:@"\n"];
	
	[res appendString:@"#define COMP_MANUF		'ScBh'\n"];
	
	[res appendString:@"#define VERSION			"];
	[res appendString:kCurrentVersionNSString];
	[res appendString:@"\n"];
	
	[res appendString:@"#define NAME			\""];
	[res appendString:company];
	[res appendString:@": "];
	[res appendString:name];
	[res appendString:@"\"\n"];
	
	[res appendString:@"#define DESCRIPTION		\""];
	[res appendString:pluginDescription];
	[res appendString:@"\"\n"];
	
	if ([circuit hasMidiArguments] || ([circuit numberOfInputs] == 0))
	{
		if ([circuit numberOfInputs] == 0)
		{
			[res appendString:@"#define COMP_TYPE		kAudioUnitType_MusicDevice\n"];
			[res appendString:@"#define ENTRY_POINT		\"SonicBirthRuntimeMusicDevicePluginEntry\"\n"];
		}
		else
		{
			[res appendString:@"#define COMP_TYPE		kAudioUnitType_MusicEffect\n"];
			[res appendString:@"#define ENTRY_POINT		\"SonicBirthRuntimeMidiEffectPluginEntry\"\n"];
		}
	}
	else
	{
		[res appendString:@"#define COMP_TYPE		kAudioUnitType_Effect\n"];
		[res appendString:@"#define ENTRY_POINT		\"SonicBirthRuntimeEffectPluginEntry\"\n"];
	}
	
	[res appendString:@"#include \"ExportResources.r\"\n"];
	
	// ressource for the plugin view
	if ([circuit hasCustomGui])
	{
		[res appendString:@"#define RES_ID			12000\n"];
		
		[res appendString:@"#define COMP_SUBTYPE	"];
		[res appendString:[NSString stringWithFormat:@"0x%X", *subType]];
		[res appendString:@"\n"];
		
		[res appendString:@"#define COMP_MANUF		'ScBh'\n"];
		
		[res appendString:@"#define VERSION			"];
		[res appendString:kCurrentVersionNSString];
		[res appendString:@"\n"];
		
		[res appendString:@"#define NAME			\""];
		[res appendString:company];
		[res appendString:@": "];
		[res appendString:name];
		[res appendString:@"\"\n"];
		
		[res appendString:@"#define DESCRIPTION		\""];
		[res appendString:pluginDescription];
		[res appendString:@"\"\n"];
		
		[res appendString:@"#define COMP_TYPE		kAudioUnitCarbonViewComponentType\n"];
		[res appendString:@"#define ENTRY_POINT		\"SonicBirthRuntimeCarbonViewEntry\"\n"];
		
		[res appendString:@"#include \"ExportResources.r\"\n"];
	}
	
	//NSLog(@"res:\n%@",res);
	
	ok = [res writeToFile:srcResPath atomically:NO];
	if (!ok)
	{
		FAILURE(@"Error: Can't write at %@!", srcResPath);
		return NO;
	}
	
	// compile .rsrc
	NSString *dstResPath = [[resDir stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"rsrc"];
	NSTask *task = [NSTask	launchedTaskWithLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Rez"]
							arguments:[NSArray arrayWithObjects:
	
		@"-d", @"SystemSevenOrLater=1",
		@"-useDF",
		@"-script", @"Roman",
		@"-arch", @"i386",
		@"-arch", @"x86_64",
		@"-i", [[NSBundle mainBundle] resourcePath],
		
		@"-o", dstResPath,
		srcResPath,
		
		nil]];
	if (!task)
	{
		FAILURE(@"Can't create task!");
		return NO;
	}
	
	[task waitUntilExit];
	
	int status = [task terminationStatus];
	if (status != 0)
	{
		FAILURE(@"Rez error: %i", status);
		return NO;
	}
		
	// now create plist
	NSString *identifier = [@"com.sonicbirth.audiounits." stringByAppendingString:name];
	NSMutableDictionary *md = [NSMutableDictionary dictionaryWithCapacity:10];
	[md setObject:@"English" forKey:@"CFBundleDevelopmentRegion"];
	[md setObject:name forKey:@"CFBundleExecutable"];
	[md setObject:@"SonicBirth version 1.3.5, Copyright 2004-2007 Antoine Missout." forKey:@"CFBundleGetInfoString"];
	[md setObject:identifier forKey:@"CFBundleIdentifier"];
	[md setObject:@"6.0" forKey:@"CFBundleInfoDictionaryVersion"];
	[md setObject:@"BNDL" forKey:@"CFBundlePackageType"];
	[md setObject:@"1.3.5" forKey:@"CFBundleShortVersionString"];
	[md setObject:@"ScBh" forKey:@"CFBundleSignature"];
	[md setObject:@"1.3.5" forKey:@"CFBundleVersion"];
	[md setObject:@"plugin" forKey:@"CFBundleIconFile"];

	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization
						dataFromPropertyList:md
						format:NSPropertyListXMLFormat_v1_0
						errorDescription:&error];

	if (!data || error)
	{
		FAILURE(@"Error while serializing: %@", error);
		// [error release];
		return NO;
	}
	
	NSString *plistPath = [contentsDir stringByAppendingPathComponent:@"Info.plist"];
	ok = [data writeToFile:plistPath atomically:NO];
	if (!ok)
	{
		FAILURE(@"Couldn't write to %@!", plistPath);
		return NO;
	}

	// create mach-o
	NSDictionary *d = [circuit saveData];
	if (!d)
	{
		FAILURE(@"No save data for circuit!");
		return NO;
	}
	
	data = [NSPropertyListSerialization
				dataFromPropertyList:d
				format:NSPropertyListXMLFormat_v1_0
				errorDescription:&error];				
	if (!data || error)
	{
		FAILURE(@"Error while serializing: %@", error);
		// [error release];
		return NO;
	}
	
	SBPassedData passedData;
	unsigned char *bytes = (unsigned char *)&passedData;
	for (i = 0; i < sizeof(passedData); i++)
		*bytes++ = random();
		
	if (!doEncrypt)
		memset(&(passedData.xorKey), 0, kFillBufferXORKeySize);
		
	if (doEncrypt)
	{
		NSMutableData *mdata = [NSMutableData dataWithData:data];
		unsigned char *mb = [mdata mutableBytes];
		int l = [mdata length];
		for (i = 0; i <l; i++)
			*mb++ ^= passedData.xorKey[i % kFillBufferXORKeySize];
		data = mdata;
	}
	
	// copy model
	NSString *modelPath = [resDir stringByAppendingPathComponent:@"model.sbc"];
	ok = [data writeToFile:modelPath atomically:NO];
	if (!ok)
	{
		FAILURE(@"Error: Can't write at %@!", modelPath);
		return NO;
	}
	
	// copy icns
	NSString *dstIconPath = [resDir stringByAppendingPathComponent:@"plugin.icns"];
	NSString *srcIconPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"plugin.icns"];
	ok = [fm copyPath:srcIconPath toPath:dstIconPath handler:nil];
	if (!ok)
	{
		FAILURE(@"Error: Can't copy %@ to %@!", srcIconPath, dstIconPath);
		return NO;
	}
	
	// create the code
	NSString *genericAU = [[[NSBundle mainBundle] resourcePath]
									stringByAppendingPathComponent:@"GenericAU"];
	int fd = open([genericAU fileSystemRepresentation], O_RDONLY, 0);
	if (fd < 0)
	{
		FAILURE(@"Error while opening: %@", genericAU);
		return NO;
	}
	
	int size = lseek(fd, 0, SEEK_END);
	int iok = lseek(fd, 0, SEEK_SET);
	
	if (size == -1 || iok == -1)
	{
		close(fd);
		FAILURE(@"Error while seeking: %@", genericAU);
		return NO;
	}
	
	unsigned char *buf = (unsigned char *) malloc(size);
	if (!buf)
	{
		close(fd);
		FAILURE(@"Error while allocating memory!");
		return NO;
	}
	
	iok = read(fd, buf, size);
	if (iok != size)
	{
		free(buf);
		close(fd);
		FAILURE(@"Error while reading data from %@!", genericAU);
		return NO;
	}
	
	close(fd);
	
	// NSLog(@"Inserting data at: %i", beg);
	if ([identifier length] > 1000)
	{
		free(buf);
		FAILURE(@"Identifier too long (%@)!", identifier);
		return NO;
	}
	
	// put identifier
	strcpy(passedData.identifier, [identifier UTF8String]);
	
	// copy data back
	int patchCount = patchMemory(buf, size, &passedData);
	if (patchCount < 1)
	{
		FAILURE(@"Sonic MagicKey not found!");
		return NO;
	}
	
	NSString *finalAU = [macosDir stringByAppendingPathComponent:name];
	
	fd = open([finalAU fileSystemRepresentation], O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fd < 0)
	{
		FAILURE(@"Error while opening: %@", finalAU);
		return NO;
	}
	
	iok = write(fd, buf, size);
	if (iok != size)
	{
		free(buf);
		close(fd);
		FAILURE(@"Error while writing data to %@!", finalAU);
		return NO;
	}
	
	close(fd);
	
	ok = [fm removeFileAtPath:tempDir handler:nil];
	if (!ok)
	{
		FAILURE(@"Could not erase temp dir!");
		return NO;
	}
	
	return YES;
}

#undef FAILURE
#undef SUCCESS

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if (menuItem == mBatchExport) return YES;
	if (menuItem == mBatchExportVST) return YES;
	
	NSDocumentController *dc = [NSDocumentController sharedDocumentController];
	NSDocument *cur = [dc currentDocument];
	if (cur && [cur isKindOfClass:[SBCircuitDocument class]])
		return YES;
		
	return NO;
}

@end

