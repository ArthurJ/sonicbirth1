/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
@class SBRootCircuit;

@interface SBExportServer : NSObject
{
	IBOutlet NSMenuItem *mBatchExport;
	IBOutlet NSMenuItem *mBatchExportVST;
	
	IBOutlet NSView *mCustomView;
	IBOutlet NSButton *mEncrypt;
}

- (IBAction) installAsAU:(id)sender;
- (IBAction) installAsVST:(id)sender;

- (IBAction) exportToAU:(id)sender;
- (IBAction) batchExportToAUs:(id)sender;

- (IBAction) exportToVST:(id)sender;
- (IBAction) batchExportToVSTs:(id)sender;

- (void) install:(BOOL)toAU;
- (void) export:(BOOL)toAU;
- (void) batchExport:(BOOL)toAU;

- (void) exportFrom:(NSString*)from to:(NSString*)to toAU:(BOOL)toAU;
- (void) exportCircuit:(SBRootCircuit*)circuit to:(NSString*)to toAU:(BOOL)toAU;
- (void) batchExportFrom:(NSString*)from to:(NSString*)to toAU:(BOOL)toAU;

- (BOOL) exportCircuitAsAU:(SBRootCircuit*)circuit toPath:(NSString*)path;
- (BOOL) exportCircuitAsVST:(SBRootCircuit*)circuit toPath:(NSString*)path;

- (void) exportCircuitsFromFolder:(NSString*)folder toPath:(NSString*)path goodCount:(int*)good badCount:(int*)bad toAU:(BOOL)toAU;

@end
