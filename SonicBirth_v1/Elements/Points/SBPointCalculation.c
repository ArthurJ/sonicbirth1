/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#include "SBPointCalculation.h"

void pointSort(SBPointsBuffer *pts)
{
	int changed, c = pts->count, i;
	do
	{
		changed = 0;
		for (i = 1; i < c; i++)
		{
			if (pts->x[i] < pts->x[i-1])
			{
				changed = 1;
				
				double temp;
				
				temp = pts->x[i];
				pts->x[i] = pts->x[i-1];
				pts->x[i-1] = temp;
				
				temp = pts->y[i];
				pts->y[i] = pts->y[i-1];
				pts->y[i-1] = temp;
				
				char temp2;
				temp2 = pts->move[i];
				pts->move[i] = pts->move[i-1];
				pts->move[i-1] = temp2;
			}
		} 
	} while(changed);
}


void pointSpline(SBPointsBuffer *pts)
{
	int rpc = pts->count;
	if (rpc == 0) return;
	
	double u[rpc];
	double Y2[rpc];
	
	Y2[0] = 0.;
	Y2[rpc-1] = 0.;
	u[0] = 0.;
	
	double sig, p;
	int i;
	
	for (i = 1; i <= rpc - 2; i++)
	{
		double ax = pts->x[i - 1],		ay = pts->y[i - 1];
		double bx = pts->x[  i  ],		by = pts->y[  i  ];
		double cx = pts->x[i + 1],		cy = pts->y[i + 1];
		
		sig = (bx - ax) / (cx - ax);
		p = sig * Y2[i-1] + 2.0;
		Y2[i] = (sig - 1.0)/p;
		u[i] = (cy - by) / (cx - bx) - (by - ay) / (bx - ax);
		u[i] = (6.0 * u[i] / (cx - ax) - sig * u[i-1] ) / p;
	}

	for (i = rpc - 2; i >= 0; i--)
		Y2[i] = Y2[i] * Y2[i+1] + u[i];

	for (i = 0; i < rpc; i++)
		pts->y2[i] = Y2[i];
		
	for (i = 0; i < rpc - 1; i++)
	{
		double h = pts->x[i + 1] - pts->x[i];
		pts->hi[i] = 1. / h;
		pts->h2[i] = h*h / 6.;
	}
}

