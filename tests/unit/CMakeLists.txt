# Unit tests
# Add object library to work around CMake parallel build race conditions
# (Sources defining modules should *NOT* be listed in multiple targets!
# Use an object lib and link against that instead.)
add_library(xmlmofoPassFail OBJECT XMLmofoAnalyze.f90)
target_include_directories(xmlmofoPassFail PUBLIC "${xmlmofo_mod_dir}")
set_property(TARGET xmlmofoPassFail
  PROPERTY
  FOLDER "xmlmofo-Unit-Tests")

function(add_xmlmofo_unit_test test_name)
  # Assumes source file is ${test_name}.f90
  add_executable(${test_name} ${test_name}.f90 $<TARGET_OBJECTS:xmlmofoPassFail>)
  if(xmlmofo_USE_OpenCoarrays)
    target_link_libraries(${test_name}
      PUBLIC OpenCoarrays::caf_mpi_static)
  endif()
  target_link_libraries(${test_name}
    PUBLIC xmlmofo)
  set_property(TARGET ${test_name}
    PROPERTY
    FOLDER "xmlmofo-Unit-Tests")
  source_group("xmlmofo\\UnitTests" FILES ${test_name}.f90 XMLmofoAnalyze.f90)
endfunction(add_xmlmofo_unit_test)

foreach(test
    xml_unit
    )
  add_xmlmofo_unit_test(${test})
  list(APPEND xmlmofo_unit_test_list ${test})
endforeach()

# Set the xmlmofo_unit_test_list in parent scope
set(xmlmofo_unit_test_list ${xmlmofo_unit_test_list} PARENT_SCOPE)
