/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#include "openGlWrap.h"
#include <OpenGL/gl.h>
#include <vector>
#include <list>
#include <map>
#include <math.h>
#include <string.h>
#include <stdlib.h>

//#define DEBUG_OGWRAP
#ifdef DEBUG_OGWRAP
#define LOG(args...) fprintf(stderr, "ogWrap " args);
#else
#define LOG(args...) 
#endif

//using namespace std;

// - - - - - - - - - - - - - - - - - -
// INTERNAL STRUCTURE AND VARIABLES
// - - - - - - - - - - - - - - - - - -

typedef unsigned long long ogImageId;

typedef struct ogImage
{
	unsigned char *bitmap;
	int w, h;
	ogImageId id;
} ogImage;

typedef struct ogImageTex
{
	int count;
	GLuint *tex;
	GLuint list;
} ogImageTex;

typedef struct ogWrap
{
	GLuint fontBase;
	std::map<ogImageId, ogImageTex> imageTexs;
	std::vector<ogImageId> deallocatePool;
} ogWrap;

static int ogTablesInited = 0;
static ogWrap *ogCurrentWrap = NULL;
static std::list<ogWrap*> ogValidWraps;
static ogImageId ogCurrentId = 1;

static float ogCosTable[361];
static float ogSinTable[361];
static int   ogStepTable[60];
static float ogColorTable[ogColorCount][4] =
{
	{0, 0, 0, 1},
	{1, 1, 1, 1},
	{1, 0, 0, 1},
	{0, 1, 0, 1},
	{0, 0, 1, 1},
	{0.5f, 0.5f, 0.5f, 1},
	{0.9f, 0.9f, 0.9f, 1}
};

