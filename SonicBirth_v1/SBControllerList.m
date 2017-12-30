/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBControllerList.h"

SBControllerType gControllerTypes[] =
{
	{@"Off",								kOffID},
	{@"Learn",								kLearnID},

	{@"1. Modulation Wheel",				1},
	{@"2. Breath Controller",				2},
	{@"3. Undefined",						3},
	{@"4. Foot controller",					4},
	{@"5. Portamento time",					5},
	{@"6. Data Entry",						6},
	{@"7. Channel volume",					7},
	{@"8. Balance",							8},
	{@"9. Undefined",						9},
	
	{@"10. Pan",							10},
	{@"11. Expression Controller",			11},
	{@"12. Effect control 1",				12},
	{@"13. Effect control 2",				13},
	{@"14. Undefined",						14},
	{@"15. Undefined",						15},
	{@"16. General Purpose 1",				16},
	{@"17. General Purpose 2",				17},
	{@"18. General Purpose 3",				18},
	{@"19. General Purpose 4",				19},
	
	{@"20. Undefined",						20},
	{@"21. Undefined",						21},
	{@"22. Undefined",						22},
	{@"23. Undefined",						23},
	{@"24. Undefined",						24},
	{@"25. Undefined",						25},
	{@"26. Undefined",						26},
	{@"27. Undefined",						27},
	{@"28. Undefined",						28},
	{@"29. Undefined",						29},
	
	{@"30. Undefined",						30},
	{@"31. Undefined",						31},
	
	// -- lsb -- 0 - 31 -> 31 - 63

	{@"64. Pedal sustain (on/off)",			64},
	{@"65. Portamento (on/off)",			65},
	{@"66. Sustenuto (on/off)",				66},
	{@"67. Soft Pedal (on/off)",			67},
	{@"68. Legato footswitch (on/off)",		68},
	{@"69. Hold 2 (on/off)",				69},
	
	{@"70. Sound controller 1",				70},
	{@"71. Sound controller 2",				71},
	{@"72. Sound controller 3",				72},
	{@"73. Sound controller 4",				73},
	{@"74. Sound controller 5",				74},
	{@"75. Sound controller 6",				75},
	{@"76. Sound controller 7",				76},
	{@"77. Sound controller 8",				77},
	{@"78. Sound controller 9",				78},
	{@"79. Sound controller 10",			79},
	
	{@"80. General Purpose 5",				80},
	{@"81. General Purpose 6",				81},
	{@"82. General Purpose 7",				82},
	{@"83. General Purpose 8",				83},
	{@"84. Portamento control",				84},
	
	{@"85. Undefined",						85},
	{@"86. Undefined",						86},
	{@"87. Undefined",						87},
	{@"88. Undefined",						88},
	{@"89. Undefined",						89},
	{@"90. Undefined",						90},
	
	{@"91. Effect 1 Depth",					91},
	{@"92. Effect 2 Depth",					92},
	{@"93. Effect 3 Depth",					93},
	{@"94. Effect 4 Depth",					94},
	{@"95. Effect 5 Depth",					95},
	
	{@"96. Data Entry + 1",					96},
	{@"97. Data Entry + 1",					97},
	{@"99. Non-Registered Param.",			99}, // 98 is LSB
	{@"101. Register Param.",				101}, // 100 is LSB
	
	{@"102. Undefined",						102},
	{@"103. Undefined",						103},
	{@"104. Undefined",						104},
	{@"105. Undefined",						105},
	{@"106. Undefined",						106},
	{@"107. Undefined",						107},
	{@"108. Undefined",						108},
	{@"109. Undefined",						109},
	
	{@"110. Undefined",						110},
	{@"111. Undefined",						111},
	{@"112. Undefined",						112},
	{@"113. Undefined",						113},
	{@"114. Undefined",						114},
	{@"115. Undefined",						115},
	{@"116. Undefined",						116},
	{@"117. Undefined",						117},
	{@"118. Undefined",						118},
	{@"119. Undefined",						119},
	
	{@"122. Local controller (on/off)",		122},

};

int gControllerTypesCount = sizeof(gControllerTypes) / sizeof(SBControllerType);




