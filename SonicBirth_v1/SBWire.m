/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBWire.h"
#import "SBPreferenceServer.h"

@implementation SBWire

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mAnchors = [[NSMutableArray alloc] init];
		if (!mAnchors)
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (void) dealloc
{
	if (mAnchors) [mAnchors release];
	[super dealloc];
}

- (BOOL) isConnectedToElement:(SBElement*)element
{
	if (!element) return NO;
	return ((element == mInputElement) || (element == mOutputElement));
}

- (SBElement*) inputElement
{
	return mInputElement;
}

- (SBElement*) outputElement
{
	return mOutputElement;
}

- (void) setInputElement:(SBElement*)e
{
	mInputElement = e;
}

- (void) setOutputElement:(SBElement*)e
{
	mOutputElement = e;
}

- (void) setInputIndex:(int)idx
{
	if (idx < 0) idx = 0;
	mInputIndex = idx;
}

- (void) setOutputIndex:(int)idx
{
	if (idx < 0) idx = 0;
	mOutputIndex = idx;
}

- (int) inputIndex
{
	return mInputIndex;
}

- (int) outputIndex
{
	return mOutputIndex;
}

- (void) setOutputX:(float)x Y:(float)y
{
	mOutputX = x;
	mOutputY = y;
}

- (void) setInputX:(float)x Y:(float)y
{
	mInputX = x;
	mInputY = y;
}

#define kEndSize 6.f

- (void) drawRect:(NSRect)rect
{
	NSPoint a, b, p, m;
	NSRect r;
	
	if (mInputElement)
	{
		r = [mInputElement rectForInput:mInputIndex];
	
		a.x = r.origin.x + r.size.width/2;
		a.y = r.origin.y + r.size.height/2;
	}
	else
	{
		a.x = mInputX;
		a.y = mInputY;
	}
	
	if (mOutputElement)
	{
		r = [mOutputElement rectForOutput:mOutputIndex];
		
		b.x = r.origin.x + r.size.width/2;
		b.y = r.origin.y + r.size.height/2;
	}
	else
	{
		b.x = mOutputX;
		b.y = mOutputY;
	}
	
	//[[NSColor blackColor] set];
	ogSetColorIndex(ogBlack);
	
	int c = [mAnchors count], i;
	
	if (!c)
		//[NSBezierPath strokeLineFromPoint:a toPoint:b];
		ogStrokeLine(a.x, a.y, b.x, b.y);
	else
	{
		/*
		[NSBezierPath   strokeLineFromPoint:a
						toPoint:((SBPoint*)[mAnchors objectAtIndex:0])->pt];
		
		for (i = 0; i < c - 1; i++)
			[NSBezierPath   strokeLineFromPoint:((SBPoint*)[mAnchors objectAtIndex:i])->pt
							toPoint:((SBPoint*)[mAnchors objectAtIndex:i+1])->pt];
							
		[NSBezierPath   strokeLineFromPoint:((SBPoint*)[mAnchors objectAtIndex:c-1])->pt
						toPoint:b];
		*/
		
		p = ((SBPoint*)[mAnchors objectAtIndex:0])->pt;
		ogStrokeLine(a.x, a.y, p.x, p.y);
		
		for (i = 0; i < c - 1; i++)
		{
			p = ((SBPoint*)[mAnchors objectAtIndex:i])->pt;
			m = ((SBPoint*)[mAnchors objectAtIndex:i+1])->pt;
			ogStrokeLine(p.x, p.y, m.x, m.y);
		}
		
		p = ((SBPoint*)[mAnchors objectAtIndex:c-1])->pt;
		ogStrokeLine(p.x, p.y, b.x, b.y);
	}
	
	if (!gShowWireAnchors) return;
	
	NSRect end;
	end.origin = a;
	//end.origin.x -= kEndSize/2;
	//end.origin.y -= kEndSize/2;
	end.size.width = kEndSize;
	end.size.height = kEndSize;
	
	//[[NSBezierPath bezierPathWithOvalInRect:end] fill];
	ogFillCircle(end.origin.x, end.origin.y, (kEndSize/2));
	
	end.origin = b;
	//end.origin.x -= kEndSize/2;
	//end.origin.y -= kEndSize/2;
	
	//[[NSBezierPath bezierPathWithOvalInRect:end] fill];
	ogFillCircle(end.origin.x, end.origin.y, kEndSize/2);
	
	for (i = 0; i < c; i++)
	{
		end.origin = ((SBPoint*)[mAnchors objectAtIndex:i])->pt;
		//end.origin.x -= kEndSize/2;
		//end.origin.y -= kEndSize/2;
	
		//[[NSBezierPath bezierPathWithOvalInRect:end] fill];
		ogFillCircle(end.origin.x, end.origin.y, kEndSize/2);
	}
}

