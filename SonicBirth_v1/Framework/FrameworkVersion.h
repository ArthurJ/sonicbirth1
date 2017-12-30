/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifndef FRAMEWORK_VERSION
#define FRAMEWORK_VERSION

#include "FrameworkSettings.h"

#ifdef __cplusplus
extern "C" {
#endif

unsigned int getSonicBirthFrameworkVersion();
int frameworkSupportsVersion(unsigned int version);

#ifdef __cplusplus
}
#endif

#endif /* FRAMEWORK_VERSION */
