/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "FrameworkUtils.h"
#import "SBPreferenceServer.h"
 
int gHasAltivec = 0;
int gNumberOfCPUs = 1;

static int gHasInited = 0;
static int gSystemVersion = 3;

// ------------------------------------------------------------
// ALTIVEC DETECTION FUNCTION
// http://developer.apple.com/hardware/ve/g3_compatibility.html
#include <sys/sysctl.h>
//returns: 0 for scalar only, 1 for AltiVec - Note: may return >1 in the future 
static int GetAltiVecTypeAvailable()
{
	int sels[2] = { CTL_HW, HW_VECTORUNIT };
	int vType = 0; //0 == scalar only
	size_t length = sizeof(vType);
	int error = sysctl(sels, 2, &vType, &length, NULL, 0);
	if( 0 == error ) return vType;

	return 0;
}

// ------------------------------------------------------------
#include <CoreServices/CoreServices.h>
static int GetNumberOfCPUs()
{
	return MPProcessors();
}


@interface FrameworkUtils : NSObject
+ (void)enableMultithreading;
@end
@implementation FrameworkUtils
+ (void)enableMultithreading { [NSThread exit]; }
@end

// ------------------------------------------------------------
void frameworkInit(int callNSAppLoad)
{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	
	if (gHasInited) return;
	gHasInited = 1;

	[NSThread detachNewThreadSelector:@selector(enableMultithreading) toTarget:[FrameworkUtils class] withObject:nil];	

	// load appKit if needed.
	if (callNSAppLoad) NSApplicationLoad();
	
	gHasAltivec = GetAltiVecTypeAvailable();
	gNumberOfCPUs = GetNumberOfCPUs();
	
	// load user prefs
	[SBPreferenceServer loadPref];
	
	if (pool) [pool release];
	
	long ver = 0;
	OSErr err = Gestalt(gestaltSystemVersion , &ver);
	if (!err) gSystemVersion = (ver >> 4) & 0xF;
}

// ------------------------------------------------------------
// returns 3 for 10.3, 4 for 10.4, ...
int frameworkOSVersion()
{
	return gSystemVersion;
}

// ------------------------------------------------------------
FFTSetup sb_vDSP_create_fftsetup(vDSP_Length log2n, FFTRadix radix)
{
	return vDSP_create_fftsetup(log2n, radix);
}

FFTSetupD sb_vDSP_create_fftsetupD(vDSP_Length log2n, FFTRadix radix)
{
	return vDSP_create_fftsetupD(log2n, radix);
}

void sb_vDSP_destroy_fftsetup(FFTSetup setup)
{

}

void sb_vDSP_destroy_fftsetupD(FFTSetupD setup)
{

}

