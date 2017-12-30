/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

static inline double pointCalculate(SBPointsBuffer *pts, double value, int *save) __attribute__ ((always_inline));
static inline double pointCalculate(SBPointsBuffer *pts, double value, int *save)
{
	int left = *save;
	int c = pts->count, cm1 = c - 1, i;
	
	if (c == 0) return 0;
	
	if (value < pts->x[0]) return pts->y[0];
	if (value >= pts->x[cm1]) return pts->y[cm1];
	if (value >= pts->x[left] && value < pts->x[left+1]) goto found;

	for (i = 0; i < cm1; i++)
	{
		if (value >= pts->x[i] && value < pts->x[i+1])
		{
			left = i;
			*save = left;
			goto found;
		}
	}

	// shouldn't get here
	// nan or inf ?
	return pts->y[cm1];
	
found:
	if (pts->type == 0)
	
		// step
		return pts->y[left];
		
	else if (pts->type == 1)
		
		// linear
		return pts->y[left] + (value - pts->x[left])/(pts->x[left+1] - pts->x[left]) * (pts->y[left+1] - pts->y[left]);
		
	else
	
		// spline
	{
		double rax = pts->x[  left  ],	ray = pts->y[  left  ];
		double rbx = pts->x[left + 1],	rby = pts->y[left + 1];
		double hinv = pts->hi[left];
		double a = (rbx - value) * hinv;
		double b = (value - rax) * hinv;
		double r = a * ray + b * rby + ((a*a*a - a) * pts->y2[left] + (b*b*b - b) * pts->y2[left+1]) * pts->h2[left];
		if (r < 0.) return 0.;
		if (r > 1.) return 1.;
		return r;
	}
}


void pointSort(SBPointsBuffer *pts);
void pointSpline(SBPointsBuffer *pts);