- (BOOL) hitTestX:(int)x Y:(int)y pt:(NSPoint)a pt:(NSPoint)b
{	
	float dst = hypotf(fabsf(a.x-b.x), fabsf(a.y-b.y));
	float dst1 = hypotf(fabsf(x-b.x), fabsf(y-b.y));
	float dst2 = hypotf(fabsf(x-a.x), fabsf(y-a.y));
	float dstt = dst1 + dst2;
	
	float ny = b.x - a.x;
	float nx = a.y - b.y;
	float c = nx*a.x + ny*a.y;
	float d = fabsf(nx*x + ny*y - c) / hypotf(nx, ny);
	
	//NSLog(@"seg lengh: %f point length: %f diff: %f dist: %f",
	//		dst, dstt, fabsf(dst - dstt), d);
	
	return ((fabsf(dst - dstt) < 1.) && (d < 2.));
}

- (BOOL) hitTestX:(int)x Y:(int)y pt:(NSPoint)a
{
	float dst = hypotf(fabsf(x-a.x), fabsf(y-a.y));
	return (dst <= (kEndSize/2));
}

- (BOOL) hitTestX:(int)x Y:(int)y
{
	NSPoint a, b;
	NSRect r;
	
	if (mInputElement)
	{
		r = [mInputElement rectForInput:mInputIndex];
	
		a.x = r.origin.x + r.size.width/2;
		a.y = r.origin.y + r.size.height/2;
	}
	else
	{
		a.x = mInputX;
		a.y = mInputY;
	}
	
	if (mOutputElement)
	{
		r = [mOutputElement rectForOutput:mOutputIndex];
		
		b.x = r.origin.x + r.size.width/2;
		b.y = r.origin.y + r.size.height/2;
	}
	else
	{
		b.x = mOutputX;
		b.y = mOutputY;
	}
	
	if ([self hitTestX:x Y:y pt:a]) return NO;
	if ([self hitTestX:x Y:y pt:b]) return NO;
	
	int c = [mAnchors count], i;
	
	if (!c)
		return [self hitTestX:x Y:y pt:a pt:b];
	else
	{
		if ([self hitTestX:x Y:y pt:a pt:((SBPoint*)[mAnchors objectAtIndex:0])->pt])
			return YES;
		
		for (i = 0; i < c - 1; i++)
			if ([self hitTestX:x Y:y	pt:((SBPoint*)[mAnchors objectAtIndex:i])->pt
										pt:((SBPoint*)[mAnchors objectAtIndex:i+1])->pt])
				return YES;

		if ([self hitTestX:x Y:y	pt:((SBPoint*)[mAnchors objectAtIndex:c-1])->pt
									pt:b])
			return YES;
	}
	

	for (i = 0; i < c; i++)
	{
		if ([self hitTestX:x Y:y pt:((SBPoint*)[mAnchors objectAtIndex:i])->pt])
			return YES;
	}

	return NO;
}

