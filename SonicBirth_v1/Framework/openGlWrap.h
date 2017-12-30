/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifndef __OPENGLWRAP_H__
#define __OPENGLWRAP_H__

#ifdef __cplusplus
extern "C" {
#endif

typedef enum 
{
	ogBlack = 0,
	ogWhite,
	ogRed,
	ogGreen,
	ogBlue,
	ogGray,
	ogLightGray,
	ogColorCount
} ogColorIndex;

typedef struct ogWrap ogWrap;
typedef struct ogImage ogImage;

typedef struct
{
	float r, g, b, a;
} ogColor;

// initialization
ogWrap * ogInit();
void ogBeginDrawing(ogWrap * w);
void ogRelease(ogWrap * w);
void ogSetShape(float x, float y, float w, float h);
void ogEndDrawing(int flush);

// contexts
void ogPushContext();
void ogPopContext();

// matrix
void ogPushMatrix();
void ogTranslate(float x, float y);
void ogPopMatrix();

// attributes
void ogSetLineWidth(float lw);
void ogSetColor(ogColor c);
void ogSetColorComp(float r, float g, float b, float a);
void ogSetColorIndex(ogColorIndex i);
void ogSetClearColor(float r, float g, float b, float a);

void ogEnableClipRegion(float x, float y, float w, float h);
void ogDisableClipRegion();

// drawing
void ogClearBuffer();

void ogDrawPoint(float x, float y);
void ogStrokeLine(float x_1, float y_1, float x_2, float y_2);

void ogStrokeTriangle(float x_1, float y_1, float x_2, float y_2, float x_3, float y_3);
void ogFillTriangle(float x_1, float y_1, float x_2, float y_2, float x_3, float y_3);

void ogStrokeRectangle(float x, float y, float w, float h);
void ogFillRectangle(float x, float y, float w, float h);

void ogStrokeRoundedRectangle(float x, float y, float w, float h, float r);
void ogFillRoundedRectangle(float x, float y, float w, float h, float r);

void ogStrokeCircle(float x, float y, float r);
void ogFillCircle(float x, float y, float r);

/*			270
		180		0
			90			*/
void ogStrokeArc(float x, float y, float r, float a1, float a2);
void ogFillArc(float x, float y, float r, float a1, float a2);

float ogStringWidth(const char *s);
void ogDrawStringAtPoint(const char *s, float x, float y);
void ogDrawStringInRect(const char *s, float x, float y, float w, float h);
void ogDrawValueInRect(double v, float x, float y, float w, float h);

ogImage * ogInitImage(int w, int h, unsigned char *data);
int ogImageWidth(ogImage *oi);
int ogImageHeight(ogImage *oi);
void ogDrawImage(ogImage *oi, float x, float y);
void ogDrawRotatedImage(ogImage *oi, float x, float y, float a);
void ogReleaseImage(ogImage *oi);

#ifdef __cplusplus
}
#endif


#endif /* __OPENGLWRAP_H__ */