static int gFontHeight = 12, gFontMove = 5;
static const GLubyte gCourier9[95][12] =
{
	{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x20, 0x00, 0x20, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x50, 0x50, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x00, 0xA0, 0xF0, 0x50, 0x78, 0x28, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x20, 0x70, 0x50, 0x10, 0x20, 0x50, 0x70, 0x20, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xA0, 0x50, 0x30, 0x40, 0xA0, 0x50, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x68, 0x90, 0xA8, 0x40, 0x80, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x40, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x20, 0x40, 0x40, 0x40, 0x40, 0x40, 0x20, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x40, 0x20, 0x20, 0x20, 0x20, 0x20, 0x40, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x70, 0x70, 0x20, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x20, 0x20, 0xF8, 0x20, 0x20, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x40, 0x20, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x40, 0x40, 0x20, 0x20, 0x10, 0x10, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x90, 0x90, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0x20, 0x20, 0x20, 0x20, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xF0, 0x40, 0x20, 0x10, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x10, 0x20, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x10, 0x10, 0xF0, 0x50, 0x30, 0x10, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x10, 0xE0, 0x80, 0xF0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x90, 0xE0, 0x40, 0x20, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x40, 0x40, 0x20, 0x20, 0x90, 0xF0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x90, 0x60, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x40, 0x20, 0x70, 0x90, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x40, 0x20, 0x20, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x20, 0x40, 0x80, 0x40, 0x20, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x00, 0xF0, 0x00, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x40, 0x20, 0x10, 0x20, 0x40, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x40, 0x00, 0x40, 0x20, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x60, 0x80, 0xB0, 0xD0, 0xB0, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x90, 0x90, 0xF0, 0x90, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xE0, 0x50, 0x50, 0x60, 0x50, 0xE0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x80, 0x80, 0x90, 0x70, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xE0, 0x50, 0x50, 0x50, 0x50, 0xE0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xF0, 0x40, 0x40, 0x60, 0x40, 0xF0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xE0, 0x40, 0x40, 0x60, 0x40, 0xF0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0xB0, 0x80, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xD8, 0x90, 0x90, 0xF0, 0x90, 0xD8, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0x20, 0x20, 0x20, 0x20, 0x70, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x90, 0x10, 0x10, 0x38, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x90, 0xA0, 0xC0, 0xC0, 0xA0, 0x90, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xF8, 0x48, 0x40, 0x40, 0x40, 0xE0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x88, 0x88, 0x88, 0xA8, 0xD8, 0x88, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x90, 0x90, 0xB0, 0xD0, 0x90, 0x90, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x90, 0x90, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xE0, 0x40, 0x60, 0x50, 0x50, 0xE0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x10, 0x60, 0x90, 0x90, 0x90, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xC8, 0x50, 0x60, 0x50, 0x50, 0xE0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xE0, 0x90, 0x10, 0x60, 0x90, 0x70, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0x20, 0x20, 0xA8, 0xA8, 0xF8, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x90, 0x90, 0x90, 0xD8, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x20, 0x20, 0x50, 0x50, 0x88, 0xD8, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x50, 0x50, 0x50, 0xA8, 0xA8, 0xA8, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xD8, 0x50, 0x20, 0x20, 0x50, 0xD8, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0x20, 0x20, 0x20, 0x50, 0xD8, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xF0, 0x90, 0x40, 0x20, 0x90, 0xF0, 0x00, 0x00, 0x00},
	{0x00, 0x60, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x10, 0x10, 0x20, 0x20, 0x40, 0x40, 0x00, 0x00, 0x00},
	{0x00, 0x60, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x40, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0x90, 0x50, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xE0, 0x90, 0x90, 0xE0, 0x80, 0x80, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0x80, 0x90, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x78, 0x90, 0x90, 0x70, 0x10, 0x30, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0xC0, 0xB0, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xF0, 0x40, 0x40, 0xF0, 0x40, 0x30, 0x00, 0x00, 0x00},
	{0x00, 0x60, 0x10, 0x70, 0x90, 0x90, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xD8, 0x90, 0x90, 0xE0, 0x80, 0xC0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0x20, 0x20, 0x60, 0x00, 0x20, 0x00, 0x00, 0x00},
	{0x00, 0xC0, 0x20, 0x20, 0x20, 0x20, 0xE0, 0x00, 0x20, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xD8, 0x50, 0x60, 0x50, 0x40, 0xC0, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0x20, 0x20, 0x20, 0x20, 0x60, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xA8, 0xA8, 0xA8, 0xD0, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x90, 0x90, 0x90, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x60, 0x90, 0x90, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0xC0, 0x80, 0xE0, 0x90, 0x90, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x38, 0x10, 0x70, 0x90, 0x90, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xE0, 0x40, 0x40, 0xB0, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xE0, 0x30, 0xC0, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x30, 0x40, 0x40, 0xF0, 0x40, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x70, 0x90, 0x90, 0x90, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x20, 0x20, 0x50, 0xD8, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x50, 0x50, 0xA8, 0xA8, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x50, 0x20, 0x20, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x40, 0x20, 0x20, 0x50, 0x50, 0xD8, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0xF0, 0x40, 0x20, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x20, 0x40, 0x40, 0x80, 0x40, 0x40, 0x20, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x40, 0x20, 0x20, 0x10, 0x20, 0x20, 0x40, 0x00, 0x00, 0x00},
	{0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00}
};

// - - - - - - - - - - - - - - - - - -
// INTERNAL FUNCTIONS
// - - - - - - - - - - - - - - - - - -

static inline float dcos(int deg)
{
	return ogCosTable[deg];
}

static inline float dsin(int deg)
{
	return ogSinTable[deg];
}

static inline int dstep(float radius)
{
	int r = (int)(radius + 0.5f);
	if (r < 0 || r >= 60) return 1;
	return ogStepTable[r];
}

static inline ogImageId getNextImageId()
{
	return ogCurrentId++;
}

// - - - - - - - - - - - - - - - - - -
// EXTERNAL FUNCTIONS
// - - - - - - - - - - - - - - - - - -

