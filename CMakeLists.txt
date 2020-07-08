# CMAKE minimum version
cmake_minimum_required(VERSION 3.13.4)

option(xmlmofo_USE_OpenCoarrays
"Build XMLmofo with support for linking against OpenCoarray programs" OFF)

# Project name
project(xmlmofo LANGUAGES Fortran)

# xmlmofo project version
set (xmlmofo_VERSION_MAJOR 0)
set (xmlmofo_VERSION_MINOR 001)

# Print project logo, version and tag line
file(READ ${CMAKE_CURRENT_LIST_DIR}/cmake/XMLmofo-logo.txt xmlmofo_LOGO)
string(JOIN "\n         " xmlmofo_GREETING "${xmlmofo_LOGO}"
  "XMLmofo, v${xmlmofo_VERSION_MAJOR}.${xmlmofo_VERSION_MINOR}: XML in MOdern FOrtran")
if(NOT isMultiConfig)
  string(APPEND xmlmofo_GREETING "\n         Build type: ${CMAKE_BUILD_TYPE}")
endif()
string(APPEND xmlmofo_GREETING "\n")
string(PREPEND xmlmofo_GREETING "\n")
message(STATUS "${xmlmofo_GREETING}")

# Turn on the ability to create folders to organize projects (.vcproj)
# It creates "CMakePredefinedTargets" folder by default and adds CMake
# defined projects like INSTALL.vcproj and ZERO_CHECK.vcproj
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# System options
if ( "${CMAKE_SYSTEM_NAME}" MATCHES "Windows")
  set(prefix "/")
  set(infix ":")
  set(Qf "Q")
  set(Q "Q")
  set(eq ":")
  set(colon ":")
  set(colon_ ":")
  set(libs_static "/libs:static")
  set(dgblibs "/dbglibs")
else()
  set(prefix "-")
  set( infix " ")
  set( Qf "f")
  set( Q "")
  set( eq "=")
  set( colon "")
  set( colon_ " ")
  set( libs_static "")
  set( dgblibs "")
endif()

# Compiler options
if ("${CMAKE_Fortran_COMPILER_ID}" MATCHES "Intel")
  set(intel_compiler true)
  if ( "${CMAKE_SYSTEM_NAME}" MATCHES "Windows")
    # Full debug, Fortran 2008 standard, free format (due to automatic build to .f file for testing), Check bounds
    set(CMAKE_Fortran_FLAGS
      "${prefix}nologo ${prefix}debug${infix}full ${prefix}MP ${prefix}Od ${prefix}standard-semantics ${prefix}warn${infix}errors ${prefix}stand${infix}f15 ${prefix}debug-parameters${infix}all ${prefix}warn${infix}declarations ${prefix}warn${infix}unused ${prefix}warn${infix}interfaces ${prefix}${Qf}trapuv ${prefix}${Q}init${eq}snan ${prefix}${Q}init${eq}arrays ${prefix}fpe${colon}0 ${prefix}traceback ${prefix}check${colon_}bounds ${prefix}check${colon_}stack ${libs_static} ${prefix}threads ${dbglibs} ${prefix}free"
       )
  else()
    # Full debug, Fortran 2008 standard, free format (due to automatic build to .f file for testing), Check bounds
    set(CMAKE_Fortran_FLAGS
      "${prefix}nologo ${prefix}debug${infix}full ${prefix}multiple-processes ${prefix}O0 ${prefix}standard-semantics ${prefix}warn${infix}errors ${prefix}stand${infix}f15 ${prefix}debug-parameters${infix}all ${prefix}warn${infix}declarations ${prefix}warn${infix}unused ${prefix}warn${infix}interfaces ${prefix}${Qf}trapuv ${prefix}${Q}init${eq}snan ${prefix}${Q}init${eq}arrays ${prefix}fpe${colon}0 ${prefix}traceback ${prefix}check${colon_}bounds ${prefix}check${colon_}stack ${libs_static} ${prefix}threads ${dbglibs} ${prefix}free"
	   )
  endif()
elseif("${CMAKE_Fortran_COMPILER_ID}" MATCHES "GNU")
  set(gnu_compiler true)
  # Fortran 2008 standard, free format (due to automatic build to .f file for testing)
  set(CMAKE_Fortran_FLAGS "${prefix}std=f2008 ${prefix}fcheck=all ${prefix}Wall ${prefix}Wno-unused-dummy-argument ${prefix}ffree-form")
else()
  message(WARNING
    "\n"
    "Attempting to build with untested Fortran compiler: ${CMAKE_Fortran_COMPILER_ID}. "
    "Please report any failures through the xmlmofo Git issues\n\n"
  )
endif()

if(xmlmofo_USE_OpenCoarrays)
  find_package(OpenCoarrays)
endif()

##################################################
# Begin xmlmofo specific targets and configuration
##################################################

# Where to put xmlmofo module files
set(xmlmofo_mod_dir ${CMAKE_CURRENT_BINARY_DIR}/mod)

# Avoid compilation cascades:
#    put interfaces and submodules in separate libraries
# Specify xmlmofo interfaces
set(xmlmofo_interfaces
  utilities/file_utility.f90
  utilities/Misc.f90
  utilities/Precision.f90
  xml.f90
  )

