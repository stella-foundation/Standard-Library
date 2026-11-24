cmake_minimum_required(VERSION 3.20)

project(stellalib CXX)
include(GNUInstallDirs)
enable_testing()

set(STELLALIB_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")

set(STELLAC_EXECUTABLE "stellac" CACHE STRING
    "Stella compiler executable used to build stellalib")

set(STELLALIB_ARCH "" CACHE STRING
    "Target architecture (x86_64, aarch64, riscv64)")
if(NOT DEFINED STELLALIB_ARCH OR STELLALIB_ARCH STREQUAL "")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
        set(STELLALIB_ARCH "aarch64")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "riscv64")
        set(STELLALIB_ARCH "riscv64")
    else()
        set(STELLALIB_ARCH "x86_64")
    endif()
endif()

set(STELLALIB_TRIPLE_ARGS "")
set(STELLALIB_AS_TARGET_ARGS "")
if(STELLALIB_ARCH STREQUAL "aarch64")
    set(STELLALIB_TRIPLE_ARGS "--tar.triple=aarch64-linux-gnu")
    set(STELLALIB_AS_TARGET_ARGS "--target=aarch64-linux-gnu")
elseif(STELLALIB_ARCH STREQUAL "riscv64")
    set(STELLALIB_TRIPLE_ARGS "--tar.triple=riscv64-linux-gnu")
    set(STELLALIB_AS_TARGET_ARGS "--target=riscv64-linux-gnu")
elseif(STELLALIB_ARCH STREQUAL "x86_64")
    set(STELLALIB_TRIPLE_ARGS "--tar.triple=x86_64-linux-gnu")
    set(STELLALIB_AS_TARGET_ARGS "--target=x86_64-linux-gnu")
endif()

set(STELLALIB_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/include")
set(STELLALIB_STD_INCLUDE_DIR "${STELLALIB_INCLUDE_DIR}/std")
file(MAKE_DIRECTORY "${STELLALIB_STD_INCLUDE_DIR}")
file(GLOB STELLALIB_TOP_ENTRIES RELATIVE "${STELLALIB_SOURCE_DIR}" "${STELLALIB_SOURCE_DIR}/*")
foreach(entry IN LISTS STELLALIB_TOP_ENTRIES)
    if(NOT entry STREQUAL "arch")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E create_symlink
                "${STELLALIB_SOURCE_DIR}/${entry}"
                "${STELLALIB_STD_INCLUDE_DIR}/${entry}"
        )
    endif()
endforeach()
execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink
        "${STELLALIB_SOURCE_DIR}/arch/${STELLALIB_ARCH}"
        "${STELLALIB_STD_INCLUDE_DIR}/arch"
)

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../Compiler/share/stella")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E create_symlink
            "${STELLALIB_SOURCE_DIR}/arch/${STELLALIB_ARCH}"
            "${CMAKE_CURRENT_SOURCE_DIR}/../Compiler/share/stella/arch"
    )
endif()

file(GLOB_RECURSE STELLALIB_ALL_SL LIST_DIRECTORIES false CONFIGURE_DEPENDS
    "${STELLALIB_SOURCE_DIR}/*.sl")

set(STELLALIB_SL "")
foreach(sl IN LISTS STELLALIB_ALL_SL)
    file(RELATIVE_PATH rel "${STELLALIB_SOURCE_DIR}" "${sl}")
    if(rel MATCHES "^arch/")
        if(rel MATCHES "^arch/${STELLALIB_ARCH}/")
            list(APPEND STELLALIB_SL "${sl}")
        endif()
    else()
        list(APPEND STELLALIB_SL "${sl}")
    endif()
endforeach()

set(STELLA_IMPORT_ROOT_ARGS
    "--src.no-auto-include"
    "--src.include=${STELLALIB_INCLUDE_DIR}")

set(STELLALIB_OBJECT_DIR "${CMAKE_CURRENT_BINARY_DIR}/object")
set(STELLALIB_OBJS "")
set(STELLALIB_OBJS_PIC "")
set(STELLA_SHARED_OBJS "")

set(STELLALIB_HWCAPS_LEVELS "" CACHE STRING
    "List of glibc-hwcaps microarchitecture levels to compile and install")
if(NOT DEFINED STELLALIB_HWCAPS_LEVELS OR STELLALIB_HWCAPS_LEVELS STREQUAL "")
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "") AND STELLALIB_ARCH STREQUAL "x86_64")
        set(STELLALIB_HWCAPS_LEVELS "x86-64-v2" "x86-64-v3" "x86-64-v4")
    endif()
endif()