//
// initialization
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ogWrap * ogInit()
{
	if (!ogTablesInited)
	{
		ogTablesInited = 1;
		
		for (int i = 0; i < 361; i++)
		{
			ogCosTable[i] = cos(i * M_PI / 180.);
			ogSinTable[i] = sin(i * M_PI / 180.);
		}
		
		ogStepTable[0] = 1;
		for (int i = 1; i < 60; i++)
		{
			ogStepTable[i] = (int)(atan2(1., i) * 180. / M_PI + 0.5);
			if (ogStepTable[i] < 1) ogStepTable[i] = 1;
		}
	}
	
	
	// opengl
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glEnable(GL_TEXTURE_2D);
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glDisable(GL_COLOR_MATERIAL);
	glDisable(GL_AUTO_NORMAL);
	glDisable(GL_NORMALIZE);
	
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_LINE_SMOOTH);
	glDisable(GL_POLYGON_SMOOTH);
	
	glColor4f(0, 0, 0, 1);
	glClearColor(1, 1, 1, 1);
	glLineWidth(1);
	

	ogWrap *w = new ogWrap; //must use new to initialize the map and vector
	if (!w) return NULL;
	
	// string init
	w->fontBase = glGenLists(256);
	for (int i = 0; i < 95; i++)
	{
		glNewList(w->fontBase+i+32, GL_COMPILE);
			glBitmap(8, gFontHeight, 0, gFontHeight, gFontMove, 0, gCourier9[i]);
		glEndList( );
	}
	
	glListBase(w->fontBase);
	
	LOG("new context : %p\n", w);
	ogValidWraps.push_back(w);
	return w;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogBeginDrawing(ogWrap *w)
{
	//printf("ogBeginDrawing: openGL context: %p\n", w);

	ogCurrentWrap = w;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogEndDrawing(int flush)
{
	//printf("ogEndDrawing\n");

	if (flush) glFlush();
	
	// empty the deallocate pool
	if (ogCurrentWrap)
	{
		int c = ogCurrentWrap->deallocatePool.size();
		LOG("%i images in deallocate pool in context: %p\n", c, ogCurrentWrap);
		
		for (int i = 0; i < c; i++)
		{
			ogImageId id = ogCurrentWrap->deallocatePool.back();
			
			std::map<ogImageId, ogImageTex>::iterator it = ogCurrentWrap->imageTexs.find(id);
			if (it != ogCurrentWrap->imageTexs.end())
			{
				ogImageTex itex = it->second;
				
				if (itex.list)
					glDeleteLists(itex.list, 1);
					
				if (itex.tex)
				{
					if (itex.count) glDeleteTextures(itex.count, itex.tex);
					free(itex.tex);
				}
					
				ogCurrentWrap->imageTexs.erase(it);
				
				LOG("removed image : %lld in context: %p\n", id, ogCurrentWrap);
			}
			
			ogCurrentWrap->deallocatePool.pop_back();
		}
	}
	
	ogCurrentWrap = NULL;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogRelease(ogWrap *w)
{
	if (w)
	{
		//glDeleteLists(w->fontBase, 256);
		//the context is already deallocated or will be, so no need to
		
		LOG("removed context : %p\n", w);
		ogValidWraps.remove(w);
		delete w;
	}
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogSetShape(float x, float y, float w, float h)
{
	glViewport((int)x, (int)y, (int)w, (int)h);
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	glOrtho(0, w, h, 0, -1, 1);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

//
// contexts
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogPushContext()
{
	glPushAttrib(GL_CURRENT_BIT | GL_LINE_BIT);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogPopContext()
{
	glPopAttrib();
}

//
// matrix
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogPushMatrix()
{
	glPushMatrix();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogTranslate(float x, float y)
{
	glTranslatef(x, y, 0);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogPopMatrix()
{
	glPopMatrix();
}


//
// attributes
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogSetLineWidth(float lw)
{
	glLineWidth(lw);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogSetColor(ogColor c)
{
	glColor4f(c.r, c.g, c.b, c.a);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogSetColorComp(float r, float g, float b, float a)
{
	glColor4f(r, g, b, a);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogSetColorIndex(ogColorIndex i)
{
	if (i < 0 || i >= ogColorCount) return;
	glColor4f(	ogColorTable[i][0],
				ogColorTable[i][1],
				ogColorTable[i][2],
				ogColorTable[i][3]);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogSetClearColor(float r, float g, float b, float a)
{
	glClearColor(r, g, b, a);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogEnableClipRegion(float x, float y, float w, float h)
{
	double upperXBoundPlane[4] = {  1,  0, 0, -x  };
	double lowerXBoundPlane[4] = { -1,  0, 0, x+w };
	double upperYBoundPlane[4] = {  0,  1, 0, -y  };
	double lowerYBoundPlane[4] = {  0, -1, 0, y+h };

	glClipPlane(GL_CLIP_PLANE0, upperXBoundPlane);
	glClipPlane(GL_CLIP_PLANE1, lowerXBoundPlane);
	glClipPlane(GL_CLIP_PLANE2, upperYBoundPlane);
	glClipPlane(GL_CLIP_PLANE3, lowerYBoundPlane);

	glEnable(GL_CLIP_PLANE0);
	glEnable(GL_CLIP_PLANE1);
	glEnable(GL_CLIP_PLANE2);
	glEnable(GL_CLIP_PLANE3);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogDisableClipRegion()
{
	glDisable(GL_CLIP_PLANE0);
	glDisable(GL_CLIP_PLANE1);
	glDisable(GL_CLIP_PLANE2);
	glDisable(GL_CLIP_PLANE3);
}


//
// drawing
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogClearBuffer()
{
	glClear(GL_COLOR_BUFFER_BIT);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogDrawPoint(float x, float y)
{
	glBegin(GL_POINTS);
		glVertex2f(x, y);
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogStrokeLine(float x_1, float y_1, float x_2, float y_2)
{
	glBegin(GL_LINES);
		glVertex2f(x_1, y_1);
		glVertex2f(x_2, y_2);
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogStrokeTriangle(float x_1, float y_1, float x_2, float y_2, float x_3, float y_3)
{
	glBegin(GL_LINE_LOOP);
		glVertex2f(x_1, y_1);
		glVertex2f(x_2, y_2);
		glVertex2f(x_3, y_3);
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogFillTriangle(float x_1, float y_1, float x_2, float y_2, float x_3, float y_3)
{
	glBegin(GL_TRIANGLES);
		glVertex2f(x_1, y_1);
		glVertex2f(x_2, y_2);
		glVertex2f(x_3, y_3);
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogStrokeRectangle(float x, float y, float w, float h)
{
	glBegin(GL_LINE_LOOP);
		glVertex2f(x, y);
		glVertex2f(x + w, y);
		glVertex2f(x + w, y + h);
		glVertex2f(x, y + h);
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogFillRectangle(float x, float y, float w, float h)
{
	glBegin(GL_POLYGON);
		glVertex2f(x, y);
		glVertex2f(x + w, y);
		glVertex2f(x + w, y + h);
		glVertex2f(x, y + h);
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogStrokeRoundedRectangle(float x, float y, float w, float h, float r)
{
	float d = r + r;
	if (d > w) { r = w * 0.5f; d = r + r; }
	if (d > h) { r = h * 0.5f; d = r + r; }
	int s = dstep(r);
	
	glBegin(GL_LINE_LOOP);
	
		// top left corner
		for (int a = 180; a <= 270; a += s)
				glVertex2f(x+r + dcos(a)*r, y+r + dsin(a)*r);
	
		glVertex2f(x+w-r, y);
		
		// top right corner
		for (int a = 270; a <= 360; a += s)
				glVertex2f(x+w-r + dcos(a)*r, y+r + dsin(a)*r);
				
		glVertex2f(x+w, y+h-r);
		
		// bottom right corner
		for (int a = 0; a <= 90; a += s)
				glVertex2f(x+w-r + dcos(a)*r, y+h-r + dsin(a)*r);
				
		glVertex2f(x+r, y+h);
		
		// bottom left corner
		for (int a = 90; a <= 180; a += s)
				glVertex2f(x+r + dcos(a)*r, y+h-r + dsin(a)*r);
	
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogFillRoundedRectangle(float x, float y, float w, float h, float r)
{
	float d = r + r;
	if (d > w) { r = w * 0.5f; d = r + r; }
	if (d > h) { r = h * 0.5f; d = r + r; }
	int s = dstep(r);
	
	glBegin(GL_POLYGON);
	
		// top left corner
		for (int a = 180; a <= 270; a += s)
				glVertex2f(x+r + dcos(a)*r, y+r + dsin(a)*r);
	
		glVertex2f(x+w-r, y);
		
		// top right corner
		for (int a = 270; a <= 360; a += s)
				glVertex2f(x+w-r + dcos(a)*r, y+r + dsin(a)*r);
				
		glVertex2f(x+w, y+h-r);
		
		// bottom right corner
		for (int a = 0; a <= 90; a += s)
				glVertex2f(x+w-r + dcos(a)*r, y+h-r + dsin(a)*r);
				
		glVertex2f(x+r, y+h);
		
		// bottom left corner
		for (int a = 90; a <= 180; a += s)
				glVertex2f(x+r + dcos(a)*r, y+h-r + dsin(a)*r);
	
	glEnd();
}


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogStrokeCircle(float x, float y, float r)
{
	int s = dstep(r);
	glBegin(GL_LINE_LOOP);
		for (int a = 0; a < 360; a += s)
			glVertex2f(x + dcos(a)*r, y + dsin(a)*r);
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogFillCircle(float x, float y, float r)
{
	int s = dstep(r);
	glBegin(GL_POLYGON);
		for (int a = 0; a < 360; a += s)
			glVertex2f(x + dcos(a)*r, y + dsin(a)*r);
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogStrokeArc(float x, float y, float r, float a1, float a2)
{
	int a = (int)a1, b = (int)a2;
	
	if (b <= a) return;
	if (a < 0 || a > 360) return;
	if (b < 0 || b > 360) return;
	
	int s = dstep(r);
	glBegin(GL_LINE_STRIP);
		for (; a < b; a += s)
			glVertex2f(x + dcos(a)*r, y + dsin(a)*r);
		glVertex2f(x + dcos(b)*r, y + dsin(b)*r);
	glEnd();
}

void ogFillArc(float x, float y, float r, float a1, float a2)
{
	int a = (int)a1, b = (int)a2;
	
	if (b <= a) return;
	if (a < 0 || a > 360) return;
	if (b < 0 || b > 360) return;
	
	int s = dstep(r);
	glBegin(GL_TRIANGLE_FAN);
		glVertex2f(x, y);
		for (; a < b; a += s)
			glVertex2f(x + dcos(a)*r, y + dsin(a)*r);
		glVertex2f(x + dcos(b)*r, y + dsin(b)*r);
	glEnd();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
float ogStringWidth(const char *s)
{
	if (!s) return 0;
	return strlen(s) * gFontMove;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogDrawStringAtPoint(const char *s, float x, float y)
{
	/*printf("ogDrawStringAtPoint: %s openGL context: %p x: %f y: %f fontBase: %i\n",
			(s) ? s : "null",
			ogCurrentWrap,
			x, y,
			(ogCurrentWrap) ? ogCurrentWrap->fontBase : 0);*/


	if (!s) return;
	if (!*s) return;
	if (!ogCurrentWrap) return;
	
	int ln = strlen(s);
	
	glRasterPos2f(x + 0.5f, y + 0.5f);
	//glPushAttrib(GL_LIST_BIT);

     // glListBase(ogCurrentWrap->fontBase);
      glCallLists(ln, GL_UNSIGNED_BYTE, (GLubyte *)s);

	//glPopAttrib();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogDrawStringInRect(const char *s, float x, float y, float w, float h)
{
	/*printf("ogDrawStringInRect: %s openGL context: %p x: %f y: %f w: %f h: %f fontBase: %i\n",
			(s) ? s : "null",
			ogCurrentWrap,
			x, y, w, h,
			(ogCurrentWrap) ? ogCurrentWrap->fontBase : 0);*/

	if (!s) return;
	if (!*s) return;
	if (!ogCurrentWrap) return;
	
	int ln = strlen(s); int max = (int)(w / gFontMove); if (ln > max) ln = max;
	int dw = ln * gFontMove;

	x += (w - dw) * 0.5f;
	y += (h - gFontHeight) * 0.5f;
	
	glRasterPos2f(x + 0.5f, y + 0.5f);
	//glPushAttrib(GL_LIST_BIT);

      //glListBase(ogCurrentWrap->fontBase);
      glCallLists(ln, GL_UNSIGNED_BYTE, (GLubyte *)s);

	//glPopAttrib();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
static inline int maxChars(double val)
{
	int sign = 0;
	if (val < 0.) { sign = 1; val = -val; }

	int size = (int) ceil( log10(val) );
	
	if (size == 0) size = 1;
	else if (size < 0) size = -size + 2; // +2 for "0." (size for 0.001 is -3)
	
	return sign + size;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogDrawValueInRect(double v, float x, float y, float w, float h)
{
// Note: isnan and isinf are not available while using -ffast-math. 
// -ffast-math (Relax IEEE Compliance) has been disabled. 
// Honestly, I don't know how well/if these approximations will work.

// Note: Use of isnan avoided
// if (isnan(v)) 
	if (v > DBL_MAX == false && v < DBL_MAX == false)
	{
		ogDrawStringInRect("nan", x, y, w, h);
		return;
	}
	
// Note: use of isinf avoided
// else if (isinf(v))
	else if (fabs(v) >= DBL_MAX)	
	{
		ogDrawStringInRect((v < 0) ? "-inf" : "inf", x, y, w, h);
		return;
	}

	int max = (int)(w / gFontMove);
	int nmax = maxChars(v);
	if (nmax < 1) nmax = 1;
	
	char st[122];

	if (nmax == max || nmax == max - 1)
		snprintf(st, 120, "%f", v);
			
	else if (nmax > max)
	{
		char fm[32];
		max -= 6; // 7.e+48
		if (v < 0) max--;
		if (max < 0) max = 0;
		snprintf(fm, 30, "%%.%ie", max); fm[30] = 0;
		snprintf(st, 120, fm, v);
	}
	
	else // nmax < max - 1
	{
		char fm[32];
		snprintf(fm, 30, "%%.%if", (max - 1) - nmax); fm[30] = 0;
		snprintf(st, 120, fm, v);
	}
	
	st[120] = 0;
	
	ogDrawStringInRect(st, x, y, w, h);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ogImage * ogInitImage(int w, int h, unsigned char *data)
{
	if (w < 1 || h < 1 || !data) return NULL;
	
	ogImage *oi = (ogImage *) malloc(sizeof(ogImage));
	if (!oi) return NULL;
	
	oi->w = w;
	oi->h = h;
	oi->id = getNextImageId();
	
	int dataSize = (w*h) << 2;
	oi->bitmap = (unsigned char *)malloc(dataSize);
	if (!oi->bitmap)
	{
		free(oi);
		return NULL;
	}
	
	memcpy(oi->bitmap, data, dataSize);
	LOG("created image : %lld\n", oi->id);
	
	return oi;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
int ogImageWidth(ogImage *oi)
{
	if (!oi) return 0;
	return oi->w;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
int ogImageHeight(ogImage *oi)
{
	if (!oi) return 0;
	return oi->h;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogDrawImage(ogImage *oi, float x, float y)
{
	ogDrawRotatedImage(oi, x, y, 0);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogDrawRotatedImage(ogImage *oi, float x, float y, float a)
{
	if (!oi) return;
	if (!ogCurrentWrap) return;
	
	ogImageTex itex = { 0, NULL, 0 };
	
	std::map<ogImageId, ogImageTex>::iterator it = ogCurrentWrap->imageTexs.find(oi->id);
	
	if (it != ogCurrentWrap->imageTexs.end())
	{
		// texture already allocated for this context
		itex = it->second;
		
		LOG("using image : %lld in context: %p\n", oi->id, ogCurrentWrap);
	}
	else
	{
		// texture creation for this context
		#define TILE_SIZE 64
	
		int tileSize = TILE_SIZE;
		
		int w = oi->w;
		int h = oi->h;
		unsigned char *data = oi->bitmap;
		int hc = (w / tileSize) + (((w % tileSize) == 0) ? 0 : 1);
		int vc = (h / tileSize) + (((h % tileSize) == 0) ? 0 : 1);
		
		int count = hc * vc;
		
		GLuint *tex = (GLuint *) malloc(count * sizeof(GLuint));
		if (!tex) return;
		
		itex.count = count;
		itex.tex = tex;

		glGenTextures(count, tex);
		unsigned char buf[TILE_SIZE*TILE_SIZE*4];
		
		for (int j = 0; j < vc; j++)
		{
			for (int i = 0; i < hc; i++)
			{
				glBindTexture( GL_TEXTURE_2D, tex[j*hc + i]);
				glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP );
				glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP );
				glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
				glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
				glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE );
				
				if (count == 1)
				{
					tileSize = 1;
					while (tileSize < h) tileSize <<= 1;
					while (tileSize < w) tileSize <<= 1;
				}
				
				memset(buf, 0, tileSize*tileSize*4);
				
				for (int y1 = j * tileSize, y2 = 0; y1 < h && y2 < tileSize; y1++, y2++)
					for (int x1 = i * tileSize, x2 = 0; x1 < w && x2 < tileSize; x1++, x2++)
						((int*)buf)[y2 * tileSize + x2] = ((int*)data)[y1 * w + x1];
				
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, tileSize, tileSize, 0,
								GL_RGBA, GL_UNSIGNED_BYTE, buf);
			}
		}

		glBindTexture(GL_TEXTURE_2D, 0);

		GLuint list = glGenLists(1); 
		itex.list = list;

		glNewList(list, GL_COMPILE);
			for (int j = 0; j < vc; j++)
			{
				for (int i = 0; i < hc; i++)
				{
					glBindTexture( GL_TEXTURE_2D, tex[j*hc + i]);
					
					glBegin( GL_QUADS );
						glTexCoord2f( 0, 0 ); glVertex2f( (i+0) * tileSize, (j+0) * tileSize);
						glTexCoord2f( 1, 0 ); glVertex2f( (i+1) * tileSize, (j+0) * tileSize);
						glTexCoord2f( 1, 1 ); glVertex2f( (i+1) * tileSize, (j+1) * tileSize);
						glTexCoord2f( 0, 1 ); glVertex2f( (i+0) * tileSize, (j+1) * tileSize);
					glEnd( );
				}
			}
			glBindTexture(GL_TEXTURE_2D, 0);
		glEndList( );
		
		LOG("created image : %lld in context: %p\n", oi->id, ogCurrentWrap);
		ogCurrentWrap->imageTexs.insert(std::make_pair(oi->id, itex));
	}

	if (itex.list)
	{
		glPushMatrix();
			glTranslatef(x, y, 0);
			if (a != 0)
			{
				int hw = oi->w >> 1, hh = oi->h >> 1;
				glTranslatef(hw, hh, 0);
					glRotatef(a, 0, 0, 1);
				glTranslatef(-hw, -hh, 0);
			}
			glCallList(itex.list);
		glPopMatrix();
	}	
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void ogReleaseImage(ogImage *oi)
{
	if (oi)
	{
		LOG("removed image : %lld\n", oi->id);
	
		for(std::list<ogWrap*>::iterator it = ogValidWraps.begin(); it != ogValidWraps.end(); it++)
			(*it)->deallocatePool.push_back(oi->id);

		if (oi->bitmap) free(oi->bitmap);
		free(oi);
	}
}
