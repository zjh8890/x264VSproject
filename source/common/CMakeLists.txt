# vim: syntax=cmake

list(APPEND VFLAGS "-DX264_VERSION=${X264_VERSION}")
if(EXTRA_LIB)
    if(LINKED_8BIT)
        list(APPEND VFLAGS "-DLINKED_8BIT=1")
    endif(LINKED_8BIT)
    if(LINKED_10BIT)
        list(APPEND VFLAGS "-DLINKED_10BIT=1")
    endif(LINKED_10BIT)
    if(LINKED_12BIT)
        list(APPEND VFLAGS "-DLINKED_12BIT=1")
    endif(LINKED_12BIT)
endif(EXTRA_LIB)

if(ENABLE_ASSEMBLY)
    set_source_files_properties(bitstream.c dct.c deblock.c mc.c pixel.c predict.c quant.c  PROPERTIES COMPILE_FLAGS -DHAVE_MMX=1)
    list(APPEND VFLAGS "-DHAVE_MMX=1")
endif(ENABLE_ASSEMBLY)

if(ENABLE_ASSEMBLY AND X86)
    if(MSVC)
        set(PRIMITIVES ${SSE3} ${SSSE3} ${SSE41})
        set(WARNDISABLE "/wd4100") # unreferenced formal parameter
        if(INTEL_CXX)
            add_definitions(/Qwd111) # statement is unreachable
            add_definitions(/Qwd128) # loop is unreachable
            add_definitions(/Qwd177) # declared function is unused
            add_definitions(/Qwd185) # dynamic initialization in unreachable code
            add_definitions(/Qwd280) # conditional expression is constant
        endif()
        if(X64)
            set_source_files_properties(${SSE3} ${SSSE3} ${SSE41} PROPERTIES COMPILE_FLAGS "${WARNDISABLE}")
        else()
            # x64 implies SSE4, so only add /arch:SSE2 if building for Win32
            set_source_files_properties(${SSE3} ${SSSE3} ${SSE41} PROPERTIES COMPILE_FLAGS "${WARNDISABLE} /arch:SSE2")
        endif()
    endif()
    if(GCC)
        if(CLANG)
            # llvm intrinsic headers cause shadow warnings
            set(WARNDISABLE "-Wno-shadow -Wno-unused-parameter")
        else()
            set(WARNDISABLE "-Wno-unused-parameter")
        endif()
        if(INTEL_CXX OR CLANG OR (NOT CC_VERSION VERSION_LESS 4.3))
            set(PRIMITIVES ${SSE3} ${SSSE3} ${SSE41})
            set_source_files_properties(${SSE3}  PROPERTIES COMPILE_FLAGS "${WARNDISABLE} -msse3")
            set_source_files_properties(${SSSE3} PROPERTIES COMPILE_FLAGS "${WARNDISABLE} -mssse3")
            set_source_files_properties(${SSE41} PROPERTIES COMPILE_FLAGS "${WARNDISABLE} -msse4.1")
        endif()
    endif()

    set(C_SRCS dct.h mc.h mc-c.c pixel.h predict.h predict-c.c quant.h util.h)
    set(A_SRCS const-a.asm cabac-a.asm dct-a.asm deblock-a.asm mc-a.asm
               mc-a2.asm pixel-a.asm predict-a.asm quant-a.asm
               cpu-a.asm dct-32.asm bitstream-a.asm)
    if(HIGH_BIT_DEPTH)
        set(A_SRCS ${A_SRCS} sad16-a.asm)
    else()
        set(A_SRCS ${A_SRCS} sad-a.asm)
    endif()

    if(NOT X64)
        set(A_SRCS ${A_SRCS} pixel-32.asm)
	else()
        set(A_SRCS ${A_SRCS} trellis-64.asm)	    
    endif()

    if(MSVC_IDE OR XCODE)
        # MSVC requires custom build rules in the main cmake script for yasm
        set(MSVC_ASMS "${A_SRCS}" CACHE INTERNAL "yasm sources")
        set(A_SRCS)
    endif()

    enable_language(ASM_YASM)

    foreach(SRC ${A_SRCS} ${C_SRCS})
        set(ASM_PRIMITIVES ${ASM_PRIMITIVES} x86/${SRC})
    endforeach()
    source_group(Assembly FILES ${ASM_PRIMITIVES})
endif(ENABLE_ASSEMBLY AND X86)

# set_target_properties can't do list expansion
string(REPLACE ";" " " VERSION_FLAGS "${VFLAGS}")
set_source_files_properties(version.cpp PROPERTIES COMPILE_FLAGS ${VERSION_FLAGS})

check_symbol_exists(strtok_r "string.h" HAVE_STRTOK_R)
if(HAVE_STRTOK_R)
    set_source_files_properties(common.c PROPERTIES COMPILE_FLAGS -DHAVE_STRTOK_R=1)
endif()

if(GCC AND CC_HAS_NO_NARROWING)
    set_source_files_properties(cpu.c PROPERTIES COMPILE_FLAGS -Wno-narrowing)
endif()

add_library(common OBJECT
    ${ASM_PRIMITIVES} ../config.h
    bitstream.c bitstream.h
    cabac.c cabac.h
    common.c common.h
    cpu.c cpu.h
    cpu.c cpu.h
    dct.c dct.h
    deblock.c frame.c frame.h
    macroblock.c macroblock.h
	mc.c mc.h mvpred.c
	osdep.c osdep.h
    pixel.c pixel.h
    predict.c predict.h
    quant.c quant.h
    rectangle.c rectangle.h
    set.c set.h 
    threadpool.c threadpool.h
    vlc.c win32thread.c win32thread.h
)
