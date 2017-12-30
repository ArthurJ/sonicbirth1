/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "CocoaAdditions.h"
#include "tiffio.h"

@implementation NSBezierPath (CocoaAdditions)


+ (NSBezierPath *)bezierPathWithRect:(NSRect)rect cornerRadius:(float)radius
{
	float h1 = rect.size.height;
	float w1 = rect.size.width;
	float h2 = h1 / 2;
	float w2 = w1 / 2;
	float r = radius;
	float wr = w1 - r - r;
	float hr = h1 - r - r;

	if (r > h2) r = h2;
	if (r > w2) r = w2;
	
	NSBezierPath *bp = [NSBezierPath bezierPath];
	[bp setLineJoinStyle:NSRoundLineJoinStyle];
	
	
/*
	  c-----------------d
	 /					 \
	a b					e f
	|					  |
	|					  |
	l k					h g
	 \					 /
	  j-----------------i
*/
	
	
	NSPoint o = rect.origin;
	
	NSPoint a = o; a.y += r;
	NSPoint b = a; b.x += r;
	NSPoint c = o; c.x += r;
	
	NSPoint d = c; d.x += wr;
	NSPoint e = b; e.x += wr;
	NSPoint f = e; f.x += r;
	
	NSPoint g = f; g.y += hr;
	NSPoint h = e; h.y += hr;
	NSPoint i = h; i.y += r;
	
	NSPoint l = a; l.y += hr;
	NSPoint k = b; k.y += hr;
	NSPoint j = k; j.y += r;
	
	[bp moveToPoint:a];
	
	[bp appendBezierPathWithArcWithCenter:b radius:r startAngle:180 endAngle:270 clockwise:NO];
	[bp lineToPoint:d];
	
	[bp appendBezierPathWithArcWithCenter:e radius:r startAngle:270 endAngle:0 clockwise:NO];
	[bp lineToPoint:g];
	
	[bp appendBezierPathWithArcWithCenter:h radius:r startAngle:0 endAngle:90 clockwise:NO];
	[bp lineToPoint:j];
	
	[bp appendBezierPathWithArcWithCenter:k radius:r startAngle:90 endAngle:180 clockwise:NO];
	[bp lineToPoint:a];
	
	return bp;
}

+ (void) strokeRect:(NSRect)rect cornerRadius:(float)radius
{
	NSBezierPath *p = [NSBezierPath bezierPathWithRect:rect cornerRadius:radius];
	if (p) [p stroke];
}

+ (void) fillRect:(NSRect)rect cornerRadius:(float)radius
{
	NSBezierPath *p = [NSBezierPath bezierPathWithRect:rect cornerRadius:radius];
	if (p) [p fill];
}

@end

typedef struct
{
	const void *ptr;
	int size;
	int head;
} mTiffUserData;

static tsize_t mTIFFReadProc(thandle_t inud, tdata_t d, tsize_t s)
{
	mTiffUserData *ud = (mTiffUserData*)inud;
	if (s <= 0) return 0;
	
	if (ud->head + s > ud->size) s = ud->size - ud->head;
	if (d) memcpy(d, ud->ptr + ud->head, s);
	ud->head += s;
	
	return s;
}

static tsize_t mTIFFWriteProc(thandle_t inud, tdata_t d, tsize_t s)
{
	return -1;
}

static toff_t mTIFFSeekProc(thandle_t inud, toff_t o, int w)
{
	mTiffUserData *ud = (mTiffUserData*)inud;

	if (w == SEEK_CUR) o += ud->head;
	else if (w == SEEK_END) o += ud->size; 

	if (o > ud->size) o = ud->size;
	ud->head = o;
	return ud->head;
}

static int mTIFFCloseProc(thandle_t inud)
{
	return 0;
}

static toff_t mTIFFSizeProc(thandle_t inud)
{
	mTiffUserData *ud = (mTiffUserData*)inud;
	return ud->size;
}


@implementation NSImage (CocoaAdditions)

- (ogImage*) toOgImage
{
	NSData *data = [self TIFFRepresentation];
	if (!data) return nil;
	
	mTiffUserData ud;
	
	ud.ptr = [data bytes];
	ud.size = [data length];
	ud.head = 0;
	
	ogImage *oi = nil;
	
	TIFF* tif = TIFFClientOpen("dummy", "r", &ud,
								mTIFFReadProc, mTIFFWriteProc,
								mTIFFSeekProc, mTIFFCloseProc,
								mTIFFSizeProc, nil, nil);
    if (tif)
	{
        uint32 w, h;
        size_t npixels;
        uint32* raster;

        TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &w);
        TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h);
		
        npixels = w * h;
        raster = (uint32*) _TIFFmalloc(npixels * sizeof (uint32));
		
        if (raster != NULL)
		{
            if (TIFFReadRGBAImageOriented(tif, w, h, raster, ORIENTATION_TOPLEFT, 0))
			{
#if defined(__ppc__) || defined(__ppc64__)
				int i;
				for (i = 0; i < npixels; i++)
				{
					uint32 t = raster[i];
					raster[i] = (t >> 24) | (t << 24) | ((t >> 8) & 0xFF00) | ((t << 8) & 0xFF0000);
				}
#endif
				oi = ogInitImage(w, h, (unsigned char*)raster);
			}
            _TIFFfree(raster);
        }
        TIFFClose(tif);
    }
	
	return oi;
}

@end