# Specify xmlmofo implementations
set(xmlmofo_procedures
  utilities/file_utility_procedures.f90
  utilities/Misc_procedures.f90
  xml_procedures.f90
  )

# Compile all the interfaces first
foreach(item ${xmlmofo_interfaces})
  list(APPEND xmlmofo_interface_srcs "${CMAKE_CURRENT_SOURCE_DIR}/src/${item}")
endforeach()
add_library(xmlmofo_interfaces OBJECT ${xmlmofo_interface_srcs})
# Tell CMake where to put xmlmofo .mod files generated with libxmlmofo
set_property(TARGET xmlmofo_interfaces
  PROPERTY
  Fortran_MODULE_DIRECTORY ${xmlmofo_mod_dir})
if(xmlmofo_USE_OpenCoarrays)
  target_link_libraries(xmlmofo_interfaces
    PRIVATE OpenCoarrays::caf_mpi_static)
endif()

# Add any object files from the interfaces to the main library build
foreach(item ${xmlmofo_procedures})
  list(APPEND xmlmofo_procedures_srcs "${CMAKE_CURRENT_SOURCE_DIR}/src/${item}")
endforeach()
add_library(xmlmofo
  STATIC ${xmlmofo_procedures_srcs} $<TARGET_OBJECTS:xmlmofo_interfaces>)
if(xmlmofo_USE_OpenCoarrays)
  target_link_libraries(xmlmofo
    PRIVATE OpenCoarrays::caf_mpi_static)
endif()

# Tell CMake where to put xmlmofo .mod files generated with libxmlmofo
set_property(TARGET xmlmofo
  PROPERTY
  Fortran_MODULE_DIRECTORY ${xmlmofo_mod_dir})

# Tell consumers where to find .mod files
target_include_directories(xmlmofo PUBLIC
  $<BUILD_INTERFACE:${xmlmofo_mod_dir}>
  $<INSTALL_INTERFACE:include/xmlmofo>
  )

# Organize things in Visual Studio
source_group("xmlmofoLib" FILES ${xmlmofo_sources})
set_property(TARGET xmlmofo
  PROPERTY
  FOLDER "xmlmofo")
install(TARGETS xmlmofo DESTINATION lib EXPORT xmlmofo-targets)
# Breaking this code out into a function would be nice
set(MOD_DIR_TO_INSTALL "${xmlmofo_mod_dir}")
set(MOD_DESTINATION_DIR include/xmlmofo)
install(
  CODE "file(GLOB_RECURSE MODULE_FILES \"${MOD_DIR_TO_INSTALL}/*.mod\")"
  CODE "file(GLOB_RECURSE SUBMOD_FILES \"${MOD_DIR_TO_INSTALL}/*.smod\")"
  CODE "file(INSTALL \${MODULE_FILES} DESTINATION \"\${CMAKE_INSTALL_PREFIX}/${MOD_DESTINATION_DIR}\")"
  CODE "file(INSTALL \${SUBMOD_FILES} DESTINATION \"\${CMAKE_INSTALL_PREFIX}/${MOD_DESTINATION_DIR}\")"
  )
install(EXPORT xmlmofo-targets DESTINATION lib/xmlmofo)

######################
# Add test directories
######################

enable_testing()

# Specify all the subdirectories containing test executable/library sources:
set(subdirectories_list tests/unit)# tests/integration)
foreach(subdirectory ${subdirectories_list})
  add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/${subdirectory}")
endforeach()

# Unit Tests exported from tests/unit subdirectory in ${xmlmofo_unit_test_list}
# Integration Tests exported from tests/integration in ${xmlmofo_integration_test_list}

# Add unit tests and define the string that is used to signal success
foreach(unit_test ${xmlmofo_unit_test_list})
  add_test(NAME "xmlmofo_${unit_test}_test" COMMAND ${CMAKE_CURRENT_BINARY_DIR}/tests/unit/${unit_test} WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tests/unit)
  set_property(TEST "xmlmofo_${unit_test}_test" PROPERTY PASS_REGULAR_EXPRESSION "Test passed")
  set_property(TEST "xmlmofo_${unit_test}_test" PROPERTY LABELS "xmlmofo" "unit-test")
endforeach()

# Add integration tests and define the string that is used to signal success
#foreach(integration_test ${xmlmofo_integration_test_list})
#  add_test(NAME "xmlmofo_${integration_test}_test" COMMAND ${CMAKE_CURRENT_BINARY_DIR}/tests/integration/${integration_test} WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tests/integration)
#  set_property(TEST "xmlmofo_${integration_test}_test" PROPERTY PASS_REGULAR_EXPRESSION "Finished")
#  set_property(TEST "xmlmofo_${integration_test}_test" PROPERTY LABELS "xmlmofo" "integration-test")
#endforeach()

add_custom_target(RUN_ALL_xmlmofo_TESTS
  COMMAND ${CMAKE_CTEST_COMMAND} -C $<CONFIG> --output-on-failure -L "xmlmofo")
set_property(TARGET RUN_ALL_xmlmofo_TESTS PROPERTY FOLDER "All-Tests")
