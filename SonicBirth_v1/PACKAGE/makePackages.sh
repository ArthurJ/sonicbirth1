#!/bin/bash

YELLOW="[1;33m"
NORM="[0m"

cecho()
{
  echo "${YELLOW}$1${NORM}"
}

if [ "$#" -eq "0" ]
then
	cecho "Usage is: $0 major minor revision"
	cecho "Exemple: $0 1 0 1"
	cecho "Input should be \"SonicBirth v1.0.1\""
	cecho "Output will be \"SonicBirth_v101.dmg\""
	exit 2;
fi

#check file hierarchy
cecho "check file tree, then press enter.";
find SonicBirth\ v$1.$2.$3;
read;
clear;

#make images
cecho "Creating image...";
hdiutil create -srcfolder SonicBirth\ v$1.$2.$3 -format UDRW full;

#copying DS_Stores doesn't seem to work, do the openUp thing
cecho "Modify .dmg if needed (background images, openUp), then press enter.";
# ./openUp /Volumes/SonicBirth\ v1.2.0/.
# view -> hide toolbar, set background picture, place icons
# mv dmg_back4.jpg .dmg_back4.jpg
read;

hdiutil convert -format UDCO full.dmg -o full_ro;
mv full_ro.dmg SonicBirth_v$1$2$3.dmg;
rm full.dmg;



