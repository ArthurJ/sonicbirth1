/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifdef __OBJC__

#ifndef COCOAADDITIONS_H
#define COCOAADDITIONS_H



@interface NSBezierPath (CocoaAdditions)

+ (NSBezierPath *)bezierPathWithRect:(NSRect)rect cornerRadius:(float)radius;
+ (void) strokeRect:(NSRect)rect cornerRadius:(float)radius;
+ (void) fillRect:(NSRect)rect cornerRadius:(float)radius;

@end


@interface NSImage (CocoaAdditions)

- (ogImage*) toOgImage;

@end



#endif /* COCOAADDITIONS_H */

#endif /* __OBJC__ */

