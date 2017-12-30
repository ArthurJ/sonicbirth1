/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifndef FRAMEWORK_UTILS
#define FRAMEWORK_UTILS

#import <Accelerate/Accelerate.h>

#ifdef __cplusplus
extern "C" {
#endif

extern int gHasAltivec;
extern int gNumberOfCPUs;


void frameworkInit(int callNSAppLoad);


// returns 3 for 10.3, 4 for 10.4, ...
int frameworkOSVersion();

// allow this to be defined by the IDE
#ifndef MAX_OS_VERSION_USE
#define MAX_OS_VERSION_USE (4)
#endif

FFTSetup sb_vDSP_create_fftsetup(vDSP_Length log2n, FFTRadix radix);
FFTSetupD sb_vDSP_create_fftsetupD(vDSP_Length log2n, FFTRadix radix);
void sb_vDSP_destroy_fftsetup(FFTSetup setup);
void sb_vDSP_destroy_fftsetupD(FFTSetupD setup);

#ifdef __cplusplus
}
#endif

#endif /* FRAMEWORK_UTILS */