foreach(sl IN LISTS STELLALIB_SL)
    file(RELATIVE_PATH rel "${STELLALIB_SOURCE_DIR}" "${sl}")
    string(REGEX REPLACE "\\.sl$" ".o" objrel "${rel}")
    string(REGEX REPLACE "\\.sl$" ".d" deprel "${rel}")
    set(obj "${STELLALIB_OBJECT_DIR}/${objrel}")
    set(obj_depfile "${STELLALIB_OBJECT_DIR}/${deprel}")
    list(APPEND STELLALIB_OBJS "${obj}")
    get_filename_component(obj_dir "${obj}" DIRECTORY)
    add_custom_command(
        OUTPUT "${obj}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${obj_dir}"
        COMMAND ${STELLAC_EXECUTABLE} "${sl}" --build.compile-only --opt.function-sections --build.output=${obj}
                ${STELLALIB_TRIPLE_ARGS} --emit.depfile ${STELLA_IMPORT_ROOT_ARGS}
        DEPENDS "${sl}"
        DEPFILE "${obj_depfile}"
        VERBATIM)

    set(pic_obj "${STELLALIB_OBJECT_DIR}/pic/${objrel}")
    set(pic_depfile "${STELLALIB_OBJECT_DIR}/pic/${deprel}")
    list(APPEND STELLALIB_OBJS_PIC "${pic_obj}")
    # a module may be split across several source files. the shared library
    # must contain every object, not just the first object for each namespace
    # declaration.
    list(APPEND STELLA_SHARED_OBJS "${pic_obj}")
    get_filename_component(pic_obj_dir "${pic_obj}" DIRECTORY)
    add_custom_command(
        OUTPUT "${pic_obj}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${pic_obj_dir}"
        COMMAND ${STELLAC_EXECUTABLE} "${sl}" --build.compile-only --opt.function-sections --build.output=${pic_obj}
                ${STELLALIB_TRIPLE_ARGS} --tar.relocation=pic --emit.depfile ${STELLA_IMPORT_ROOT_ARGS}
        DEPENDS "${sl}"
        DEPFILE "${pic_depfile}"
        VERBATIM)

    foreach(hwcap IN LISTS STELLALIB_HWCAPS_LEVELS)
        set(hwcap_obj "${STELLALIB_OBJECT_DIR}/pic-${hwcap}/${objrel}")
        set(hwcap_depfile "${STELLALIB_OBJECT_DIR}/pic-${hwcap}/${deprel}")
        list(APPEND STELLALIB_HWCAPS_${hwcap}_OBJS "${hwcap_obj}")
        get_filename_component(hwcap_obj_dir "${hwcap_obj}" DIRECTORY)
        add_custom_command(
            OUTPUT "${hwcap_obj}"
            COMMAND ${CMAKE_COMMAND} -E make_directory "${hwcap_obj_dir}"
            COMMAND ${STELLAC_EXECUTABLE} "${sl}" --build.compile-only --opt.function-sections --build.output=${hwcap_obj}
                    ${STELLALIB_TRIPLE_ARGS} --tar.cpu=${hwcap} --tar.relocation=pic --emit.depfile ${STELLA_IMPORT_ROOT_ARGS}
            DEPENDS "${sl}"
            DEPFILE "${hwcap_depfile}"
            VERBATIM)
    endforeach()
endforeach()

set(STELLA_LIB "${STELLALIB_OBJECT_DIR}/stellalib.a")
set(STELLA_SHARED "${STELLALIB_OBJECT_DIR}/stellalib.so.0")
set(STELLA_SHARED_LINK "${STELLALIB_OBJECT_DIR}/stellalib.so")

add_custom_command(
    OUTPUT "${STELLA_LIB}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${STELLALIB_OBJECT_DIR}"
    COMMAND ${CMAKE_AR} rcs "${STELLA_LIB}" ${STELLALIB_OBJS}
    DEPENDS ${STELLALIB_OBJS}
    VERBATIM)

