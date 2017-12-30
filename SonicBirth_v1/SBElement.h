/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAudioProcess.h"

extern NSString *kSBElementWillChangeAudioNotification;
extern NSString *kSBElementDidChangeAudioNotification;
extern NSString *kSBElementDidChangeViewNotification;
extern NSString *kSBElementDidChangeGlobalViewNotification;
extern NSString *kSBElementDidChangeConnectionsNotification;

extern NSMutableDictionary *gTextAttributes;

extern ogColor gSelectedColor;

@class SBCircuit;
@class SBCell;

typedef enum
{
	kCommon = 0, // should only be used by element server
	
	kAlgebraic,
	kFunction,
	kTrigonometric,
	
	kArgument,
	kMidiArgument,
	kDisplay,
	
	kAnalysis,
	kComparator,
	kConverter,
	kDelay,
	kGenerator,
	kFilter,
	kFeedback,
	kDistortion,
	kAudioFile,
	kFFT,
	
	kMisc,
	kInternal, // bit precision, midi controller, interpolation mode
	
	kCategoryCount
	
} SBElementCategory;

typedef enum
{
	kNormal = 0,
	kPoints = 1,
	kAudioBuffer = 2,
	kFFTSync = 3
} SBConnectionType;

#define SET_TYPE_COLOR(type) \
	if (type == kPoints)			ogSetColorComp(217.f/255.f, 214.f/255.f, 110.f/255.f, 1.f); \
	else if (type == kAudioBuffer)	ogSetColorComp(  0.f/255.f, 255.f/255.f,  66.f/255.f, 1.f); \
	else if (type == kFFTSync)		ogSetColorComp(255.f/255.f,  46.f/255.f, 123.f/255.f, 1.f);

#define SET_TYPE_NAMES(pcell) \
	[pcell addItemWithTitle:@"Numbers"]; \
	[pcell addItemWithTitle:@"Points"]; \
	[pcell addItemWithTitle:@"Audio buffer"]; \
	[pcell addItemWithTitle:@"FFT Sync."];

#define kTextHeight (12)
#define kSocketWidth (10)
#define kNameSpace (10)
#define kContentSpace (4)

@interface SBElement : SBAudioProcess
{
@public
	NSMutableArray  *mInputNames;
	NSMutableArray  *mOutputNames;
	
	NSMutableArray  *mOutputBuffers;
	int				mSampleRate;
	int				mSampleCount;
	SBPrecision		mPrecision;
	SBInterpolation mInterpolation;
	
	// buffers
	int				mAudioBuffersCount;
	SBBuffer		mAudioBuffers[kMaxChannels];
	
	// gui stuff
	BOOL			mMiniMode;
	BOOL			mCalculatedFrame;
	NSRect			mFrame, mContentFrame;
	NSPoint			mGuiOrigin, mDesignOrigin;
	float			mInputNameWidth;
	float			mElementNameWidth;
	float			mOutputNameWidth;
	NSImage			*mImage;
	BOOL			mIsSelected;
	SBGuiMode		mGuiMode;
	
	SBCell			*mCell;
	
	BOOL			mLastCircuit;
	
@public
	SBCalculateFuncPtr	pFinishFunc;
}

- (void) setLastCircuit:(BOOL)isLastCircuit;

- (BOOL) miniMode;
- (void) setMiniMode:(BOOL)mini;

- (SBCell*) createCell;

+ (NSString*) name;
- (NSString*) name;

+ (NSString*) nameForCategory:(SBElementCategory)category;
+ (SBElementCategory) category;
- (SBElementCategory) category;

- (NSString*) nameOfInputAtIndex:(int)idx;
- (NSString*) nameOfOutputAtIndex:(int)idx;

- (SBConnectionType) typeOfInputAtIndex:(int)idx;
- (SBConnectionType) typeOfOutputAtIndex:(int)idx;

- (NSString*) informations;
- (NSView*) settingsView;

- (void) willChangeAudio;
- (void) didChangeAudio;
- (void) didChangeView;
- (void) didChangeGlobalView;
- (void) didChangeConnections;

- (NSMutableDictionary*) saveData;
- (BOOL) loadData:(NSDictionary*)data;

- (void) specificPrepare;
- (BOOL) alwaysExecute;
- (BOOL) constantRefresh;

- (SBCircuit*)subCircuit;

// gui stuff
// content specific, defaults draws image, ignores user events
- (SBGuiMode) guiMode;
- (void) setGuiMode:(SBGuiMode)mode;
- (void) setGuiOriginX:(int)x Y:(int)y; 
- (NSPoint) guiOrigin;
- (NSPoint) contentOrigin;
- (void) drawContent;
- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount;
- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly;
- (BOOL) mouseUpX:(int)x Y:(int)y;
- (BOOL) keyDown:(unichar)ukey;

// generic apparence
- (NSRect) frame;
- (NSRect) rectForInput:(int)idx;
- (NSRect) rectForOutput:(int)idx;
- (int) inputForX:(int)x Y:(int)y;
- (int) outputForX:(int)x Y:(int)y;
- (void) setOriginX:(int)x Y:(int)y; 
- (NSPoint) designOrigin;
- (BOOL) hitTestX:(int)x Y:(int)y;
- (void) drawRect:(NSRect)rect;


- (void) setSelected:(BOOL)s;

- (void) setColorsBack:(NSColor*)back contour:(NSColor*)contour front:(NSColor*)front;

- (void) trimDebug;
@end

