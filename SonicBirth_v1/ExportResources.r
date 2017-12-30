
#ifndef EXPORTRESOURCES_HEADER
#define EXPORTRESOURCES_HEADER

#define kAudioUnitCarbonViewComponentType   'auvw'
#define kAudioUnitType_MusicEffect			'aumf'
#define kAudioUnitType_Effect				'aufx'
#define kAudioUnitType_MusicDevice			'aumu'

#define componentDoAutoVersion             0x01
#define componentHasMultiplePlatforms      0x08

#define UseExtendedThingResource 1

#ifndef cmpThreadSafeOnMac
#define cmpThreadSafeOnMac	0x10000000
#endif

#define Target_PlatformType			platformIA32NativeEntryPoint
#define Target_SecondPlatformType	platformX86_64NativeEntryPoint
#define Target_CodeResType			'dlle'

type 'STR ' {
        pstring;                                                /* String               */
};

type 'dlle' {
 cstring;
};

#ifndef thng_RezTemplateVersion
  #ifdef UseExtendedThingResource         /* grandfather in use of ÒUseExtendedThingResourceÓ */
     #define thng_RezTemplateVersion 1
  #else
      #define thng_RezTemplateVersion 0
  #endif
#endif

type 'thng' {
     literal longint;                                        /* Type */
     literal longint;                                        /* Subtype */
      literal longint;                                        /* Manufacturer */
     unsigned hex longint;                                   /* component flags */
      unsigned hex longint    kAnyComponentFlagsMask = 0;     /* component flags Mask */
     literal longint;                                        /* Code Type */
        integer;                                                /* Code ID */
      literal longint;                                        /* Name Type */
        integer;                                                /* Name ID */
      literal longint;                                        /* Info Type */
        integer;                                                /* Info ID */
      literal longint;                                        /* Icon Type */
        integer;                                                /* Icon ID */
#if thng_RezTemplateVersion >= 1
     unsigned hex longint;                                   /* version of Component */
     longint;                                                /* registration flags */
       integer;                                                /* resource id of Icon Family */
       longint = $$CountOf(ComponentPlatformInfo);
        wide array ComponentPlatformInfo {
         unsigned hex longint;                               /* component flags */
          literal longint;                                    /* Code Type */
            integer;                                            /* Code ID */
          integer platform68k = 1,                            /* platform type (response from gestaltComponentPlatform if available, or else gestaltSysArchitecture) */
                  platformPowerPC = 2,
                   platformInterpreted = 3,
                   platformWin32 = 4,
                 platformPowerPCNativeEntryPoint = 5,
                   platformIA32NativeEntryPoint = 6,
                  platformPowerPC64NativeEntryPoint = 7,
                 platformX86_64NativeEntryPoint = 8;
      };
#if thng_RezTemplateVersion >= 2
        literal longint;                                        /* resource map type */
        integer;                                                /* resource map id */
#endif
#endif
};

#endif /* EXPORTRESOURCES_HEADER */

resource 'STR ' (RES_ID, purgeable) {
	NAME
};

resource 'STR ' (RES_ID + 1, purgeable) {
	DESCRIPTION
};

resource 'dlle' (RES_ID) {
	ENTRY_POINT
};

resource 'thng' (RES_ID, NAME) {
	COMP_TYPE,
	COMP_SUBTYPE,
	COMP_MANUF,
	0,		0,		// Flags, Mask
	0,		0,		// Code
	'STR ',	RES_ID,
	'STR ',	RES_ID + 1,
	0,	0,			/* icon */
	VERSION,
	componentHasMultiplePlatforms | componentDoAutoVersion,
	0,
	{
		//cmpThreadSafeOnMac,
		//Target_CodeResType, RES_ID,
		//Target_PlatformType,

		//cmpThreadSafeOnMac,
		//Target_CodeResType, RES_ID,
		//Target_SecondPlatformType
		
		// i386
		cmpThreadSafeOnMac,
		'dlle', RES_ID, platformIA32NativeEntryPoint,
		
		// x86_64
		cmpThreadSafeOnMac,
		'dlle', RES_ID, platformX86_64NativeEntryPoint
	}
};

#undef RES_ID
#undef COMP_TYPE
#undef COMP_SUBTYPE
#undef COMP_MANUF
#undef VERSION
#undef NAME
#undef DESCRIPTION
#undef ENTRY_POINT