find_program(STELLA_LD_EXECUTABLE NAMES ld.lld)
if(STELLA_LD_EXECUTABLE AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    add_custom_command(
        OUTPUT "${STELLA_SHARED}" "${STELLA_SHARED_LINK}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${STELLALIB_OBJECT_DIR}"
        COMMAND ${STELLA_LD_EXECUTABLE} -shared -soname stellalib.so.0
                -o "${STELLA_SHARED}" ${STELLA_SHARED_OBJS}
        COMMAND ${CMAKE_COMMAND} -E create_symlink stellalib.so.0 "${STELLA_SHARED_LINK}"
        DEPENDS ${STELLALIB_OBJS_PIC} ${STELLA_SHARED_OBJS}
        VERBATIM)
else()
    add_custom_command(
        OUTPUT "${STELLA_SHARED}" "${STELLA_SHARED_LINK}"
        COMMAND ${CMAKE_COMMAND} -E touch "${STELLA_SHARED}"
        COMMAND ${CMAKE_COMMAND} -E touch "${STELLA_SHARED_LINK}"
        DEPENDS ${STELLALIB_OBJS_PIC}
        VERBATIM)
endif()

set(STELLALIB_ALL_TARGETS "${STELLA_LIB}" "${STELLA_SHARED}" "${STELLA_SHARED_LINK}")

foreach(hwcap IN LISTS STELLALIB_HWCAPS_LEVELS)
    set(hwcap_dir "${STELLALIB_OBJECT_DIR}/glibc-hwcaps/${hwcap}")
    set(hwcap_shared "${hwcap_dir}/stellalib.so.0")
    set(hwcap_shared_link "${hwcap_dir}/stellalib.so")
    list(APPEND STELLALIB_ALL_TARGETS "${hwcap_shared}" "${hwcap_shared_link}")

    if(STELLA_LD_EXECUTABLE AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
        add_custom_command(
            OUTPUT "${hwcap_shared}" "${hwcap_shared_link}"
            COMMAND ${CMAKE_COMMAND} -E make_directory "${hwcap_dir}"
            COMMAND ${STELLA_LD_EXECUTABLE} -shared -soname stellalib.so.0
                    -o "${hwcap_shared}" ${STELLALIB_HWCAPS_${hwcap}_OBJS}
            COMMAND ${CMAKE_COMMAND} -E create_symlink stellalib.so.0 "${hwcap_shared_link}"
            DEPENDS ${STELLALIB_HWCAPS_${hwcap}_OBJS}
            VERBATIM)
    else()
        add_custom_command(
            OUTPUT "${hwcap_shared}" "${hwcap_shared_link}"
            COMMAND ${CMAKE_COMMAND} -E make_directory "${hwcap_dir}"
            COMMAND ${CMAKE_COMMAND} -E touch "${hwcap_shared}"
            COMMAND ${CMAKE_COMMAND} -E touch "${hwcap_shared_link}"
            DEPENDS ${STELLALIB_HWCAPS_${hwcap}_OBJS}
            VERBATIM)
    endif()
endforeach()

add_custom_target(stella_libs ALL
    DEPENDS ${STELLALIB_OBJS} ${STELLALIB_ALL_TARGETS})

# discover the platform startup source from the architecture tree instead of
# naming an architecture in this build file. the selected source is installed
# as start.o, which is the runtime entry object expected by stellac.
set(STELLALIB_START_SOURCE "${STELLALIB_SOURCE_DIR}/arch/${STELLALIB_ARCH}/start.s")
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND EXISTS "${STELLALIB_START_SOURCE}")
    set(STELLA_START_OBJECT "${STELLALIB_OBJECT_DIR}/start.o")
    add_custom_command(
        OUTPUT "${STELLA_START_OBJECT}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${STELLALIB_OBJECT_DIR}"
        COMMAND ${CMAKE_CXX_COMPILER} -c "${STELLALIB_START_SOURCE}"
                ${STELLALIB_AS_TARGET_ARGS} -o "${STELLA_START_OBJECT}"
        DEPENDS "${STELLALIB_START_SOURCE}"
        VERBATIM)
    add_custom_target(start_o ALL DEPENDS "${STELLA_START_OBJECT}")
else()
    add_custom_target(start_o)
endif()

install(DIRECTORY "${STELLALIB_SOURCE_DIR}/"
        DESTINATION ${CMAKE_INSTALL_DATADIR}/stella/std
        FILES_MATCHING PATTERN "*.sl"
        PATTERN "arch" EXCLUDE)
install(DIRECTORY "${STELLALIB_SOURCE_DIR}/arch/${STELLALIB_ARCH}/"
        DESTINATION ${CMAKE_INSTALL_DATADIR}/stella/std/arch
        FILES_MATCHING PATTERN "*.sl")
install(FILES "${STELLA_LIB}" DESTINATION ${CMAKE_INSTALL_LIBDIR}/stella)
if(STELLA_LD_EXECUTABLE AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    install(FILES "${STELLA_SHARED}" "${STELLA_SHARED_LINK}"
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/stella)
endif()
foreach(hwcap IN LISTS STELLALIB_HWCAPS_LEVELS)
    set(hwcap_shared "${STELLALIB_OBJECT_DIR}/glibc-hwcaps/${hwcap}/stellalib.so.0")
    set(hwcap_shared_link "${STELLALIB_OBJECT_DIR}/glibc-hwcaps/${hwcap}/stellalib.so")
    if(STELLA_LD_EXECUTABLE AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
        install(FILES "${hwcap_shared}" "${hwcap_shared_link}"
                DESTINATION ${CMAKE_INSTALL_LIBDIR}/stella/glibc-hwcaps/${hwcap})
    endif()
endforeach()
if(TARGET start_o AND CMAKE_SYSTEM_NAME STREQUAL "Linux" AND
   STELLA_START_OBJECT)
    install(FILES "${STELLA_START_OBJECT}" DESTINATION ${CMAKE_INSTALL_LIBDIR}/stella)
endif()

add_custom_target(std DEPENDS stella_libs)
