/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"
#import "SBWire.h"
#import "SBArgument.h"
#import "SBMidiArgument.h"
#import "SBPreset.h"

@class SBSelectionList;

extern NSString *kSBCircuitDidChangeMinSizeNotification;
extern NSString *kSBCircuitDidChangeNameNotification;
extern NSString *kSBCircuitDidChangeArgumentCountNotification;

typedef struct
{
	SBElement	*inputElement;
	SBElement	*outputElement;
	int			inputIndex;
	int			outputIndex;
} WireBufferUpdate;

@interface SBCircuit : SBElement
{
@public
	// secur
	int				mNumberOfOutputs;
	unsigned int	mCurPos;
	SBBuffer		mRealOutputBuffers[kMaxChannels];
	
	SBConnectionType mInputTypes[kMaxChannels];
	SBConnectionType mOutputTypes[kMaxChannels];

	NSMutableArray  *mWireArray;
	NSMutableArray  *mArgumentArray;
	NSMutableArray  *mMidiArgumentArray;
	NSMutableArray  *mElementArray;
	NSMutableString *mInformations;
	NSMutableString *mName;
	
	BOOL			mActsAsCircuit;
	
	NSColor			*mColorBack;
	NSColor			*mColorContour;
	NSColor			*mColorFront;

	// compilation stuff
	BOOL			mIsCompiled;
	BOOL			mHasFeedback;
	BOOL			mConstantRefresh;
	BOOL			mSharingArguments;
	NSMutableArray  *mCompiledArray;
	NSMutableArray  *mFeedbackArray;
	SBBuffer		mSilence;
	
	// compilation caches
	int mCachedCompiledArrayCount;
	int mCachedWireBufferUpdateCount;
	SBElement			**mCachedCompiledArray;
	WireBufferUpdate	*mCachedWireBufferUpdate;
	
	// gui stuff
	SBSelectionList	*mSelectedList;
	
	SBWire			*mCreatingWire;
	SBWire			*mSelectedWire;
	NSSize			mCircuitSize, mCircuitMinSize;
	float			mInputChannelNameWidth;
	float			mOutputChannelNameWidth;
	
	BOOL			mMovedElement;
	BOOL			mCanChangeNumberOfInputsOutputs;
	BOOL			mCanChangeInputsOutputsTypes;
	
	BOOL			mWiresBehind;
	
	BOOL			mLoadingData;
	
	// settings view
	IBOutlet NSView			*mSettingsView;
	
	IBOutlet NSTextField	*mNameTF;
	IBOutlet NSTextField	*mCommentsTF;
	
	IBOutlet NSTextField	*mWidthTF;
	IBOutlet NSTextField	*mHeightTF;
	
	IBOutlet NSTextField	*mNumberOfInputTF;
	IBOutlet NSTextField	*mNumberOfOutputTF;
	
	IBOutlet NSTableView	*mInoutTable;
	
	IBOutlet NSButton		*mWiresBehindButton;
	
@public
	SBBuffer			pOutputBuffers[kMaxChannels];
}

- (void) selectRect:(NSRect)rect;
- (void) selectAll;
- (void) clearState;
- (BOOL) creatingWire;
- (SBWire*) selectedWire;

- (void) setCanChangeNumberOfInputsOutputs:(BOOL)can;
- (void) setCanChangeInputsOutputsTypes:(BOOL)can;

- (void) didChangeMinSize;
- (void) controlTextDidEndEditing:(NSNotification *)aNotification;

- (void) setName:(NSString*)name;
- (void) setInformations:(NSString*)informations;

- (void) compileForElement:(SBElement*)e;
- (void) compile;

- (void) setNumberOfInputs:(int)count;
- (void) setNumberOfOutputs:(int)count;

- (void) shareArgumentsFrom:(SBCircuit*)circuit shareCount:(int)shareCount;

- (int) numberOfArguments;
- (SBArgument*) argumentAtIndex:(int)idx;

- (int) numberOfMidiArguments;
- (SBMidiArgument*) midiArgumentAtIndex:(int)idx;

- (int) numberOfWires;
- (SBWire*) wireAtIndex:(int)idx;
- (SBWire*) wireForInputElement:(SBElement*)e inputIndex:(int)idx;

- (int) numberOfElements;
- (SBElement*) elementAtIndex:(int)idx;

- (BOOL) isCircular;
- (BOOL) checkCircularForElement:(SBElement*)e pastElements:(NSMutableArray*)past;

- (SBBuffer) intOutputAtIndex:(int)idx;

// add/remove element/wire
- (void) addElement:(SBElement*)element;
- (void) removeElement:(SBElement*)element;

- (void) addWire:(SBWire*)wire;
- (void) removeWire:(SBWire*)wire;

// gui stuff
- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount flags:(unsigned int)flags;

- (void) setActsAsCircuit:(BOOL)a;
- (SBElement*) selectedElement;
- (NSArray*) selectedElements;
- (NSArray*) selectedWires;
- (void) deselect;
- (NSSize) circuitSize;
- (NSSize) circuitMinSize;
- (void) setCircuitSize:(NSSize)s;
- (void) setCircuitMinSize:(NSSize)s;
- (void) drawInputsOutputs:(NSRect)rect;

- (int) inputNameForX:(int)x Y:(int)y;
- (int) outputNameForX:(int)x Y:(int)y;

- (void) changeInputName:(int)idx newName:(NSString*)newName;
- (void) changeOutputName:(int)idx newName:(NSString*)newName;

- (void) changeInputType:(int)idx newType:(SBConnectionType)type;
- (void) changeOutputType:(int)idx newType:(SBConnectionType)type;

- (void) unsuperposeElements;

- (void) subElementWillChangeAudio:(NSNotification *)notification;
- (void) subElementDidChangeAudio:(NSNotification *)notification;
- (void) subElementDidChangeView:(NSNotification *)notification;
- (void) subElementDidChangeGlobalView:(NSNotification *)notification;
- (void) subElementDidChangeConnections:(NSNotification *)notification;
- (void) subElementDidChangePrecision:(NSNotification *)notification;
- (void) subElementDidChangeInterpolation:(NSNotification *)notification;

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

- (IBAction) changedWiresBehind:(id)sender;

- (SBSelectionList *)selectionList;

@end