- (SBPoint*) anchorForX:(int)x Y:(int)y
{
	int c = [mAnchors count], i;
	for (i = 0; i < c; i++)
	{
		SBPoint *pt = [mAnchors objectAtIndex:i];
		if ([self hitTestX:x Y:y pt:pt->pt])
			return pt;
	}
	return nil;
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	SBPoint *pt = [self anchorForX:x Y:y];
	if (pt && clickCount == 2)
	{
		[mAnchors removeObject:pt];
		return YES;
	}
	else if (!pt)
	{
		NSPoint a, b;
		NSRect r;
		
		if (mInputElement)
		{
			r = [mInputElement rectForInput:mInputIndex];
		
			a.x = r.origin.x + r.size.width/2;
			a.y = r.origin.y + r.size.height/2;
		}
		else
		{
			a.x = mInputX;
			a.y = mInputY;
		}
		
		if (mOutputElement)
		{
			r = [mOutputElement rectForOutput:mOutputIndex];
			
			b.x = r.origin.x + r.size.width/2;
			b.y = r.origin.y + r.size.height/2;
		}
		else
		{
			b.x = mOutputX;
			b.y = mOutputY;
		}
	
		pt = [[SBPoint alloc] init];
		if (!pt) return NO;
		
		pt->pt.x = x;
		pt->pt.y = y;
		
		int c = [mAnchors count], i;
		
		if (!c || [self hitTestX:x Y:y pt:a pt:((SBPoint*)[mAnchors objectAtIndex:0])->pt])
		{
			[mAnchors insertObject:pt atIndex:0];
		}
		else if ([self hitTestX:x Y:y	pt:((SBPoint*)[mAnchors objectAtIndex:c-1])->pt
										pt:b])
		{
			[mAnchors insertObject:pt atIndex:c];
		}
		else
		{
			for (i = 0; i < c - 1; i++)
				if ([self hitTestX:x Y:y	pt:((SBPoint*)[mAnchors objectAtIndex:i])->pt
											pt:((SBPoint*)[mAnchors objectAtIndex:i+1])->pt])
				{
					[mAnchors insertObject:pt atIndex:i+1];
					break;
				}
		}
		
		[pt release];
		return YES;
	}

	return NO;
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	SBPoint *pt = [self anchorForX:lx Y:ly];
	if (pt)
	{
		pt->pt.x = x;
		pt->pt.y = y;
		return YES;
	}
	else
		return NO;
}

- (NSMutableDictionary*) saveData
{
	int c = [mAnchors count], i;
	if (!c) return nil;
	
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	NSMutableArray *ma = [[NSMutableArray alloc] init];
		for (i = 0; i < c; i++)
		{
			SBPoint *pt = [mAnchors objectAtIndex:i];
			NSMutableDictionary *mde = [[NSMutableDictionary alloc] init];
			
			[mde setObject:[NSNumber numberWithFloat:pt->pt.x] forKey:@"x"];
			[mde setObject:[NSNumber numberWithFloat:pt->pt.y] forKey:@"y"];
			
			[ma addObject:mde];
			[mde release];
		}
	[md setObject:ma forKey:@"AnchorsArray"];
	[ma release];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	if (!data) return NO;
	
	NSArray *a = [data objectForKey:@"AnchorsArray"];
	if (a)
	{
		int c = [a count], i;
		for (i = 0; i < c; i++)
		{
			NSDictionary *d = [a objectAtIndex:i];
		
			NSNumber *n1, *n2;
			
			n1 = [d objectForKey:@"x"];
			n2 = [d objectForKey:@"y"];
			
			if (n1 && n2)
			{
				SBPoint *pt = [[SBPoint alloc] init];
				pt->pt.x = [n1 floatValue];
				pt->pt.y = [n2 floatValue];
				[mAnchors addObject:pt];
				[pt release];
			}
		}
	}
	return YES;
}

- (void) translateDeltaX:(int)x deltaY:(int)y
{
	int c = [mAnchors count], i;
	if (!c) return;

	for (i = 0; i < c; i++)
	{
		SBPoint *pt = [mAnchors objectAtIndex:i];
		pt->pt.x += x;
		pt->pt.y += y;
	}
}

@end
