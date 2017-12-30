/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCircuitDocument.h"
#import "SBSoundServer.h"

@implementation SBCircuitDocument

- (id)init
{
	self = [super init];
	if (self)
	{
		mCircuit = [[SBRootCircuit alloc] init];
		if (!mCircuit)
		{
			[self release];
			return nil;
		}
		mUndoData = nil;
	}
	return self;
}

- (void) dealloc
{
	if ([gSoundServer currentAudioProcess] == mCircuit)
		[gSoundServer stop];
	if (mCircuit) [mCircuit release];
	[super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"SBCircuitDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	[super windowControllerDidLoadNib:aController];
	[mCircuitView setParent:self];
	[mCircuitView setRootCircuit:mCircuit];
	
	[[self undoManager] setLevelsOfUndo:10];
}

- (void) undoMark
{
	[self snapShot];
	[self snapShotMark];
}

- (void) undoApply:(NSData*)data
{
	if (!data) return;

	[self undoMark];
	
	NSString *error = nil;
	NSDictionary *d = [NSPropertyListSerialization
						propertyListFromData:data
						mutabilityOption:NSPropertyListImmutable
						format:nil
						errorDescription:&error];
	if (d && !error)
	{
		[mCircuit willChangeAudio];
			[mCircuit clearState];
		[mCircuit didChangeAudio];
	
		[mCircuit loadData:d];
		if (mCircuitView) [mCircuitView reselect];
	}
	else
	{
		NSLog(@"Error while deserializing: %@", error);
		// [error release];
	}
}

- (void) snapShot
{

	if (mUndoData) { [mUndoData release]; mUndoData = nil; }

	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization
						dataFromPropertyList:[mCircuit saveData]
						format:NSPropertyListXMLFormat_v1_0
						errorDescription:&error];
						
	if (data && !error)
	{
		[data retain];
		mUndoData = data;
	}
	else
	{
		NSLog(@"Error while serializing: %@", error);
		// [error release];
	}
}

- (void) snapShotMark
{
	if (!mUndoData) return;
	[[self undoManager] registerUndoWithTarget:self
						selector:@selector(undoApply:)
						object:mUndoData];
	[mUndoData release];
	mUndoData = nil;
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType
{
	NSDictionary *d = [mCircuit saveData];
	if (!d) return NO;
	
	NSString *error = nil;
	NSData *data = [NSPropertyListSerialization
						dataFromPropertyList:d
						format:NSPropertyListXMLFormat_v1_0
						errorDescription:&error];
		
	if (data && !error)
	{
		BOOL ok = [data writeToFile:fileName atomically:YES];
		if (ok) mWriteSuccess = YES;
		return ok;
	}
	else
	{
		NSLog(@"Error while serializing: %@", error);
		// [error release];
	}
	return NO;
}

- (IBAction)saveDocumentAs:(id)sender
{
	if ([[self fileType] isEqual:@"circuit"])
	{
		[super saveDocumentAs:sender];
		return;
	}
	mWriteSuccess = NO;
	[self setFileType:@"circuit"];
	
	[super saveDocumentAs:sender];
	
	if (!mWriteSuccess)
		[self setFileType:@"plugin"];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
	NSData *data;
	
	if ([docType isEqual:@"plugin"])
	{
		data = [NSData dataWithContentsOfFile:[fileName stringByAppendingPathComponent:@"Contents/Resources/model.sbc"]];
	
		//[self setFileType:@"circuit"];
		//[self setFileName:[[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"sbc"]];
	}
	else
		data = [NSData dataWithContentsOfFile:fileName];

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
			if (!c) return NO;			
			if (![c loadData:d])
			{
				[c release];
				return NO;
			}

			[mCircuit release];
			mCircuit = c;
			
			[mCircuitView setRootCircuit:mCircuit];
			return YES;
		}
		else
		{
			NSLog(@"Error while deserializing: %@", error);
			// [error release];
		}
	}
	
	return NO;
}

- (SBRootCircuit*) circuit
{
	return mCircuit;
}

- (SBCircuitView*) circuitView
{
	return mCircuitView;
}

@end
