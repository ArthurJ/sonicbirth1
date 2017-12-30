#!/bin/bash
find . -name "*.m" -or -name "*.mm" -or -name "*.c" -or -name "*.h" | grep -v ThirdParty | grep -v jos_site | grep -v build | grep -v "nessie" | grep -v "Whirlpool" | grep -v "demo_version.raw.c" | grep -v "Documentation" | grep -v "PACKAGE" | xargs wc -l | sort -g;
